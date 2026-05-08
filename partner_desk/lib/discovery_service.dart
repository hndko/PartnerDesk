import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'dart:async';

/// LAN Discovery Service - ID-based connection like AnyDesk
/// Uses UDP broadcast on port 9092 for device discovery
class DiscoveryService {
  static const int discoveryPort = 9092;
  static String? _deviceId;
  static String? _localIp;
  static RawDatagramSocket? _socket;
  static bool _isListening = false;

  /// Generate or return cached 9-digit device ID
  static String get deviceId {
    _deviceId ??= _generateId();
    return _deviceId!;
  }

  static String _generateId() {
    final random = Random();
    // Generate 9-digit numeric ID (like AnyDesk format: XXX-XXX-XXX)
    final id = List.generate(9, (_) => random.nextInt(10)).join();
    return '${id.substring(0, 3)}-${id.substring(3, 6)}-${id.substring(6, 9)}';
  }

  /// Fetch local IP
  static Future<String> getLocalIp() async {
    if (_localIp != null) return _localIp!;
    try {
      final allIps = <String>[];
      for (var iface in await NetworkInterface.list()) {
        for (var addr in iface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            allIps.add(addr.address);
          }
        }
      }
      if (allIps.isNotEmpty) {
        // Prefer 192.168.x.x (WiFi) over 10.x.x.x (Ethernet/VPN)
        _localIp = allIps.firstWhere(
          (ip) => ip.startsWith('192.168.'),
          orElse: () => allIps.first,
        );
        return _localIp!;
      }
    } catch (_) {}
    return 'Tidak ditemukan';
  }

  /// Start listening for discovery requests
  static Future<void> startListening() async {
    if (_isListening) return;
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, discoveryPort, reuseAddress: true);
      _socket!.broadcastEnabled = true;
      _isListening = true;

      _socket!.listen((event) async {
        if (event == RawSocketEvent.read) {
          final datagram = _socket!.receive();
          if (datagram == null) return;
          final message = utf8.decode(datagram.data);

          // Handle discovery request: "DISCOVER:<target_id>"
          if (message.startsWith('DISCOVER:')) {
            final targetId = message.substring(9);
            if (targetId == deviceId) {
              final ip = await getLocalIp();
              final response = 'FOUND:$deviceId:$ip';
              _socket!.send(
                utf8.encode(response),
                datagram.address,
                datagram.port,
              );
            }
          }
        }
      });
    } catch (e) {
      print('Discovery listen error: $e');
    }
  }

  /// Look up IP by partner ID via broadcast
  static Future<String?> resolveId(String partnerId) async {
    RawDatagramSocket? client;
    try {
      client = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0, reuseAddress: true);
      client.broadcastEnabled = true;

      final completer = Completer<String?>();
      Timer? timeout;

      final sub = client.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = client!.receive();
          if (datagram == null) return;
          final message = utf8.decode(datagram.data);

          // Handle response: "FOUND:<id>:<ip>"
          if (message.startsWith('FOUND:')) {
            final parts = message.split(':');
            if (parts.length == 3 && parts[1] == partnerId) {
              timeout?.cancel();
              if (!completer.isCompleted) completer.complete(parts[2]);
            }
          }
        }
      });

      // Send broadcast discovery request
      final request = utf8.encode('DISCOVER:$partnerId');
      client.send(request, InternetAddress('255.255.255.255'), discoveryPort);

      // Retry a few times
      for (int i = 1; i <= 3; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (completer.isCompleted) break;
        client.send(request, InternetAddress('255.255.255.255'), discoveryPort);
      }

      timeout = Timer(const Duration(seconds: 5), () {
        if (!completer.isCompleted) completer.complete(null);
      });

      final result = await completer.future;
      await sub.cancel();
      client.close();
      return result;
    } catch (e) {
      client?.close();
      return null;
    }
  }

  static void dispose() {
    _socket?.close();
    _isListening = false;
  }
}
