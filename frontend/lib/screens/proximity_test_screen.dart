import 'dart:async';
import 'package:flutter/material.dart';
import '../services/proximity/professor_beacon_service.dart';
import '../services/proximity/student_scanner_service.dart';
import '../services/mqtt_service.dart';
import '../services/attendance_service.dart';

class ProximityTestScreen extends StatefulWidget {
  const ProximityTestScreen({super.key});

  @override
  State<ProximityTestScreen> createState() => _ProximityTestScreenState();
}

class _ProximityTestScreenState extends State<ProximityTestScreen> {
  final ProfessorBeaconService _beaconService = ProfessorBeaconService();
  final StudentScannerService _scannerService = StudentScannerService();
  final MqttService _mqttService = MqttService();
  final AttendanceService _attendanceService = AttendanceService();

  final String testUuid = '39ED98FF-2900-441A-802F-9C398FC199D2';
  final int testClassId = 1; // ID de teste da turma
  int? _currentSessionId;
  
  String _status = 'Aguardando...';
  StreamSubscription<double>? _scanSubscription;

  void _updateStatus(String newStatus) {
    setState(() {
      _status = newStatus;
    });
  }

  Future<void> _startProfessor() async {
    _updateStatus('Iniciando sessão no servidor...');
    try {
      final session = await _attendanceService.startSession(testClassId);
      if (session != null) {
        _currentSessionId = session['id'];
        _updateStatus('Sessão ${session['id']} iniciada. Ligando Beacon...');
        await _beaconService.startBroadcasting(testUuid);
        _updateStatus('Transmitindo... (Professor)\nSessão ID: $_currentSessionId');
      } else {
        _updateStatus('Erro ao iniciar sessão no backend.');
      }
    } catch (e) {
      _updateStatus('Erro: $e');
    }
  }

  Future<void> _startStudent() async {
    _updateStatus('Verificando se há aula ativa...');
    try {
      final session = await _attendanceService.getActiveSession(testClassId);
      if (session == null) {
        _updateStatus('Não há sessão ativa para esta turma no momento.');
        return;
      }

      _updateStatus('Sessão ativa encontrada! Conectando MQTT...');
      bool connected = await _mqttService.connect();
      if (!connected) {
        _updateStatus('Erro ao conectar ao MQTT. Verifique o broker.');
        return;
      }

      _scanSubscription?.cancel();
      
      _scanSubscription = _scannerService.scanForProfessor(testUuid).listen(
        (distance) {
          if (distance >= 0) {
            _updateStatus('Professor encontrado a ${distance.toStringAsFixed(2)} metros');
            _mqttService.publishPresence(testClassId, 123, distance);
          } else {
            _updateStatus('Sinal encontrado, mas RSSI inválido.');
          }
        }, 
        onError: (error) {
          _updateStatus('Erro no scan: $error');
        }
      );

      _updateStatus('Escaneando e enviando pings...');
    } catch (e) {
      _updateStatus('Erro ao iniciar scan: $e');
    }
  }

  Future<void> _stopAll() async {
    _updateStatus('Parando serviços...');
    
    // Para professor: Encerra a sessão no backend se houver uma
    if (_currentSessionId != null) {
      await _attendanceService.endSession(_currentSessionId!);
      _currentSessionId = null;
    }

    await _beaconService.stopBroadcasting();
    
    // Para aluno
    _scanSubscription?.cancel();
    await _scannerService.stopScanning();
    _mqttService.disconnect();

    _updateStatus('Parado. Sessão encerrada.');
  }

  @override
  void dispose() {
    // Garantir que os recursos são libertados ao fechar a tela
    _stopAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste de Presença'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Status Atual:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _status,
                  style: const TextStyle(fontSize: 16, color: Colors.blueAccent),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: _startProfessor,
                icon: const Icon(Icons.cast),
                label: const Text('Sou Professor (Iniciar Aula)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _startStudent,
                icon: const Icon(Icons.radar),
                label: const Text('Sou Aluno (Marcar Presença)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _stopAll,
                icon: const Icon(Icons.stop),
                label: const Text('Parar tudo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
