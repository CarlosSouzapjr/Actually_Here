import 'package:flutter/foundation.dart';

class ServerEndpoint {
  const ServerEndpoint({
    required this.host,
    required this.apiPort,
    required this.mqttPort,
  });

  final String host;
  final int apiPort;
  final int mqttPort;

  String get apiBaseUrl => 'http://$host:$apiPort/api';
  String apiUrl(String path) => '$apiBaseUrl/$path';
}

class ServerConfig {
  static final ValueNotifier<ServerEndpoint> endpoint =
      ValueNotifier<ServerEndpoint>(_defaultEndpoint);

  static const ServerEndpoint _defaultEndpoint = ServerEndpoint(
    host: 'localhost',
    apiPort: 8080,
    mqttPort: 1883,
  );

  static ServerEndpoint get current => endpoint.value;

  static void update({required String host, int? apiPort, int? mqttPort}) {
    endpoint.value = ServerEndpoint(
      host: host.trim(),
      apiPort: apiPort ?? current.apiPort,
      mqttPort: mqttPort ?? current.mqttPort,
    );
  }
}
