// lib/data/services/simulacao_service.dart

import 'package:emprestafacil/data/services/base_service.dart';
import 'package:emprestafacil/data/models/simulacao.dart';

class SimulacaoService extends BaseService {
  Future<List<Simulacao>> getAllSimulacoes() async {
    return await databaseHelper.getAllSimulacoes();
  }
}