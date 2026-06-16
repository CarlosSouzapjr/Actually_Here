import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/server_config.dart';

class ServerDiscoveryService {
  const ServerDiscoveryService();

  Future<bool> testEndpoint(ServerEndpoint endpoint) async {
    try {
      final response = await http
          .get(Uri.parse(endpoint.apiUrl('health')))
          .timeout(const Duration(milliseconds: 900));

      if (response.statusCode != 200) return false;
      return response.body.contains('actually-here-backend') ||
          response.body.contains('"status"');
    } catch (_) {
      return false;
    }
  }

  Future<ServerEndpoint?> discover({
    required int apiPort,
    required int mqttPort,
    void Function(String message)? onProgress,
  }) async {
    final prefixes = await _localNetworkPrefixes();
    if (prefixes.isEmpty) {
      onProgress?.call('Nenhuma rede local encontrada no aparelho.');
      return null;
    }

    for (final prefix in prefixes) {
      onProgress?.call('Procurando em $prefix.0/24...');
      final found = await _scanPrefix(
        prefix: prefix,
        apiPort: apiPort,
        mqttPort: mqttPort,
      );
      if (found != null) return found;
    }

    return null;
  }

  Future<List<String>> _localNetworkPrefixes() async {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );

    final prefixes = <String>{};
    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        final parts = address.address.split('.');
        if (parts.length == 4 && !_isIgnoredAddress(parts)) {
          prefixes.add('${parts[0]}.${parts[1]}.${parts[2]}');
        }
      }
    }

    final sortedPrefixes = prefixes.toList()
      ..sort((a, b) => _prefixPriority(a).compareTo(_prefixPriority(b)));
    return sortedPrefixes;
  }

  int _prefixPriority(String prefix) {
    final parts = prefix.split('.');
    if (parts.length != 3) return 4;

    final first = int.tryParse(parts[0]) ?? -1;
    final second = int.tryParse(parts[1]) ?? -1;

    if (first == 192 && second == 168) return 0;
    if (first == 172 && second >= 16 && second <= 31) return 1;
    if (first == 10) return 2;
    return 3;
  }

  bool _isIgnoredAddress(List<String> parts) {
    final first = int.tryParse(parts[0]) ?? 0;
    final second = int.tryParse(parts[1]) ?? 0;

    return first == 127 ||
        first == 0 ||
        first >= 224 ||
        (first == 169 && second == 254);
  }

  Future<ServerEndpoint?> _scanPrefix({
    required String prefix,
    required int apiPort,
    required int mqttPort,
  }) async {
    const batchSize = 32;

    for (var start = 1; start <= 254; start += batchSize) {
      final end = (start + batchSize - 1).clamp(1, 254);
      final futures = <Future<ServerEndpoint?>>[];

      for (var hostPart = start; hostPart <= end; hostPart++) {
        final endpoint = ServerEndpoint(
          host: '$prefix.$hostPart',
          apiPort: apiPort,
          mqttPort: mqttPort,
        );
        futures.add(_tryEndpoint(endpoint));
      }

      final results = await Future.wait(futures);
      for (final result in results) {
        if (result != null) return result;
      }
    }

    return null;
  }

  Future<ServerEndpoint?> _tryEndpoint(ServerEndpoint endpoint) async {
    try {
      final response = await http
          .get(Uri.parse(endpoint.apiUrl('health')))
          .timeout(const Duration(milliseconds: 350));

      if (response.statusCode == 200 &&
          response.body.contains('actually-here-backend')) {
        return endpoint;
      }
    } catch (_) {
      return null;
    }

    return null;
  }
}
