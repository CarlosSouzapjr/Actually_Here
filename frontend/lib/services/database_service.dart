import 'package:flutter/material.dart';

class DatabaseService extends ChangeNotifier {
  final List<Map<String, dynamic>> turmas = [
    {
      'id': 't1', 
      'nome': 'Sistemas Distribuídos', 
      'professor': 'Você (Professor)', 
      'professorId': 'user_123', 
      'beaconUuid': '39ED98FF-2900-441A-802F-9C398FC199D2'
    },
    {
      'id': 't2', 
      'nome': 'Cálculo II', 
      'professor': 'Prof. Einstein', 
      'professorId': 'user_999', 
      'beaconUuid': '12345678-1234-1234-1234-123456789012'
    },
  ];

  // Estado local para simular a chamada em andamento
  List<String> alunosPresentes = [];
  bool isChamadaAtiva = false;

  void iniciarChamada(String turmaId) {
    isChamadaAtiva = true;
    alunosPresentes.clear();
    notifyListeners();
  }

  void pararChamada(String turmaId) {
    isChamadaAtiva = false;
    notifyListeners();
  }

  void registrarPresenca(String alunoNome) {
    if (!alunosPresentes.contains(alunoNome)) {
      alunosPresentes.add(alunoNome);
      notifyListeners();
    }
  }
}
