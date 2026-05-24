import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/proximity/professor_beacon_service.dart';
import '../services/proximity/student_scanner_service.dart';

class ClassScreen extends StatefulWidget {
  final String turmaId;
  final String nomeTurma;
  final String professor;
  final String professorId;
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
  
  bool _isScanning = false;
  String _statusAluno = '';

  @override
  void dispose() {
    _beaconService.stopBroadcasting();
    _scannerService.stopScanning();
    super.dispose();
  }

  void _iniciarChamadaProfessor() async {
    try {
      context.read<DatabaseService>().iniciarChamada(widget.turmaId);
      await _beaconService.startBroadcasting(widget.beaconUuid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chamada iniciada!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  void _pararChamadaProfessor() {
    context.read<DatabaseService>().pararChamada(widget.turmaId);
    _beaconService.stopBroadcasting();
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
        context.read<DatabaseService>().registrarPresenca(user?.nome ?? 'Aluno Desconhecido');
        
        setState(() {
          _isScanning = false;
          _statusAluno = 'Presença confirmada! Distância: ${distance.toStringAsFixed(2)}m';
        });
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
    final isProfessor = user?.id == widget.professorId;
    final db = context.watch<DatabaseService>();

    return Scaffold(
      appBar: AppBar(title: Text(widget.nomeTurma)),
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
              
              if (db.isChamadaAtiva) ...[
                const Text('Chamada em andamento...', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Alunos presentes: ${db.alunosPresentes.length}'),
                Expanded(
                  child: ListView.builder(
                    itemCount: db.alunosPresentes.length,
                    itemBuilder: (context, i) {
                      return ListTile(
                        leading: const Icon(Icons.check_circle, color: Colors.green),
                        title: Text(db.alunosPresentes[i]),
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
              
              if (db.alunosPresentes.contains(user?.nome)) ...[
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