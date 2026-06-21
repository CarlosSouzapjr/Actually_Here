import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/server_config.dart';
import '../models/class_model.dart';

class ClassService {
  String get baseUrl => ServerConfig.current.apiUrl('classes');

  Future<List<ClassModel>> fetchClasses(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/user/$userId'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ClassModel.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        print('Erro ao buscar turmas: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Erro de conexão ao buscar turmas: $e');
      return [];
    }
  }

  Future<List<ClassModel>> fetchClassesByProfessor(int professorId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/professor/$professorId'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ClassModel.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        print('Erro ao buscar turmas do professor: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Erro de conexão ao buscar turmas do professor: $e');
      return [];
    }
  }

  Future<bool> enrollStudent(int classId, int studentId) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/$classId/enroll/$studentId'));
      if (response.statusCode == 201) {
        return true;
      } else {
        print('Erro ao matricular: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Erro de conexão ao matricular na turma: $e');
      return false;
    }
  }
}
