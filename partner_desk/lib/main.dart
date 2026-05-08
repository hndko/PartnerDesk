import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:partner_desk/src/rust/api/remote.dart';
import 'package:partner_desk/src/rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  runApp(const PartnerDeskApp());
}

// ─────────────────────────────────────────────
// App Root
// ─────────────────────────────────────────────
class PartnerDeskApp extends StatelessWidget {
  const PartnerDeskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PartnerDesk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Segoe UI',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: const Color(0xFF1E1E2E),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A2A3E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// ─────────────────────────────────────────────
// Home Screen
// ─────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _ipController = TextEditingController();
  bool _isHosting = false;
  String _localIp = '...';
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _fetchLocalIp();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ipController.dispose();
    _pulseController.dispose();
    super.dispose();
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
      if (mounted) setState(() => _localIp = ip);
    } catch (e) {
      if (mounted) setState(() => _localIp = 'Error');
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
          _showSnack('Host error: $e', isError: true);
          setState(() => _isHosting = false);
        }
      }
    }
  }

  void _connect() {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      _showSnack('Masukkan IP Address partner terlebih dahulu', isError: true);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ViewerScreen(ip: ip, port: 9090)),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(msg)),
        ],
      ),
      backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade800,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121220),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  // ── Logo & Title ──
                  _buildHeader(),
                  const SizedBox(height: 32),
                  // ── Host Card ──
                  _buildHostCard(),
                  const SizedBox(height: 20),
                  // ── Connect Card ──
                  _buildConnectCard(),
                  const SizedBox(height: 32),
                  // ── Footer ──
                  Text(
                    'PartnerDesk v1.0 · Made with ❤️ & Rust',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.3)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF3F51B5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.desktop_windows_rounded, size: 40, color: Colors.white),
        ),
        const SizedBox(height: 20),
        const Text(
          'PartnerDesk',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Remote Desktop · High Performance',
          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5)),
        ),
      ],
    );
  }

  Widget _buildHostCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Status indicator
            Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) => Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isHosting
                          ? Color.lerp(Colors.green, Colors.green.shade300, _pulseController.value)
                          : Colors.grey.shade600,
                      boxShadow: _isHosting
                          ? [BoxShadow(color: Colors.green.withOpacity(0.5), blurRadius: 8)]
                          : [],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _isHosting ? 'Hosting Aktif' : 'Hosting Nonaktif',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _isHosting ? Colors.green.shade300 : Colors.grey,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.screen_share_rounded, color: Color(0xFF6C63FF), size: 28),
              ],
            ),
            const SizedBox(height: 20),

            // IP Address display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A3E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isHosting
                      ? const Color(0xFF6C63FF).withOpacity(0.4)
                      : Colors.white.withOpacity(0.06),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.wifi, size: 20,
                      color: _isHosting ? const Color(0xFF6C63FF) : Colors.grey),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'IP Address Anda',
                        style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4)),
                      ),
                      const SizedBox(height: 2),
                      SelectableText(
                        _localIp,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    color: Colors.white.withOpacity(0.4),
                    tooltip: 'Salin IP',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _localIp));
                      _showSnack('IP Address disalin!');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Host button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _toggleHost,
                icon: Icon(_isHosting ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 22),
                label: Text(
                  _isHosting ? 'Stop Hosting' : 'Start Hosting',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isHosting ? const Color(0xFFE53935) : const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.link_rounded, color: Color(0xFF4CAF50), size: 28),
                const SizedBox(width: 10),
                const Text(
                  'Remote Partner',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _ipController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 16, letterSpacing: 1),
              decoration: const InputDecoration(
                hintText: '192.168.x.x',
                hintStyle: TextStyle(color: Colors.grey),
                labelText: 'Partner IP Address',
                prefixIcon: Icon(Icons.computer_rounded, color: Color(0xFF4CAF50)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _connect,
                icon: const Icon(Icons.connect_without_contact_rounded, size: 22),
                label: const Text(
                  'Connect',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Viewer Screen (Remote Display)
// ─────────────────────────────────────────────
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
  bool _isConnecting = true;
  Timer? _connectionTimeoutTimer;
  int _frameCount = 0;
  DateTime? _sessionStart;

  // Keyboard support
  final FocusNode _keyboardFocusNode = FocusNode();
  final TextEditingController _hiddenTextController = TextEditingController();
  bool _showKeyboard = false;
  bool _showSpecialKeys = false;

  @override
  void initState() {
    super.initState();
    _sessionStart = DateTime.now();
    _startReceiving();

    // Listen for text changes to send keystrokes
    _hiddenTextController.addListener(_onTextChanged);
  }

  String _previousText = '';

  void _onTextChanged() {
    final current = _hiddenTextController.text;
    if (current.length > _previousText.length) {
      // New character(s) typed
      final newChars = current.substring(_previousText.length);
      sendInput(
        ip: widget.ip,
        port: widget.port,
        cmd: InputCommand.keyboardType(text: newChars),
      );
    } else if (current.length < _previousText.length) {
      // Character deleted (backspace)
      sendInput(
        ip: widget.ip,
        port: widget.port,
        cmd: const InputCommand.keyboardSpecial(keyName: 'backspace'),
      );
    }
    _previousText = current;
  }

  void _sendSpecialKey(String keyName) {
    sendInput(
      ip: widget.ip,
      port: widget.port,
      cmd: InputCommand.keyboardSpecial(keyName: keyName),
    );
  }

  void _toggleKeyboard() {
    setState(() {
      _showKeyboard = !_showKeyboard;
    });
    if (_showKeyboard) {
      _keyboardFocusNode.requestFocus();
    } else {
      _keyboardFocusNode.unfocus();
    }
  }

  void _startReceiving() async {
    _connectionTimeoutTimer = Timer(const Duration(seconds: 10), () {
      if (!_isConnected && mounted) {
        _streamSubscription?.cancel();
        stopViewer();
        _showTimeoutDialog();
      }
    });

    try {
      final stream = await startViewer(ip: widget.ip, port: widget.port);
      _streamSubscription = stream.listen((frame) {
        if (mounted) {
          _connectionTimeoutTimer?.cancel();
          setState(() {
            _currentFrame = frame;
            _isConnected = true;
            _isConnecting = false;
            _frameCount++;
          });
        }
      }, onError: (e) {
        _connectionTimeoutTimer?.cancel();
        _handleDisconnect('Koneksi error: ${e.toString()}');
      }, onDone: () {
        _connectionTimeoutTimer?.cancel();
        _handleDisconnect('Koneksi ditutup oleh host');
      });
    } catch (e) {
      _connectionTimeoutTimer?.cancel();
      if (mounted) {
        _showTimeoutDialog(message: e.toString());
      }
    }
  }

  void _showTimeoutDialog({String? message}) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.cloud_off_rounded, color: Colors.orangeAccent, size: 48),
        title: const Text('Partner Offline',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          message ?? 'Tidak dapat terhubung ke ${widget.ip}.\nPastikan partner sudah menyalakan "Start Hosting" terlebih dahulu.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.7), height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isConnecting = true;
                _isConnected = false;
              });
              _startReceiving();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba Lagi'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Kembali'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
            ),
          ),
        ],
      ),
    );
  }

  void _handleDisconnect(String reason) {
    if (!mounted) return;
    _showSessionSummary(reason);
  }

  void _showSessionSummary(String reason) {
    final duration = _sessionStart != null
        ? DateTime.now().difference(_sessionStart!)
        : Duration.zero;
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.summarize_rounded, color: Color(0xFF6C63FF), size: 48),
        title: const Text('Sesi Selesai',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sessionRow(Icons.access_time_rounded, 'Durasi', '${minutes}m ${seconds}s'),
            const SizedBox(height: 10),
            _sessionRow(Icons.image_rounded, 'Total Frame', '$_frameCount'),
            const SizedBox(height: 10),
            _sessionRow(Icons.computer_rounded, 'Partner', widget.ip),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.orangeAccent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      reason,
                      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.home_rounded),
            label: const Text('Kembali ke Home'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sessionRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white.withOpacity(0.4)),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5))),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }

  @override
  void dispose() {
    _connectionTimeoutTimer?.cancel();
    _streamSubscription?.cancel();
    _hiddenTextController.removeListener(_onTextChanged);
    _hiddenTextController.dispose();
    _keyboardFocusNode.dispose();
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
        monitorHeight: maxHeight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            _streamSubscription?.cancel();
            stopViewer();
            _showSessionSummary('Sesi diakhiri oleh Anda');
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isConnected ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _isConnected ? widget.ip : 'Menghubungkan...',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          // Right-click button
          if (_isConnected)
            IconButton(
              icon: const Icon(Icons.mouse_rounded, size: 20),
              tooltip: 'Right Click',
              onPressed: () {
                sendInput(
                  ip: widget.ip,
                  port: widget.port,
                  cmd: const InputCommand.mouseRightClick(),
                );
              },
            ),
          // Special keys toggle
          if (_isConnected)
            IconButton(
              icon: Icon(
                Icons.keyboard_command_key_rounded,
                size: 20,
                color: _showSpecialKeys ? const Color(0xFF6C63FF) : null,
              ),
              tooltip: 'Special Keys',
              onPressed: () => setState(() => _showSpecialKeys = !_showSpecialKeys),
            ),
        ],
      ),
      // Hidden text field to capture keyboard input
      body: Stack(
        children: [
          // Main content
          Center(
            child: _isConnecting && _currentFrame == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF6C63FF)),
                      const SizedBox(height: 20),
                      Text(
                        'Menghubungkan ke ${widget.ip}...',
                        style: TextStyle(color: Colors.white.withOpacity(0.5)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Menunggu respons host (timeout 10 detik)',
                        style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.3)),
                      ),
                    ],
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return Listener(
                        onPointerHover: (details) =>
                            _sendMouseEvent(details, constraints.maxWidth, constraints.maxHeight),
                        onPointerMove: (details) =>
                            _sendMouseEvent(details, constraints.maxWidth, constraints.maxHeight),
                        onPointerDown: (details) {
                          sendInput(
                              ip: widget.ip,
                              port: widget.port,
                              cmd: const InputCommand.mouseLeftClick());
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

          // Hidden text field (invisible, for capturing keyboard input)
          if (_showKeyboard)
            Positioned(
              bottom: -100, // Off-screen, just to capture input
              left: 0,
              right: 0,
              child: TextField(
                controller: _hiddenTextController,
                focusNode: _keyboardFocusNode,
                autofocus: true,
                decoration: const InputDecoration(border: InputBorder.none),
                style: const TextStyle(color: Colors.transparent, height: 0),
              ),
            ),

          // Special keys toolbar
          if (_showSpecialKeys && _isConnected)
            Positioned(
              bottom: _showKeyboard ? 280 : 80,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2E).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _specialKeyBtn('Esc', 'escape'),
                      _specialKeyBtn('Tab', 'tab'),
                      _specialKeyBtn('⏎', 'enter'),
                      _specialKeyBtn('⌫', 'backspace'),
                      _specialKeyBtn('Del', 'delete'),
                      _specialKeyBtn('Space', 'space'),
                      const SizedBox(width: 8),
                      Container(width: 1, height: 28, color: Colors.white24),
                      const SizedBox(width: 8),
                      _specialKeyBtn('←', 'left'),
                      _specialKeyBtn('↑', 'up'),
                      _specialKeyBtn('↓', 'down'),
                      _specialKeyBtn('→', 'right'),
                      const SizedBox(width: 8),
                      Container(width: 1, height: 28, color: Colors.white24),
                      const SizedBox(width: 8),
                      _specialKeyBtn('Home', 'home'),
                      _specialKeyBtn('End', 'end'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),

      // Floating keyboard toggle button
      floatingActionButton: _isConnected
          ? FloatingActionButton(
              onPressed: _toggleKeyboard,
              backgroundColor: _showKeyboard ? const Color(0xFF6C63FF) : const Color(0xFF2A2A3E),
              child: Icon(
                _showKeyboard ? Icons.keyboard_hide_rounded : Icons.keyboard_rounded,
                color: Colors.white,
              ),
            )
          : null,
    );
  }

  Widget _specialKeyBtn(String label, String keyName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _sendSpecialKey(keyName),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
