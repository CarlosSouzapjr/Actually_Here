import 'dart:convert';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MqttService {
  late MqttServerClient client;

  MqttService() {
    String brokerAddress = dotenv.env['SERVER_IP'] ?? 'localhost';
    int port = int.parse(dotenv.env['MQTT_PORT'] ?? '1883');
    
    client = MqttServerClient(brokerAddress, 'flutter_client_${DateTime.now().millisecondsSinceEpoch}');
    client.port = port;
    client.keepAlivePeriod = 20;
    client.onDisconnected = onDisconnected;
    client.onConnected = onConnected;
    client.logging(on: false);

    final connMess = MqttConnectMessage()
        .withClientIdentifier('flutter_client_${DateTime.now().millisecondsSinceEpoch}')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMess;
  }

  Future<bool> connect() async {
    try {
      print('MQTT: Tentando conectar ao broker...');
      await client.connect();
      return client.connectionStatus!.state == MqttConnectionState.connected;
    } catch (e) {
      print('MQTT: Erro ao conectar - $e');
      client.disconnect();
      return false;
    }
  }

  void disconnect() {
    client.disconnect();
  }

  void publishPresence(int classId, int studentId, double distance) {
    if (client.connectionStatus!.state != MqttConnectionState.connected) {
      print('MQTT: Cliente não conectado. Não foi possível publicar.');
      return;
    }

    final String topic = 'presenca/$classId/$studentId';
    final payload = jsonEncode({
      'status': 'presente',
      'distancia': distance.toStringAsFixed(2),
      'timestamp': DateTime.now().toIso8601String(),
    });

    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);

    print('MQTT: Publicando no tópico $topic: $payload');
    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  void onConnected() {
    print('MQTT: Conectado com sucesso!');
  }

  void onDisconnected() {
    print('MQTT: Desconectado do broker.');
  }
}
