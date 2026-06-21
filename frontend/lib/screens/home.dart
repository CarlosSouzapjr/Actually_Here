import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/class_service.dart';
import '../models/class_model.dart';
import 'class.dart';
import 'login.dart';
import 'create_class_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ClassService _classService = ClassService();
  late Future<List<ClassModel>> _classesFuture;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  void _loadClasses() {
    final user = context.read<AuthService>().currentUser;
    if (user != null) {
      _classesFuture = _classService.fetchClasses(user.id);
    } else {
      _classesFuture = Future.value([]);
    }
  }

  void _showEnrollDialog() {
    final TextEditingController classIdController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Entrar em Turma'),
              content: TextField(
                controller: classIdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'ID da Turma',
                  hintText: 'Ex: 123',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final input = classIdController.text.trim();
                          if (input.isEmpty) return;
                          
                          final classId = int.tryParse(input);
                          if (classId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('ID inválido')),
                            );
                            return;
                          }

                          setStateDialog(() => isSubmitting = true);
                          
                          final user = context.read<AuthService>().currentUser;
                          if (user != null) {
                            final success = await _classService.enrollStudent(classId, user.id);
                            if (success) {
                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Matriculado com sucesso!')),
                                );
                                setState(() {
                                  _loadClasses();
                                });
                              }
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Erro ao matricular. Turma já cadastrada ou não existe.')),
                                );
                              }
                              setStateDialog(() => isSubmitting = false);
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Entrar'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Turmas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _loadClasses();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthService>().logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Olá, ${user?.nome ?? ''}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ClassModel>>(
              future: _classesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Nenhuma turma encontrada.'));
                }

                final turmas = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: turmas.length,
                  itemBuilder: (context, index) {
                    final turma = turmas[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text('${turma.name} (ID: ${turma.id})'),
                        subtitle: Text('${turma.subjectCode} - ${turma.professor ?? 'Sem Professor'}'),
                        leading: const CircleAvatar(child: Icon(Icons.class_)),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ClassScreen(
                                turmaId: turma.id,
                                nomeTurma: turma.name,
                                professor: turma.professor ?? 'Sem Professor',
                                professorId: turma.professorId,
                                beaconUuid: turma.beaconUuid,
                              ),
                            ),
                          );
                          // Refresh after returning (in case a class was deleted/modified)
                          setState(() {
                            _loadClasses();
                          });
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'enrollBtn',
            onPressed: _showEnrollDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('Entrar em Turma'),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'createBtn',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateClassScreen()),
              );
              // Refresh classes after returning from create screen
              setState(() {
                _loadClasses();
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Criar Turma'),
          ),
        ],
      ),
    );
  }
}
