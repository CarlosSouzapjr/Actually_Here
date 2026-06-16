class UserModel {
  final String id;
  final int? backendId;
  final String email;
  final String nome;

  UserModel({
    required this.id,
    this.backendId,
    required this.email,
    required this.nome,
  });
}
