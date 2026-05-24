import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  // Login simulado (MOCK)
  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); 
    
    if (email.isNotEmpty) {
      _currentUser = UserModel(
        id: 'user_123', // Usamos um ID fixo para testar as duas visões
        email: email, 
        nome: email.split('@').first.toUpperCase(), 
      );
      notifyListeners();
      return true;
    }
    
    return false; // Falha
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
