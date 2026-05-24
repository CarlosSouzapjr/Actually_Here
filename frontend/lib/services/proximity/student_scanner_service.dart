import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class StudentScannerService {
  
  /// Função auxiliar privada para calcular a distância em metros com base no RSSI
  double _calculateDistance(int rssi) {
    if (rssi == 0) {
      return -1.0; // Sinal não identificado
    }

    try {
      const int txPower = -59; // Potência de transmissão padrão do Beacon
      const double n = 2.0;    // Constante ambiental (2.0 para espaço interior livre)

      // Distância = 10 ^ ((TxPower - RSSI) / (10 * N))
      double ratio = (txPower - rssi) / (10 * n);
      double distance = pow(10, ratio).toDouble();
      
      return distance;
    } catch (e) {
      print('Erro ao calcular distância: $e');
      return -1.0;
    }
  }

  /// Helper para verificar se o dispositivo encontrado é o iBeacon do professor
  bool _isTargetBeacon(ScanResult result, String targetUuid) {
    // Limpar o UUID alvo (remover hifens e deixar em minúsculas)
    final cleanTarget = targetUuid.replaceAll('-', '').toLowerCase();

    // 1. Procurar em todos os Manufacturer Data (Apple, Radius Networks, etc.)
    for (final entry in result.advertisementData.manufacturerData.entries) {
      final bytes = entry.value;
      final hexPayload = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('').toLowerCase();
      
      // Se o UUID estiver em qualquer lugar do payload do fabricante, é o nosso alvo!
      if (hexPayload.contains(cleanTarget)) {
        return true;
      }
    }

    // 2. Por garantia, verificar se não foi emitido como Service UUID normal
    for (final uuid in result.advertisementData.serviceUuids) {
      final hexUuid = uuid.toString().replaceAll('-', '').toLowerCase();
      if (hexUuid == cleanTarget) {
        return true;
      }
    }

    return false;
  }

  /// Inicia o scan pelo UUID do professor e retorna a distância calculada em metros.
  Stream<double> scanForProfessor(String targetUuid) async* {
    try {
      print('Solicitando permissões para scan...');
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.location,
      ].request();

      if (!statuses[Permission.bluetoothScan]!.isGranted ||
          !statuses[Permission.location]!.isGranted) {
        print('Permissões não concedidas para scan.');
        throw Exception('Permissões de Bluetooth Scan e Location são obrigatórias.');
      }

      print('Permissões concedidas. Verificando estado do Bluetooth...');
      
      final state = await FlutterBluePlus.adapterState.first;
      if (state != BluetoothAdapterState.on) {
        if (Platform.isAndroid) {
          try {
            await FlutterBluePlus.turnOn();
          } catch (e) {
            print('Erro ao ligar bluetooth no Android: $e');
            throw Exception('O Bluetooth precisa estar ligado.');
          }
        } else {
          throw Exception('O Bluetooth precisa estar ligado.');
        }
      }

      if (FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.stopScan();
      }

      print('Iniciando scan para achar o iBeacon com UUID: $targetUuid...');
      // Inicia o scan amplo sem filtro GATT, pois beacons usam Manufacturer Data
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        continuousUpdates: true,
      );

      // Ouve os resultados do scan (ScanResult)
      await for (final results in FlutterBluePlus.scanResults) {
        for (final result in results) {
          // Checa se o Manufacturer Data bate com o iBeacon do alvo
          if (_isTargetBeacon(result, targetUuid)) {
            // Extrai o RSSI e calcula a distância
            double distance = _calculateDistance(result.rssi);
            print('Professor encontrado! RSSI=${result.rssi}, Distância=$distance metros');
            yield distance;
          }
        }
      }
    } catch (e) {
      print('Erro durante scanForProfessor: $e');
      rethrow;
    }
  }

  /// Para o scan manualmente
  Future<void> stopScanning() async {
    try {
      print('Parando o scan...');
      await FlutterBluePlus.stopScan();
      print('Scan parado com sucesso.');
    } catch (e) {
      print('Erro ao parar o scan: $e');
    }
  }
}
