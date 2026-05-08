import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:partner_desk/src/rust/api/remote.dart';
import 'package:partner_desk/src/rust/frb_generated.dart';
import 'package:partner_desk/discovery_service.dart';

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
  StreamSubscription? _sub;
  Uint8List? _frame;
  bool _connected = false;
  bool _connecting = true;
  Timer? _timeout;
  int _frameCount = 0;
  DateTime? _sessionStart;
  final FocusNode _kbFocus = FocusNode();
  final TextEditingController _kbCtrl = TextEditingController();
  bool _showKb = false;
  bool _showSpecial = false;
  String _prevText = '';

  @override
  void initState() {
    super.initState();
    _sessionStart = DateTime.now();
    _kbCtrl.addListener(_onText);
    _startReceiving();
  }

  void _onText() {
    final cur = _kbCtrl.text;
    if (cur.length > _prevText.length) {
      sendInput(ip: widget.ip, port: widget.port, cmd: InputCommand.keyboardType(text: cur.substring(_prevText.length)));
    } else if (cur.length < _prevText.length) {
      sendInput(ip: widget.ip, port: widget.port, cmd: const InputCommand.keyboardSpecial(keyName: 'backspace'));
    }
    _prevText = cur;
  }

  void _sendKey(String k) => sendInput(ip: widget.ip, port: widget.port, cmd: InputCommand.keyboardSpecial(keyName: k));

  void _toggleKb() {
    setState(() => _showKb = !_showKb);
    _showKb ? _kbFocus.requestFocus() : _kbFocus.unfocus();
  }

  void _startReceiving() async {
    _timeout = Timer(const Duration(seconds: 10), () {
      if (!_connected && mounted) { _sub?.cancel(); stopViewer(); _showTimeout(); }
    });
    try {
      final stream = await startViewer(ip: widget.ip, port: widget.port);
      _sub = stream.listen((f) {
        if (mounted) { _timeout?.cancel(); setState(() { _frame = f; _connected = true; _connecting = false; _frameCount++; }); }
      }, onError: (e) { _timeout?.cancel(); _disconnect('Koneksi error: $e'); },
         onDone: () { _timeout?.cancel(); _disconnect('Koneksi ditutup oleh host'); });
    } catch (e) {
      _timeout?.cancel();
      if (mounted) _showTimeout(msg: e.toString());
    }
  }

  void _showTimeout({String? msg}) {
    if (!mounted) return;
    showDialog(context: context, barrierDismissible: false, builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: const Icon(Icons.cloud_off_rounded, color: Colors.orangeAccent, size: 48),
      title: const Text('Partner Offline', style: TextStyle(fontWeight: FontWeight.w700)),
      content: Text(msg ?? 'Tidak dapat terhubung.\nPastikan partner sudah Start Hosting.',
        textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.7), height: 1.5)),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton.icon(onPressed: () { Navigator.pop(context); setState(() { _connecting = true; _connected = false; }); _startReceiving(); },
          icon: const Icon(Icons.refresh_rounded), label: const Text('Coba Lagi')),
        FilledButton.icon(onPressed: () { Navigator.pop(context); Navigator.pop(context); },
          icon: const Icon(Icons.arrow_back_rounded), label: const Text('Kembali'),
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6C63FF))),
      ],
    ));
  }

  void _disconnect(String reason) { if (mounted) _showSession(reason); }

  void _showSession(String reason) {
    final d = _sessionStart != null ? DateTime.now().difference(_sessionStart!) : Duration.zero;
    showDialog(context: context, barrierDismissible: false, builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: const Icon(Icons.summarize_rounded, color: Color(0xFF6C63FF), size: 48),
      title: const Text('Sesi Selesai', style: TextStyle(fontWeight: FontWeight.w700)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _row(Icons.access_time_rounded, 'Durasi', '${d.inMinutes}m ${d.inSeconds % 60}s'),
        const SizedBox(height: 10),
        _row(Icons.image_rounded, 'Total Frame', '$_frameCount'),
        const SizedBox(height: 10),
        _row(Icons.computer_rounded, 'Partner', widget.ip),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.withOpacity(0.3))),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded, color: Colors.orangeAccent, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(reason, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)))),
          ]),
        ),
      ]),
      actionsAlignment: MainAxisAlignment.center,
      actions: [FilledButton.icon(
        onPressed: () { Navigator.pop(context); Navigator.pop(context); },
        icon: const Icon(Icons.home_rounded), label: const Text('Kembali ke Home'),
        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
      )],
    ));
  }

  Widget _row(IconData i, String l, String v) => Row(children: [
    Icon(i, size: 18, color: Colors.white.withOpacity(0.4)),
    const SizedBox(width: 12),
    Text(l, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5))),
    const Spacer(),
    Text(v, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
  ]);

  @override
  void dispose() {
    _timeout?.cancel(); _sub?.cancel(); _kbCtrl.removeListener(_onText);
    _kbCtrl.dispose(); _kbFocus.dispose(); stopViewer(); super.dispose();
  }

  void _mouseEv(PointerEvent d, double w, double h) {
    if (!_connected) return;
    sendInput(ip: widget.ip, port: widget.port, cmd: InputCommand.mouseMove(
      x: d.localPosition.dx, y: d.localPosition.dy, monitorWidth: w, monitorHeight: h));
  }

  Widget _keyBtn(String label, String key) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3),
    child: Material(color: const Color(0xFF2A2A3E), borderRadius: BorderRadius.circular(10),
      child: InkWell(borderRadius: BorderRadius.circular(10), onTap: () => _sendKey(key),
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70))))),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () { _sub?.cancel(); stopViewer(); _showSession('Sesi diakhiri oleh Anda'); }),
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: _connected ? Colors.green : Colors.orange)),
          const SizedBox(width: 8),
          Text(_connected ? widget.ip : 'Menghubungkan...', style: const TextStyle(fontSize: 14)),
        ]),
        centerTitle: true,
        actions: [
          if (_connected) IconButton(icon: const Icon(Icons.mouse_rounded, size: 20), tooltip: 'Right Click',
            onPressed: () => sendInput(ip: widget.ip, port: widget.port, cmd: const InputCommand.mouseRightClick())),
          if (_connected) IconButton(
            icon: Icon(Icons.keyboard_command_key_rounded, size: 20, color: _showSpecial ? const Color(0xFF6C63FF) : null),
            tooltip: 'Special Keys', onPressed: () => setState(() => _showSpecial = !_showSpecial)),
        ],
      ),
      body: Stack(children: [
        Center(child: _connecting && _frame == null
          ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const CircularProgressIndicator(color: Color(0xFF6C63FF)),
              const SizedBox(height: 20),
              Text('Menghubungkan ke ${widget.ip}...', style: TextStyle(color: Colors.white.withOpacity(0.5))),
              const SizedBox(height: 8),
              Text('Menunggu respons host (timeout 10 detik)', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.3))),
            ])
          : LayoutBuilder(builder: (ctx, c) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                // Move cursor to tap position first, then click
                sendInput(ip: widget.ip, port: widget.port, cmd: InputCommand.mouseMove(
                  x: details.localPosition.dx, y: details.localPosition.dy, monitorWidth: c.maxWidth, monitorHeight: c.maxHeight));
                sendInput(ip: widget.ip, port: widget.port, cmd: const InputCommand.mouseLeftClick());
              },
              onLongPressStart: (details) {
                sendInput(ip: widget.ip, port: widget.port, cmd: InputCommand.mouseMove(
                  x: details.localPosition.dx, y: details.localPosition.dy, monitorWidth: c.maxWidth, monitorHeight: c.maxHeight));
                sendInput(ip: widget.ip, port: widget.port, cmd: const InputCommand.mouseRightClick());
              },
              onPanUpdate: (details) {
                if (!_connected) return;
                sendInput(ip: widget.ip, port: widget.port, cmd: InputCommand.mouseMove(
                  x: details.localPosition.dx, y: details.localPosition.dy, monitorWidth: c.maxWidth, monitorHeight: c.maxHeight));
              },
              child: Image.memory(_frame!, fit: BoxFit.contain, gaplessPlayback: true),
            )),
        ),
        if (_showKb) Positioned(bottom: -100, left: 0, right: 0,
          child: TextField(controller: _kbCtrl, focusNode: _kbFocus, autofocus: true,
            decoration: const InputDecoration(border: InputBorder.none),
            style: const TextStyle(color: Colors.transparent, height: 0))),
        if (_showSpecial && _connected) Positioned(
          bottom: _showKb ? 280 : 80, left: 0, right: 0,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFF1E1E2E).withOpacity(0.95), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.1))),
            child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
              _keyBtn('Esc', 'escape'), _keyBtn('Tab', 'tab'), _keyBtn('⏎', 'enter'), _keyBtn('⌫', 'backspace'),
              _keyBtn('Del', 'delete'), _keyBtn('Space', 'space'),
              const SizedBox(width: 8), Container(width: 1, height: 28, color: Colors.white24), const SizedBox(width: 8),
              _keyBtn('←', 'left'), _keyBtn('↑', 'up'), _keyBtn('↓', 'down'), _keyBtn('→', 'right'),
              const SizedBox(width: 8), Container(width: 1, height: 28, color: Colors.white24), const SizedBox(width: 8),
              _keyBtn('Home', 'home'), _keyBtn('End', 'end'),
            ])),
          ),
        ),
      ]),
      floatingActionButton: _connected
        ? FloatingActionButton(onPressed: _toggleKb,
            backgroundColor: _showKb ? const Color(0xFF6C63FF) : const Color(0xFF2A2A3E),
            child: Icon(_showKb ? Icons.keyboard_hide_rounded : Icons.keyboard_rounded, color: Colors.white))
        : null,
    );
  }
}
