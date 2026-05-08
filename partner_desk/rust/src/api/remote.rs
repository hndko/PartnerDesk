use flutter_rust_bridge::frb;
use image::codecs::jpeg::JpegEncoder;
use std::io::Cursor;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use tokio::net::{TcpStream, UdpSocket};
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use xcap::Monitor;
use serde::{Deserialize, Serialize};
use enigo::{Enigo, Mouse, Keyboard, Coordinate, Button, Direction, Settings, Key};

#[frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

static IS_SERVER_RUNNING: AtomicBool = AtomicBool::new(false);

/// Max frame size: 10MB - prevents OOM from corrupt data
const MAX_FRAME_SIZE: usize = 10 * 1024 * 1024;

#[derive(Serialize, Deserialize, Debug)]
pub enum InputCommand {
    MouseMove { x: f64, y: f64, monitor_width: f64, monitor_height: f64 },
    MouseLeftClick,
    MouseRightClick,
    KeyboardType { text: String },
    KeyboardSpecial { key_name: String },
}

/// Start the host server that will capture screen and listen for connections.
/// Now loops to accept multiple connections (reconnects).
pub async fn start_host(port: u16) -> anyhow::Result<()> {
    // Use SO_REUSEADDR to allow quick restart
    let tcp_socket = tokio::net::TcpSocket::new_v4()?;
    tcp_socket.set_reuseaddr(true)?;
    tcp_socket.bind(format!("0.0.0.0:{}", port).parse()?)?;
    let listener = tcp_socket.listen(1024)?;

    let udp_raw = socket2::Socket::new(socket2::Domain::IPV4, socket2::Type::DGRAM, Some(socket2::Protocol::UDP))?;
    udp_raw.set_reuse_address(true)?;
    udp_raw.set_nonblocking(true)?;
    udp_raw.bind(&format!("0.0.0.0:{}", port + 1).parse::<std::net::SocketAddr>()?.into())?;
    let input_socket = Arc::new(UdpSocket::from_std(std::net::UdpSocket::from(udp_raw))?);

    IS_SERVER_RUNNING.store(true, Ordering::Relaxed);

    // Spawn input receiver task
    let input_socket_clone = input_socket.clone();
    tokio::spawn(async move {
        let mut enigo = Enigo::new(&Settings::default()).unwrap();
        let mut buf = [0; 4096];
        while IS_SERVER_RUNNING.load(Ordering::Relaxed) {
            if let Ok((len, _)) = input_socket_clone.recv_from(&mut buf).await {
                if let Ok(cmd) = bincode::deserialize::<InputCommand>(&buf[..len]) {
                    match cmd {
                        InputCommand::MouseMove { x, y, monitor_width: _, monitor_height: _ } => {
                            let _ = enigo.move_mouse(x as i32, y as i32, Coordinate::Abs);
                        }
                        InputCommand::MouseLeftClick => {
                            let _ = enigo.button(Button::Left, Direction::Click);
                        }
                        InputCommand::MouseRightClick => {
                            let _ = enigo.button(Button::Right, Direction::Click);
                        }
                        InputCommand::KeyboardType { text } => {
                            let _ = enigo.text(&text);
                        }
                        InputCommand::KeyboardSpecial { key_name } => {
                            let key = match key_name.as_str() {
                                "enter" => Key::Return,
                                "backspace" => Key::Backspace,
                                "tab" => Key::Tab,
                                "escape" => Key::Escape,
                                "delete" => Key::Delete,
                                "up" => Key::UpArrow,
                                "down" => Key::DownArrow,
                                "left" => Key::LeftArrow,
                                "right" => Key::RightArrow,
                                "home" => Key::Home,
                                "end" => Key::End,
                                "space" => Key::Space,
                                _ => Key::Return,
                            };
                            let _ = enigo.key(key, Direction::Click);
                        }
                    }
                }
            }
        }
    });

    // Loop to accept multiple connections (allows reconnect)
    while IS_SERVER_RUNNING.load(Ordering::Relaxed) {
        match listener.accept().await {
            Ok((mut socket, addr)) => {
                println!("Client connected from {}", addr);
                
                let (tx, mut rx) = tokio::sync::mpsc::channel::<Vec<u8>>(10);
                
                std::thread::spawn(move || {
                    if let Ok(monitors) = Monitor::all() {
                        if let Some(primary_monitor) = monitors.into_iter().next() {
                            loop {
                                if !IS_SERVER_RUNNING.load(Ordering::Relaxed) {
                                    break;
                                }

                                if let Ok(image) = primary_monitor.capture_image() {
                                    let mut buffer = Cursor::new(Vec::new());
                                    let mut encoder = JpegEncoder::new_with_quality(&mut buffer, 60);
                                    if encoder.encode_image(&image).is_ok() {
                                        let jpeg_bytes = buffer.into_inner();
                                        if tx.blocking_send(jpeg_bytes).is_err() {
                                            break; // Receiver dropped (client disconnected)
                                        }
                                    }
                                }

                                std::thread::sleep(std::time::Duration::from_millis(100));
                            }
                        }
                    }
                });

                // Forward frames to TCP
                while let Some(jpeg_bytes) = rx.recv().await {
                    if !IS_SERVER_RUNNING.load(Ordering::Relaxed) {
                        break;
                    }
                    let size = jpeg_bytes.len() as u32;

                    if socket.write_all(&size.to_be_bytes()).await.is_err() {
                        break;
                    }
                    if socket.write_all(&jpeg_bytes).await.is_err() {
                        break;
                    }
                }
                println!("Client {} disconnected, waiting for new connection...", addr);
            }
            Err(e) => {
                eprintln!("Accept error: {}", e);
                break;
            }
        }
    }

    Ok(())
}

