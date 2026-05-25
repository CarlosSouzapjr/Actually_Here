import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'class.dart';
import 'login.dart';
import 'create_class_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final turmas = context.watch<DatabaseService>().turmas;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Turmas'),
        actions: [
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
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: turmas.length,
              itemBuilder: (context, index) {
                final turma = turmas[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(turma['nome']),
                    subtitle: Text(turma['professor']),
                    leading: const CircleAvatar(child: Icon(Icons.class_)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ClassScreen(
                            turmaId: turma['id'],
                            nomeTurma: turma['nome'],
                            professor: turma['professor'],
                            professorId: turma['professorId'],
                            beaconUuid: turma['beaconUuid'],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateClassScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
