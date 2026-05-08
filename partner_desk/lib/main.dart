import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:partner_desk/src/rust/api/remote.dart';
import 'package:partner_desk/src/rust/frb_generated.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const PartnerDeskApp());
}

class PartnerDeskApp extends StatelessWidget {
  const PartnerDeskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PartnerDesk',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _ipController = TextEditingController(text: '127.0.0.1');
  bool _isHosting = false;
  String _localIp = "Mencari IP...";

  @override
  void initState() {
    super.initState();
    _fetchLocalIp();
  }

  Future<void> _fetchLocalIp() async {
    try {
      String ip = 'Tidak ditemukan';
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            ip = addr.address;
            break;
          }
        }
      }
      if (mounted) {
        setState(() {
          _localIp = ip;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _localIp = 'Gagal mengambil IP';
        });
      }
    }
  }

  void _toggleHost() async {
    if (_isHosting) {
      stopHost();
      setState(() => _isHosting = false);
    } else {
      setState(() => _isHosting = true);
      try {
        await startHost(port: 9090);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Host error: $e')));
          setState(() => _isHosting = false);
        }
      }
    }
  }

  void _connect() {
    final ip = _ipController.text;
    if (ip.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ViewerScreen(ip: ip, port: 9090)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PartnerDesk', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const Icon(Icons.screen_share, size: 64, color: Colors.blue),
                        const SizedBox(height: 16),
                        const Text('Share Your Screen', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Column(
                            children: [
                              const Text('IP Address Anda:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 4),
                              SelectableText(
                                _localIp,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _toggleHost,
                          icon: Icon(_isHosting ? Icons.stop : Icons.play_arrow),
                          label: Text(_isHosting ? 'Stop Hosting' : 'Start Hosting'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isHosting ? Colors.red.shade700 : Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            minimumSize: const Size.fromHeight(50),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const Icon(Icons.settings_remote, size: 64, color: Colors.green),
                        const SizedBox(height: 16),
                        const Text('Connect to Partner', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _ipController,
                          decoration: const InputDecoration(
                            labelText: 'Partner IP Address',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.computer),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _isHosting ? null : _connect,
                          icon: const Icon(Icons.connect_without_contact),
                          label: const Text('Connect'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            minimumSize: const Size.fromHeight(50),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ViewerScreen extends StatefulWidget {
  final String ip;
  final int port;

  const ViewerScreen({super.key, required this.ip, required this.port});

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  StreamSubscription? _streamSubscription;
  Uint8List? _currentFrame;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _startReceiving();
  }

  void _startReceiving() async {
    try {
      final stream = await startViewer(ip: widget.ip, port: widget.port);
      _streamSubscription = stream.listen((frame) {
        if (mounted) {
          setState(() {
            _currentFrame = frame;
            _isConnected = true;
          });
        }
      }, onError: (e) {
        _handleDisconnect(e.toString());
      }, onDone: () {
        _handleDisconnect('Connection closed by host');
      });
    } catch (e) {
      _handleDisconnect(e.toString());
    }
  }

  void _handleDisconnect(String reason) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Disconnected: $reason')));
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    stopViewer();
    super.dispose();
  }

  void _sendMouseEvent(PointerEvent details, double maxWidth, double maxHeight) {
    if (!_isConnected) return;
    
    sendInput(
      ip: widget.ip, 
      port: widget.port, 
      cmd: InputCommand.mouseMove(
        x: details.localPosition.dx, 
        y: details.localPosition.dy, 
        monitorWidth: maxWidth, 
        monitorHeight: maxHeight
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Connected to ${widget.ip}'),
        backgroundColor: Colors.black87,
      ),
      body: Center(
        child: _currentFrame == null
            ? const CircularProgressIndicator()
            : LayoutBuilder(
                builder: (context, constraints) {
                  return Listener(
                    onPointerHover: (details) => _sendMouseEvent(details, constraints.maxWidth, constraints.maxHeight),
                    onPointerMove: (details) => _sendMouseEvent(details, constraints.maxWidth, constraints.maxHeight),
                    onPointerDown: (details) {
                      sendInput(ip: widget.ip, port: widget.port, cmd: const InputCommand.mouseLeftClick());
                    },
                    child: Image.memory(
                      _currentFrame!,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  );
                },
              ),
      ),
    );
  }
}
