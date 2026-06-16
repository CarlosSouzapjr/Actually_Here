import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/server_config.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  // Login simulado (MOCK)
  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));

    final cleanEmail = email.trim();
    if (cleanEmail.isNotEmpty) {
      final Map<String, dynamic>? backendUser;
      try {
        backendUser = await _syncBackendUser(cleanEmail);
      } catch (_) {
        return false;
      }

      _currentUser = UserModel(
        id: 'user_123', // Usamos um ID fixo para testar as duas visões
        backendId: backendUser?['id'] as int?,
        email: cleanEmail,
        nome: cleanEmail.split('@').first.toUpperCase(),
      );
      notifyListeners();
      return true;
    }

    return false; // Falha
  }

  Future<Map<String, dynamic>?> _syncBackendUser(String email) async {
    final usersUrl = ServerConfig.current.apiUrl('users');
    final response = await http.get(Uri.parse(usersUrl));

    if (response.statusCode == 200) {
      final users = jsonDecode(response.body) as List<dynamic>;
      for (final user in users) {
        final map = user as Map<String, dynamic>;
        if (map['email'] == email) return map;
      }
    }

    final createResponse = await http.post(
      Uri.parse(usersUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': email.split('@').first.toUpperCase(),
        'email': email,
        'authId': 'mock:$email',
      }),
    );

    if (createResponse.statusCode == 201) {
      return jsonDecode(createResponse.body) as Map<String, dynamic>;
    }

    throw Exception('Falha ao sincronizar usuário: ${createResponse.body}');
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