pub fn stop_host() {
    IS_SERVER_RUNNING.store(false, Ordering::Relaxed);
}

static IS_VIEWER_RUNNING: AtomicBool = AtomicBool::new(false);

/// Connect to a host and receive video frames, sending them to Flutter via StreamSink
pub async fn start_viewer(ip: String, port: u16, sink: crate::frb_generated::StreamSink<Vec<u8>>) -> anyhow::Result<()> {
    let mut stream = TcpStream::connect(format!("{}:{}", ip, port)).await?;
    IS_VIEWER_RUNNING.store(true, Ordering::Relaxed);

    loop {
        if !IS_VIEWER_RUNNING.load(Ordering::Relaxed) {
            break;
        }

        let mut size_buf = [0u8; 4];
        if stream.read_exact(&mut size_buf).await.is_err() {
            break;
        }
        let size = u32::from_be_bytes(size_buf) as usize;

        // Validate frame size to prevent OOM
        if size > MAX_FRAME_SIZE {
            eprintln!("Frame size {} exceeds max {}, skipping", size, MAX_FRAME_SIZE);
            break;
        }

        let mut img_buf = vec![0u8; size];
        if stream.read_exact(&mut img_buf).await.is_err() {
            break;
        }

        let _ = sink.add(img_buf);
    }
    
    Ok(())
}

pub fn stop_viewer() {
    IS_VIEWER_RUNNING.store(false, Ordering::Relaxed);
}

/// Reusable UDP socket for sending input (lazy-initialized)
static INPUT_SOCKET: tokio::sync::OnceCell<UdpSocket> = tokio::sync::OnceCell::const_new();

async fn get_input_socket() -> &'static UdpSocket {
    INPUT_SOCKET
        .get_or_init(|| async {
            UdpSocket::bind("0.0.0.0:0").await.expect("Failed to bind input socket")
        })
        .await
}

pub async fn send_input(ip: String, port: u16, cmd: InputCommand) -> anyhow::Result<()> {
    let socket = get_input_socket().await;
    let data = bincode::serialize(&cmd)?;
    socket.send_to(&data, format!("{}:{}", ip, port + 1)).await?;
    Ok(())
}
