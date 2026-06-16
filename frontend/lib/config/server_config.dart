import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
      ValueNotifier<ServerEndpoint>(_fromEnv());

  static ServerEndpoint get current => endpoint.value;

  static void update({required String host, int? apiPort, int? mqttPort}) {
    endpoint.value = ServerEndpoint(
      host: host.trim(),
      apiPort: apiPort ?? current.apiPort,
      mqttPort: mqttPort ?? current.mqttPort,
    );
  }

  static ServerEndpoint _fromEnv() {
    return ServerEndpoint(
      host: dotenv.env['SERVER_IP']?.trim().isNotEmpty == true
          ? dotenv.env['SERVER_IP']!.trim()
          : 'localhost',
      apiPort: int.tryParse(dotenv.env['API_PORT'] ?? '') ?? 8080,
      mqttPort: int.tryParse(dotenv.env['MQTT_PORT'] ?? '') ?? 1883,
    );
  }
}
