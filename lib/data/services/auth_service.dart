import 'package:bcrypt/bcrypt.dart';
import 'package:emprestafacil/data/services/base_service.dart';
import 'package:emprestafacil/data/models/usuario.dart';

class AuthService extends BaseService {
  String _hashSenha(String senha) {
    return BCrypt.hashpw(senha, BCrypt.gensalt());
  }

  bool _verificarSenha(String senhaPura, String senhaHasheada) {
    return BCrypt.checkpw(senhaPura, senhaHasheada);
  }

  // ---------------------------
  // MÉTODOS DE AUTENTICAÇÃO
  // ---------------------------
  Future<Usuario?> autenticar(String usuario, String senha) async { // Retorna Usuario?
    final userRow = await databaseHelper.getUsuario(usuario);
    if (userRow == null) return null;

    final senhaValida = _verificarSenha(senha, userRow.senha); // Acessa a senha diretamente
    if (!senhaValida) {
      return null;
    }
    return userRow; // Retorna o objeto Usuario
  }

  Future<int> addUsuario(String usuario, String senha) async {
    final hash = _hashSenha(senha);
    return await databaseHelper.addUsuario(usuario, hash);
  }

  Future<bool> verificarAdmin() async {
    return await databaseHelper.verificarAdmin();
  }

  // ---------------------------
  // MÉTODOS DE ATUALIZAÇÃO
  // ---------------------------

  /// Altera apenas o nome de usuário
  Future<void> alterarNomeUsuario(String oldUser, String newUser) async {
    final res = await databaseHelper.updateNomeUsuario(oldUser, newUser);
    if (res == 0) {
      throw Exception('Usuário não encontrado ou falha ao atualizar.');
    }
  }

  /// Altera apenas a senha (usando bcrypt)
  Future<void> alterarSenhaUsuario(String usuario, String novaSenha) async {
    final novoHash = _hashSenha(novaSenha);
    final res = await databaseHelper.updateSenha(usuario, novoHash);
    if (res == 0) {
      throw Exception('Usuário não encontrado ou falha ao atualizar a senha.');
    }
  }

  /// Altera pergunta e resposta
  Future<void> alterarPerguntaResposta(
      String usuario,
      String novaPergunta,
      String novaResposta,
      ) async {
    final res = await databaseHelper.updatePerguntaResposta(
      usuario,
      novaPergunta,
      novaResposta,
    );
    if (res == 0) {
      throw Exception('Usuário não encontrado ou falha ao atualizar pergunta/resposta.');
    }
  }
}
