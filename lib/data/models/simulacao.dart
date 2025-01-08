// lib/data/models/simulacao.dart
import 'dart:convert';

class Simulacao {
  int? id;
  String nome;
  double valor;
  int parcelas;
  double juros;
  DateTime data;
  String tipoParcela;
  List<Map<String, dynamic>> parcelasDetalhes;
  DateTime? dataVencimento;

  Simulacao({
    this.id,
    required this.nome,
    required this.valor,
    required this.parcelas,
    required this.juros,
    required this.data,
    required this.tipoParcela,
    required this.parcelasDetalhes,
    this.dataVencimento,
  });



  factory Simulacao.fromMap(Map<String, dynamic> map) {

    return Simulacao(
      id: map['id'],
      nome: map['nome'],
      valor: map['valor'],
      parcelas: map['parcelas'],
      juros: map['juros'],
      data: DateTime.parse(map['data']),
      tipoParcela: map['tipo_parcela'],
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
      'parcelas_detalhes': json.encode(parcelasDetalhes),
      'data_vencimento': dataVencimento?.toIso8601String(),
    };
  }
}
