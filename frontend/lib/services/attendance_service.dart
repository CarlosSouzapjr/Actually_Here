import 'dart:convert';
import 'package:http/http.dart' as http;

class AttendanceService {
  // Ajuste o IP conforme necessário (10.0.2.2 para emulador Android)
  final String baseUrl = 'http://localhost:8080/api/attendance';

  Future<Map<String, dynamic>?> startSession(int classId) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/start/$classId'));
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        print('Erro ao iniciar sessão: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Erro de conexão ao iniciar sessão: $e');
      return null;
    }
  }

  Future<bool> endSession(int sessionId) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/end/$sessionId'));
      return response.statusCode == 200;
    } catch (e) {
      print('Erro de conexão ao encerrar sessão: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getActiveSession(int classId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/active/$classId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Erro de conexão ao buscar sessão ativa: $e');
      return null;
    }
  }
}
