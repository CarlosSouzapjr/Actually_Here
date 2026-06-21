class ClassModel {
  final int id;
  final String name;
  final String subjectCode;
  
  // O backend não retorna esses campos atualmente, então no ClassService
  // nós os popularemos para manter a compatibilidade com a UI antiga
  final String? professor;
  final int? professorId;

  ClassModel({
    required this.id,
    required this.name,
    required this.subjectCode,
    this.professor,
    this.professorId,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'] as int,
      name: json['name'] as String,
      subjectCode: json['subjectCode'] as String,
    );
  }

  // Gera um beaconUuid determinístico (mesmo ID da turma gera o mesmo UUID)
  // UUID format: 00000000-0000-0000-0000-000000000000
  String get beaconUuid {
    final hexId = id.toRadixString(16).padLeft(12, '0');
    return '00000000-0000-0000-0000-$hexId';
  }
}
