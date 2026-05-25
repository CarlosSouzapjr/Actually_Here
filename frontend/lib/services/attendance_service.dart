import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AttendanceService {
  // Busca o IP e porta do arquivo .env
  final String baseUrl = 'http://${dotenv.env['SERVER_IP']}:${dotenv.env['API_PORT']}/api/attendance';

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
