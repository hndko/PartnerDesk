import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:partner_desk/src/rust/api/remote.dart';
import 'package:partner_desk/src/rust/frb_generated.dart';
import 'package:partner_desk/discovery_service.dart';
import 'package:partner_desk/viewer_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  await DiscoveryService.startListening();
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
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: const Color(0xFF1E1E2E),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A2A3E),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2)),
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
// Home Screen - 2 Column Layout + ID System
// ─────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _idController = TextEditingController();
  bool _isHosting = false;
  bool _isResolving = false;
  String _localIp = '...';
  late AnimationController _pulseController;

  String get _myId => DiscoveryService.deviceId;

  @override
  void initState() {
    super.initState();
    _fetchLocalIp();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _idController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocalIp() async {
    final ip = await DiscoveryService.getLocalIp();
    if (mounted) setState(() => _localIp = ip);
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

  void _connectById() async {
    final id = _idController.text.trim();
    if (id.isEmpty) {
      _showSnack('Masukkan Partner ID terlebih dahulu', isError: true);
      return;
    }

    setState(() => _isResolving = true);
    _showSnack('Mencari partner $id di jaringan...');

    final ip = await DiscoveryService.resolveId(id);

    if (!mounted) return;
    setState(() => _isResolving = false);

    if (ip != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ViewerScreen(ip: ip, port: 9090)));
    } else {
      _showSnack('Partner ID "$id" tidak ditemukan. Pastikan partner online dan satu jaringan.', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline : Icons.search_rounded, color: Colors.white, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: isError ? Colors.red.shade800 : Colors.blue.shade800,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: const Color(0xFF121220),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  // ── 2-Column Layout ──
                  isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildHostCard()),
                            const SizedBox(width: 20),
                            Expanded(child: _buildConnectCard()),
                          ],
                        )
                      : Column(children: [
                          _buildHostCard(),
                          const SizedBox(height: 20),
                          _buildConnectCard(),
                        ]),
                  const SizedBox(height: 32),
                  Text('PartnerDesk v1.0 · Made with ❤️ & Rust',
                      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.3))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF3F51B5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: const Icon(Icons.desktop_windows_rounded, size: 40, color: Colors.white),
      ),
      const SizedBox(height: 20),
      const Text('PartnerDesk', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      const SizedBox(height: 6),
      Text('Remote Desktop · High Performance', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5))),
    ]);
  }

  Widget _buildHostCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          // Status row
          Row(children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isHosting ? Color.lerp(Colors.green, Colors.green.shade300, _pulseController.value) : Colors.grey.shade600,
                  boxShadow: _isHosting ? [BoxShadow(color: Colors.green.withOpacity(0.5), blurRadius: 8)] : [],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(_isHosting ? 'Hosting Aktif' : 'Hosting Nonaktif',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _isHosting ? Colors.green.shade300 : Colors.grey)),
            const Spacer(),
            const Icon(Icons.screen_share_rounded, color: Color(0xFF6C63FF), size: 28),
          ]),
          const SizedBox(height: 20),

          // Your ID
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A3E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _isHosting ? const Color(0xFF6C63FF).withOpacity(0.4) : Colors.white.withOpacity(0.06)),
            ),
            child: Row(children: [
              Icon(Icons.fingerprint_rounded, size: 24, color: _isHosting ? const Color(0xFF6C63FF) : Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Your ID', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4))),
                  const SizedBox(height: 2),
                  SelectableText(_myId, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 2)),
                ]),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                color: Colors.white.withOpacity(0.4),
                tooltip: 'Salin ID',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _myId));
                  _showSnack('ID disalin!');
                },
              ),
            ]),
          ),
          const SizedBox(height: 12),

          // IP Address (secondary info)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A3E).withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Icon(Icons.wifi_rounded, size: 16, color: Colors.white.withOpacity(0.3)),
              const SizedBox(width: 8),
              Text('IP: $_localIp', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4))),
            ]),
          ),
          const SizedBox(height: 20),

          // Host button
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: _toggleHost,
              icon: Icon(_isHosting ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 22),
              label: Text(_isHosting ? 'Stop Hosting' : 'Start Hosting', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isHosting ? const Color(0xFFE53935) : const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildConnectCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Row(children: [
            const Icon(Icons.link_rounded, color: Color(0xFF4CAF50), size: 28),
            const SizedBox(width: 10),
            const Text('Remote Partner', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 20),
          TextField(
            controller: _idController,
            style: const TextStyle(fontSize: 18, letterSpacing: 2, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              hintText: 'XXX-XXX-XXX',
              hintStyle: TextStyle(color: Colors.grey, letterSpacing: 2),
              labelText: 'Partner ID',
              prefixIcon: Icon(Icons.fingerprint_rounded, color: Color(0xFF4CAF50)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: _isResolving ? null : _connectById,
              icon: _isResolving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.connect_without_contact_rounded, size: 22),
              label: Text(_isResolving ? 'Mencari...' : 'Connect', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50), foregroundColor: Colors.white),
            ),
          ),
        ]),
      ),
    );
  }
}
