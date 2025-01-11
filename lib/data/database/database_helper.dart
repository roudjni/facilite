import 'dart:async';
import 'package:bcrypt/bcrypt.dart';
import 'package:facilite/data/database/migrations.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:facilite/data/models/usuario.dart';
import 'package:facilite/data/models/simulacao.dart';
import 'package:facilite/data/models/emprestimo.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'facilite.db');
    return await openDatabase(
      path,
      version: 11,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usuarios (
        id INTEGER PRIMARY KEY,
        usuario TEXT NOT NULL,
        senha TEXT NOT NULL,
        pergunta_seguranca TEXT,
        resposta_seguranca TEXT
      )
    ''');

    final hashAdmin = BCrypt.hashpw('1234', BCrypt.gensalt());

    await db.insert('usuarios', {
      'usuario': 'admin',
      'senha': hashAdmin,
      'pergunta_seguranca': 'Ano de fundação do Corinthians?',
      'resposta_seguranca': '1910',
    });

    await db.execute('''
      CREATE TABLE simulacoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        valor REAL NOT NULL,
        parcelas INTEGER NOT NULL,
        juros REAL NOT NULL,
        data TEXT NOT NULL,
        tipo_parcela TEXT NOT NULL,
        parcelas_detalhes TEXT,
        data_vencimento TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE emprestimos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        valor REAL NOT NULL,
        parcelas INTEGER NOT NULL,
        juros REAL NOT NULL,
        data TEXT NOT NULL,
        tipo_parcela TEXT NOT NULL,
        cpf_cnpj TEXT NOT NULL,
        whatsapp TEXT NOT NULL,
        email TEXT,
        endereco TEXT,
        parcelas_detalhes TEXT,
        data_vencimento TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS financeiro (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        saldo_disponivel REAL NOT NULL DEFAULT 0
      )
  ''');

    // Inicializar com saldo padrão caso necessário
    await db.insert('financeiro', {'saldo_disponivel': 0});

    await db.execute('''
      CREATE TABLE financeiro_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT NOT NULL, -- "adicao" ou "retirada"
        valor REAL NOT NULL,
        usuario TEXT NOT NULL,
        data_hora TEXT NOT NULL -- ISO 8601 format
      )
  ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await DatabaseMigrations.migrate(db, oldVersion, newVersion);
  }

  Future<List<Map<String, dynamic>>> query(String table,
      {String? where, List<dynamic>? whereArgs, int? limit, String? orderBy}) async {
    Database db = await instance.database;
    return await db.query(table, where: where, whereArgs: whereArgs, limit: limit, orderBy: orderBy);
  }

  Future<int> insert(String table, Map<String, dynamic> values) async {
    Database db = await instance.database;
    return await db.insert(table, values);
  }

  Future<int> update(String table, Map<String, dynamic> values,
      {String? where, List<dynamic>? whereArgs}) async {
    Database db = await instance.database;
    return await db.update(table, values, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(String table, {String? where, List<dynamic>? whereArgs}) async {
    Database db = await instance.database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<Usuario?> getUsuario(String usuario) async {
    final result = await query('usuarios', where: 'usuario = ?', whereArgs: [usuario]);
    return result.isNotEmpty ? Usuario.fromMap(result.first) : null;
  }

  Future<int> addUsuario(String usuario, String senhaHasheada) async {
    return await insert('usuarios', {
      'usuario': usuario,
      'senha': senhaHasheada,
    });
  }

  Future<bool> verificarAdmin() async {
    final result = await query('usuarios', where: 'usuario = ?', whereArgs: ['admin']);
    return result.isNotEmpty;
  }

  Future<int> updateSenha(String usuario, String senhaHasheada) async {
    return await update(
      'usuarios',
      {'senha': senhaHasheada},
      where: 'usuario = ?',
      whereArgs: [usuario],
    );
  }

  Future<int> updateNomeUsuario(String oldUser, String newUser) async {
    return await update(
      'usuarios',
      {'usuario': newUser},
      where: 'usuario = ?',
      whereArgs: [oldUser],
    );
  }

  Future<int> updatePerguntaResposta(String usuario, String novaPergunta, String novaResposta) async {
    return await update(
      'usuarios',
      {
        'pergunta_seguranca': novaPergunta,
        'resposta_seguranca': novaResposta,
      },
      where: 'usuario = ?',
      whereArgs: [usuario],
    );
  }

  Future<int> criarSimulacao(Simulacao simulacao) async {
    return await insert('simulacoes', simulacao.toMap());
  }

  Future<List<Simulacao>> getAllSimulacoes() async {
    final List<Map<String, dynamic>> maps = await query('simulacoes');
    return List.generate(maps.length, (i) {
      return Simulacao.fromMap(maps[i]);
    });
  }

  Future<int> criarEmprestimo(Emprestimo emprestimo) async {
    return await insert('emprestimos', emprestimo.toMap());
  }

  Future<List<Emprestimo>> getAllEmprestimos({int? limit}) async {
    final List<Map<String, dynamic>> maps = await query('emprestimos', limit: limit, orderBy: 'data DESC');
    return List.generate(maps.length, (i) {
      return Emprestimo.fromMap(maps[i]);
    });
  }

  Future<Emprestimo?> getEmprestimoById(int id) async {
    final List<Map<String, dynamic>> maps = await query('emprestimos', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? Emprestimo.fromMap(maps.first) : null;
  }

  Future<int> updateEmprestimo(Emprestimo emprestimo) async {
    final db = await instance.database;
    return await db.update(
      'emprestimos',
      emprestimo.toMap(),
      where: 'id = ?',
      whereArgs: [emprestimo.id],
    );
  }

  Future<int> deleteEmprestimo(int id) async {
    return await delete('emprestimos', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateSimulacao(Simulacao simulacao) async {
    return await update('simulacoes', simulacao.toMap(), where: 'id = ?', whereArgs: [simulacao.id]);
  }

  Future<int> deleteSimulacao(int id) async {
    return await delete('simulacoes', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getSaldoDisponivel() async {
    Database db = await instance.database;
    final result = await db.query('financeiro', limit: 1);
    if (result.isNotEmpty) {
      return result.first['saldo_disponivel'] as double;
    }
    return 0.0;
  }

  Future<void> updateSaldoDisponivel(double saldo) async {
    Database db = await instance.database;
    await db.update('financeiro', {'saldo_disponivel': saldo}, where: 'id = ?', whereArgs: [1]);
  }

  Future<void> adicionarLogFinanceiro(String tipo, double valor, String usuario, {String? descricao}) async {
    Database db = await instance.database;
    await db.insert('financeiro_logs', {
      'tipo': tipo,
      'valor': valor,
      'usuario': usuario,
      'data_hora': DateTime.now().toIso8601String(),
      'descricao' : descricao,
    });
  }

  Future<List<Map<String, dynamic>>> getLogsFinanceiros() async {
    Database db = await instance.database;
    return await db.query('financeiro_logs', orderBy: 'data_hora DESC');
  }

}