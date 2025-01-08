// lib/data/models/emprestimo.dart
import 'dart:convert';

class Emprestimo {
  int? id;
  String nome;
  double valor;
  int parcelas;
  double juros;
  DateTime data;
  String tipoParcela;
  String cpfCnpj;
  String whatsapp;
  String? email;
  String? endereco;
  List<Map<String, dynamic>> parcelasDetalhes;
  DateTime? dataVencimento;

  Emprestimo({
    this.id,
    required this.nome,
    required this.valor,
    required this.parcelas,
    required this.juros,
    required this.data,
    required this.tipoParcela,
    required this.cpfCnpj,
    required this.whatsapp,
    this.email,
    this.endereco,
    required this.parcelasDetalhes,
    this.dataVencimento,
  });

  factory Emprestimo.fromMap(Map<String, dynamic> map) {
    return Emprestimo(
      id: map['id'],
      nome: map['nome'],
      valor: map['valor'],
      parcelas: map['parcelas'],
      juros: map['juros'],
      data: DateTime.parse(map['data']),
      tipoParcela: map['tipo_parcela'],
      cpfCnpj: map['cpf_cnpj'],
      whatsapp: map['whatsapp'],
      email: map['email'],
      endereco: map['endereco'],
      parcelasDetalhes: List<Map<String, dynamic>>.from(json.decode(map['parcelas_detalhes'])),
      dataVencimento: map['data_vencimento'] != null ? DateTime.parse(map['data_vencimento']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'valor': valor,
      'parcelas': parcelas,
      'juros': juros,
      'data': data.toIso8601String(),
      'tipo_parcela': tipoParcela,
      'cpf_cnpj': cpfCnpj,
      'whatsapp': whatsapp,
      'email': email,
      'endereco': endereco,
      'parcelas_detalhes': json.encode(parcelasDetalhes), // Certifique-se de serializar
      'data_vencimento': dataVencimento?.toIso8601String(),
    };
  }

  Emprestimo copyWith({
    int? id,
    String? nome,
    double? valor,
    int? parcelas,
    double? juros,
    DateTime? data,
    String? tipoParcela,
    String? cpfCnpj,
    String? whatsapp,
    String? email,
    String? endereco,
    List<Map<String, dynamic>>? parcelasDetalhes,
    DateTime? dataVencimento,
  }) {
    return Emprestimo(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      valor: valor ?? this.valor,
      parcelas: parcelas ?? this.parcelas,
      juros: juros ?? this.juros,
      data: data ?? this.data,
      tipoParcela: tipoParcela ?? this.tipoParcela,
      cpfCnpj: cpfCnpj ?? this.cpfCnpj,
      whatsapp: whatsapp ?? this.whatsapp,
      email: email ?? this.email,
      endereco: endereco ?? this.endereco,
      parcelasDetalhes: parcelasDetalhes ?? this.parcelasDetalhes,
      dataVencimento: dataVencimento ?? this.dataVencimento,
    );
  }

}