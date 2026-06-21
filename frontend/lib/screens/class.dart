import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/attendance_service.dart';
import '../services/mqtt_service.dart';
import '../services/proximity/professor_beacon_service.dart';
import '../services/proximity/student_scanner_service.dart';
import 'proximity_test_screen.dart';

class ClassScreen extends StatefulWidget {
  final int turmaId;
  final String nomeTurma;
  final String professor;
  final int? professorId;
  final String beaconUuid;

  const ClassScreen({
    super.key,
    required this.turmaId,
    required this.nomeTurma,
    required this.professor,
    required this.professorId,
    required this.beaconUuid,
  });

  @override
  State<ClassScreen> createState() => _ClassScreenState();
}

class _ClassScreenState extends State<ClassScreen> {
  final ProfessorBeaconService _beaconService = ProfessorBeaconService();
  final StudentScannerService _scannerService = StudentScannerService();
  final AttendanceService _attendanceService = AttendanceService();
  final MqttService _mqttService = MqttService();
  
  bool _isScanning = false;
  String _statusAluno = '';

  bool _isChamadaAtiva = false;
  int? _activeSessionId;
  final List<String> _alunosPresentes = [];

  @override
  void initState() {
    super.initState();
    _mqttService.connect();
    _checkActiveSession();
  }

  Future<void> _checkActiveSession() async {
    final sessionData = await _attendanceService.getActiveSession(widget.turmaId);
    if (sessionData != null && mounted) {
      setState(() {
        _isChamadaAtiva = true;
        _activeSessionId = sessionData['id'];
      });
      // Verifica se é o professor e escuta o MQTT
      final user = context.read<AuthService>().currentUser;
      final isProfessor = user?.backendId == widget.professorId && widget.professorId != null;
      if (isProfessor) {
        _startListeningToMqtt();
      }
    }
  }

  void _startListeningToMqtt() {
    _mqttService.subscribeToClass(widget.turmaId, (studentId, distance) {
      // Como não temos a rota para buscar o nome do aluno ainda, mockamos visualmente o nome.
      final studentName = 'Aluno ID: $studentId';
      if (!_alunosPresentes.contains(studentName) && mounted) {
        setState(() {
          _alunosPresentes.add(studentName);
        });
      }
    });
  }

  @override
  void dispose() {
    _beaconService.stopBroadcasting();
    _scannerService.stopScanning();
    _mqttService.unsubscribeFromClass(widget.turmaId);
    _mqttService.disconnect();
    super.dispose();
  }

  void _iniciarChamadaProfessor() async {
    try {
      final sessionData = await _attendanceService.startSession(widget.turmaId);
      if (sessionData != null) {
        setState(() {
          _isChamadaAtiva = true;
          _activeSessionId = sessionData['id'];
          _alunosPresentes.clear();
        });
        await _beaconService.startBroadcasting(widget.beaconUuid);
        _startListeningToMqtt();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chamada iniciada!')));
        }
      } else {
        throw Exception('Falha ao iniciar sessão no backend.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  void _pararChamadaProfessor() async {
    if (_activeSessionId != null) {
      await _attendanceService.endSession(_activeSessionId!);
    }
    setState(() {
      _isChamadaAtiva = false;
      _activeSessionId = null;
    });
    _beaconService.stopBroadcasting();
    _mqttService.unsubscribeFromClass(widget.turmaId);
  }

  void _marcarPresencaAluno() {
    setState(() {
      _isScanning = true;
      _statusAluno = 'Procurando professor na sala...';
    });

    _scannerService.scanForProfessor(widget.beaconUuid).listen((distance) {
      if (distance >= 0 && distance < 10.0) { // 10 metros de tolerância
        _scannerService.stopScanning();
        final user = context.read<AuthService>().currentUser;
        
        if (user != null && user.backendId != null) {
          _mqttService.publishPresence(widget.turmaId, user.backendId!, distance);
          setState(() {
            _isScanning = false;
            _statusAluno = 'Presença confirmada! Distância: ${distance.toStringAsFixed(2)}m';
          });
        } else {
          setState(() {
            _isScanning = false;
            _statusAluno = 'Erro: Usuário não sincronizado no backend.';
          });
        }
      }
    }, onError: (e) {
      setState(() {
        _isScanning = false;
        _statusAluno = 'Erro: $e';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final isProfessor = user?.backendId == widget.professorId && widget.professorId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nomeTurma),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth),
            tooltip: 'Testar Proximidade',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProximityTestScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.professor, style: const TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 24),
            
            if (isProfessor) ...[
              const Text('Painel do Professor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              if (_isChamadaAtiva) ...[
                const Text('Chamada em andamento...', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Alunos presentes: ${_alunosPresentes.length}'),
                Expanded(
                  child: ListView.builder(
                    itemCount: _alunosPresentes.length,
                    itemBuilder: (context, i) {
                      return ListTile(
                        leading: const Icon(Icons.check_circle, color: Colors.green),
                        title: Text(_alunosPresentes[i]),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _pararChamadaProfessor,
                    icon: const Icon(Icons.stop), label: const Text('Encerrar Chamada'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  ),
                ),
              ] else ...[
                const Spacer(),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _iniciarChamadaProfessor,
                    icon: const Icon(Icons.play_arrow), label: const Text('Iniciar Chamada'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  ),
                ),
              ]
            ] else ...[
              const Text('Painel do Aluno', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              if (_statusAluno.contains('confirmada')) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 32),
                      const SizedBox(width: 16),
                      Expanded(child: Text(_statusAluno, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                    ],
                  ),
                )
              ] else ...[
                Text(_statusAluno, style: const TextStyle(color: Colors.blue)),
                const Spacer(),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isScanning ? null : _marcarPresencaAluno,
                    icon: _isScanning ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.bluetooth),
                    label: Text(_isScanning ? 'Procurando...' : 'Marcar Presença'),
                  ),
                ),
              ]
            ],
          ],
        ),
      ),
    );
  }
}