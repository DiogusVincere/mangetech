class Responsavel {
  final String id;
  final String nome;
  final String? avatar;
  final String role;

  Responsavel({
    required this.id,
    required this.nome,
    this.avatar,
    required this.role,
  });

  factory Responsavel.fromJson(Map<String, dynamic> json) {
    return Responsavel(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      avatar: json['avatar'],
      role: json['role'] ?? '',
    );
  }
}