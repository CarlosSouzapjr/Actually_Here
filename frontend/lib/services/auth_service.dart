import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/server_config.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));

    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) return false;

    final backendUser = await _findBackendUserByEmail(cleanEmail);
    if (backendUser == null) return false;

    _currentUser = _toUserModel(backendUser);
    notifyListeners();
    return true;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim();
    if (cleanName.isEmpty || cleanEmail.isEmpty) return false;

    final existingUser = await _findBackendUserByEmail(cleanEmail);
    if (existingUser != null) return false;

    final usersUrl = ServerConfig.current.apiUrl('users');
    final createResponse = await http.post(
      Uri.parse(usersUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': cleanName,
        'email': cleanEmail,
        'authId': 'mock:$cleanEmail',
      }),
    );

    if (createResponse.statusCode != 201) return false;

    _currentUser = _toUserModel(
      jsonDecode(createResponse.body) as Map<String, dynamic>,
    );
    notifyListeners();
    return true;
  }

  Future<Map<String, dynamic>?> _findBackendUserByEmail(String email) async {
    final usersUrl = ServerConfig.current.apiUrl('users');
    final response = await http.get(Uri.parse(usersUrl));

    if (response.statusCode != 200) return null;

    final users = jsonDecode(response.body) as List<dynamic>;
    for (final user in users) {
      final map = user as Map<String, dynamic>;
      if (map['email'] == email) return map;
    }

    return null;
  }

  UserModel _toUserModel(Map<String, dynamic> backendUser) {
    final email = backendUser['email'] as String;
    return UserModel(
      id: 'user_${backendUser['id']}',
      backendId: backendUser['id'] as int?,
      email: email,
      nome: backendUser['name'] as String? ?? email.split('@').first,
    );
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
