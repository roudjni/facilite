// lib/data/services/simulacao_service.dart

import 'package:facilite/data/services/base_service.dart';
import 'package:facilite/data/models/simulacao.dart';

class SimulacaoService extends BaseService {
  Future<List<Simulacao>> getAllSimulacoes() async {
    return await databaseHelper.getAllSimulacoes();
  }
}