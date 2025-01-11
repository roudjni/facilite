import 'package:sqflite/sqflite.dart';

class DatabaseMigrations {
  static Future<void> migrate(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _migrationV2(db);
    }
    if (oldVersion < 3) {
      await _migrationV3(db);
    }
    if (oldVersion < 4) {
      await _migrationV4(db);
    }
    if (oldVersion < 5) {
      await _migrationV5(db);
    }
    if (oldVersion < 6) {
      await _migrationV6(db);
    }
    if (oldVersion < 7) {
      // await _migrationV7(db);
    }
    if (oldVersion < 8) {
      await _migrationV8(db);
    }
    if (oldVersion < 9) {
      await _migrationV9(db);
    }
    if (oldVersion < 10) {
      await _migrationV10(db);
    }
    if (oldVersion < 11) {
      await _migrationV11(db);
    }
  }
  static Future<void> _migrationV11(Database db) async {
    await db.execute('''
        ALTER TABLE financeiro_logs
        ADD COLUMN descricao TEXT;
        ''');
  }
  static Future<void> _migrationV2(Database db) async {
    await db.execute('''
      CREATE TABLE simulacoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        valor REAL NOT NULL,
        parcelas INTEGER NOT NULL,
        juros REAL NOT NULL,
        data TEXT NOT NULL,
        tipo_parcela TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _migrationV3(Database db) async {
    await db.execute('''
        ALTER TABLE simulacoes
        ADD COLUMN parcelas_detalhes TEXT;
      ''');
  }

  static Future<void> _migrationV4(Database db) async {
    await db.execute('''
        ALTER TABLE simulacoes
        ADD COLUMN dia_vencimento INTEGER;
      ''');
  }

  static Future<void> _migrationV5(Database db) async {
    await db.execute('''
        ALTER TABLE simulacoes
        ADD COLUMN data_vencimento TEXT;
      ''');
  }
  static Future<void> _migrationV6(Database db) async {
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
  }
  static Future<void> _migrationV8(Database db) async {
    // Adicionando pergunta e resposta, se não existirem
    await db.execute('''
        ALTER TABLE usuarios
        ADD COLUMN pergunta_seguranca TEXT;
      ''');
    await db.execute('''
        ALTER TABLE usuarios
        ADD COLUMN resposta_seguranca TEXT;
      ''');
  }
  static Future<void> _migrationV9(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS financeiro (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        saldo_disponivel REAL NOT NULL DEFAULT 0
      )
  ''');

    // Inicializar com saldo padrão caso necessário
    await db.insert('financeiro', {'saldo_disponivel': 0});
  }
  static Future<void> _migrationV10(Database db) async {
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


}