// lib/data/models/usuario.dart
class Usuario {
  int id;
  String usuario;
  String senha;
  String? perguntaSeguranca;
  String? respostaSeguranca;

  Usuario({
    required this.id,
    required this.usuario,
    required this.senha,
    this.perguntaSeguranca,
    this.respostaSeguranca,
  });

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'],
      usuario: map['usuario'],
      senha: map['senha'],
      perguntaSeguranca: map['pergunta_seguranca'],
      respostaSeguranca: map['resposta_seguranca'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario': usuario,
      'senha': senha,
      'pergunta_seguranca': perguntaSeguranca,
      'resposta_seguranca': respostaSeguranca,
    };
  }
}