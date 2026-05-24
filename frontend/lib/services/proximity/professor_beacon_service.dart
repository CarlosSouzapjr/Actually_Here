import 'dart:io';
import 'package:beacon_broadcast/beacon_broadcast.dart';
import 'package:permission_handler/permission_handler.dart';

class ProfessorBeaconService {
  final BeaconBroadcast _beaconBroadcast = BeaconBroadcast();

  /// Verifica se o dispositivo suporta atuar como Beacon.
  Future<bool> checkTransmissionSupport() async {
    try {
      final BeaconStatus transmissionSupportStatus = await _beaconBroadcast.checkTransmissionSupported();
      print('Status de suporte de transmissão: $transmissionSupportStatus');
      return transmissionSupportStatus == BeaconStatus.supported;
    } catch (e) {
      print('Erro ao verificar suporte de transmissão: $e');
      return false;
    }
  }

  /// Inicializa e começa a transmitir o UUID do professor como um Beacon.
  Future<void> startBroadcasting(String professorUuid) async {
    try {
      print('Iniciando broadcast do Beacon para UUID: $professorUuid');
      
      // Pede múltiplas permissões simultaneamente para cobrir Android 11 e Android 12+
      if (Platform.isAndroid) {
        await [
          Permission.bluetooth,
          Permission.bluetoothAdvertise,
          Permission.bluetoothConnect,
          Permission.location,
        ].request();
        
        var advStatus = await Permission.bluetoothAdvertise.status;
        var bthStatus = await Permission.bluetooth.status;
        if (!advStatus.isGranted && !bthStatus.isGranted) {
          print('Permissões de Bluetooth não concedidas.');
          throw Exception('Permissão de Bluetooth/Advertising necessária');
        }
      } else if (Platform.isIOS) {
        var status = await Permission.bluetooth.request();
        if (!status.isGranted) {
          throw Exception('Permissão de Bluetooth necessária');
        }
      }

      final isSupported = await checkTransmissionSupport();
      if (!isSupported) {
        print('Dispositivo não suporta transmissão de Beacon.');
        throw Exception('Transmissão não suportada pelo dispositivo');
      }

      // Configura o beacon com os parâmetros definidos
      _beaconBroadcast
          .setUUID(professorUuid)
          .setMajorId(1)
          .setMinorId(1)
          .setTransmissionPower(-59)
          .setLayout('m:2-3=0215,i:4-19,i:20-21,i:22-23,p:24-24')
          .start();
          
      print('Broadcast de Beacon iniciado com sucesso!');
    } catch (e) {
      print('Erro ao iniciar o broadcast do Beacon: $e');
      rethrow;
    }
  }

  /// Para a transmissão do Beacon.
  Future<void> stopBroadcasting() async {
    try {
      print('Parando broadcast do Beacon...');
      _beaconBroadcast.stop();
      print('Broadcast parado.');
    } catch (e) {
      print('Erro ao parar broadcast: $e');
    }
  }
}
