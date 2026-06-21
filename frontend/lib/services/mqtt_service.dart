import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../config/server_config.dart';

class MqttService {
  late MqttServerClient client;

  MqttService() {
    final endpoint = ServerConfig.current;

    client = MqttServerClient(
      endpoint.host,
      'flutter_client_${DateTime.now().millisecondsSinceEpoch}',
    );
    client.port = endpoint.mqttPort;
    client.keepAlivePeriod = 20;
    client.onDisconnected = onDisconnected;
    client.onConnected = onConnected;
    client.logging(on: false);

    final connMess = MqttConnectMessage()
        .withClientIdentifier(
          'flutter_client_${DateTime.now().millisecondsSinceEpoch}',
        )
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

  void subscribeToClass(int classId, void Function(int studentId, double distance) onPresenceReceived) {
    if (client.connectionStatus!.state != MqttConnectionState.connected) {
      print('MQTT: Cliente não conectado. Não foi possível inscrever-se.');
      return;
    }

    final String topic = 'presenca/$classId/+';
    print('MQTT: Inscrevendo-se no tópico $topic');
    client.subscribe(topic, MqttQos.atLeastOnce);

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c[0].payload as MqttPublishMessage;
      final pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      
      try {
        final data = jsonDecode(pt);
        final distanceStr = data['distancia'];
        final distance = distanceStr is String ? double.parse(distanceStr) : (distanceStr as num).toDouble();
        
        // Topic is 'presenca/classId/studentId'
        final topicParts = c[0].topic.split('/');
        if (topicParts.length == 3) {
          final studentId = int.tryParse(topicParts[2]);
          if (studentId != null) {
            onPresenceReceived(studentId, distance);
          }
        }
      } catch (e) {
        print('MQTT: Erro ao processar mensagem recebida: $e');
      }
    });
  }

  void unsubscribeFromClass(int classId) {
    if (client.connectionStatus!.state != MqttConnectionState.connected) return;
    final String topic = 'presenca/$classId/+';
    print('MQTT: Cancelando inscrição no tópico $topic');
    client.unsubscribe(topic);
  }

  void onConnected() {
    print('MQTT: Conectado com sucesso!');
  }

  void onDisconnected() {
    print('MQTT: Desconectado do broker.');
  }
}
