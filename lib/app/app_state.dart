import 'package:facilite/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:facilite/data/services/simulacao_service.dart';
import 'package:intl/intl.dart';
import 'package:facilite/data/database/database_helper.dart';
import 'package:facilite/data/models/simulacao.dart';
import 'package:facilite/data/models/emprestimo.dart';

class AppState extends ChangeNotifier {
  final SimulacaoService _simulacaoService = SimulacaoService();
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  List<Simulacao> _simulacoes = [];
  List<Emprestimo> _emprestimosRecentes = [];
  bool _isLoading = false;
  String _username = 'Usuário';

  // Propriedades de EmprestimoState (agora em AppState)
  String _nome = '';
  double _valor = 0.0;
  int _parcelas = 0;
  double _juros = 0.0;
  String _tipoParcela = 'Mensais';
  DateTime? _dataVencimento;
  List<Map<String, dynamic>> _parcelasDetalhadas = [];
  double _totalComJuros = 0.0;
  String _origem = '';
  Emprestimo? _currentEmprestimo;

  AppState();

  // Getters e Setters
  String get username => _username;
  List<Simulacao> get simulacoes => _simulacoes;
  List<Emprestimo> get emprestimosRecentes => _emprestimosRecentes;
  bool get isLoading => _isLoading;
  String get nome => _nome;
  double get valor => _valor;
  int get parcelas => _parcelas;
  double get juros => _juros;
  String get tipoParcela => _tipoParcela;
  DateTime? get dataVencimento => _dataVencimento;
  List<Map<String, dynamic>> get parcelasDetalhadas => _parcelasDetalhadas;
  double get totalComJuros => _totalComJuros;
  String get origem => _origem;
  Emprestimo? get currentEmprestimo => _currentEmprestimo;

  // Expor as propriedades privadas como getters
  int get currentPage => _currentPage;
  int get itemsPerPage => _itemsPerPage;


  // Formato de Moeda e Data
  final _numberFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _dateFormat = DateFormat('dd/MM/yyyy');
  NumberFormat get numberFormat => _numberFormat;
  DateFormat get dateFormat => _dateFormat;

  // Novo atributo para controlar o offset e o limite
  int _currentPage = 0;
  final int _itemsPerPage = 12; // Itens por página

  List<Emprestimo> get paginatedEmprestimos {
    int start = _currentPage * _itemsPerPage;
    int end = start + _itemsPerPage;
    end = end > _emprestimosRecentes.length ? _emprestimosRecentes.length : end;
    return _emprestimosRecentes.sublist(start, end);
  }

  DatabaseHelper get databaseHelper => _databaseHelper;

  void nextPage() {
    if ((_currentPage + 1) * _itemsPerPage < _emprestimosRecentes.length) {
      _currentPage++;
      notifyListeners();
    }
  }

  void previousPage() {
    if (_currentPage > 0) {
      _currentPage--;
      notifyListeners();
    }
  }

  void resetPagination() {
    _currentPage = 0;
    notifyListeners();
  }

  // Métodos de gerenciamento de usuário
  void setUsername(String username) {
    _username = username;
    Future.microtask(notifyListeners);
  }

  Future<void> logout() async {
    _username = 'Usuário';
    notifyListeners();
  }

  // Métodos de acesso a dados (serão adaptados para usar Models)
  Future<void> loadSimulacoes() async {
    _isLoading = true;
    Future.microtask(notifyListeners);
    try {
      _simulacoes = await _simulacaoService.getAllSimulacoes();
    } finally {
      _isLoading = false;
      Future.microtask(notifyListeners);
    }
  }

  Future<void> loadRecentEmprestimos() async {
    _isLoading = true;
    Future.microtask(notifyListeners);
    List<Emprestimo> oldEmprestimos = List.from(_emprestimosRecentes);
    try {
      _emprestimosRecentes =
      await _databaseHelper.getAllEmprestimos(limit: AppConstants.defaultLimitRecents);
      print("loadRecentEmprestimos chamado, retornando ${_emprestimosRecentes.length} itens");
    } finally {
      _isLoading = false;
      if (!_listsAreEqualEmprestimo(oldEmprestimos, _emprestimosRecentes)) {
        Future.microtask(notifyListeners);
      }
    }
  }

  Future<void> loadAllEmprestimos() async {
    _isLoading = true;
    Future.microtask(notifyListeners);
    try {
      _emprestimosRecentes = await _databaseHelper.getAllEmprestimos();
      print("loadAllEmprestimos chamado, retornando ${_emprestimosRecentes.length} itens");
      print("Itens na lista _emprestimosRecentes: ${_emprestimosRecentes}");
    } finally {
      _isLoading = false;
      Future.microtask(notifyListeners);
    }
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    Future.microtask(notifyListeners);
  }

  // Métodos de EmprestimoState (agora em AppState)
  void setEmprestimo(Emprestimo? emprestimo) {
    _currentEmprestimo = emprestimo;
    Future.microtask(notifyListeners);
  }

  void clearEmprestimo() {
    _currentEmprestimo = null;
  }

  void setNome(String nome) {
    _nome = nome;
    Future.microtask(notifyListeners);
  }

  void setValor(double valor) {
    _valor = valor;
    Future.microtask(notifyListeners);
  }

  void setParcelas(int parcelas) {
    _parcelas = parcelas;
    Future.microtask(notifyListeners);
  }

  void setJuros(double juros) {
    _juros = juros;
    Future.microtask(notifyListeners);
  }

  void setTipoParcela(String tipoParcela) {
    _tipoParcela = tipoParcela;
    Future.microtask(notifyListeners);
  }

  void setDataVencimento(DateTime dataVencimento) {
    _dataVencimento = dataVencimento;
    Future.microtask(notifyListeners);
  }

  void setParcelasDetalhadas(List<Map<String, dynamic>> parcelasDetalhadas) {
    _parcelasDetalhadas = parcelasDetalhadas;
    Future.microtask(notifyListeners);
  }

  void setTotalComJuros(double totalComJuros) {
    _totalComJuros = totalComJuros;
    Future.microtask(notifyListeners);
  }

  void clearState() {
    _nome = '';
    _valor = 0.0;
    _parcelas = 0;
    _juros = 0.0;
    _tipoParcela = 'Mensais';
    _dataVencimento = null;
    _parcelasDetalhadas = [];
    _totalComJuros = 0.0;
    _origem = '';
    Future.microtask(notifyListeners);
  }

  void setOrigem(String origem) {
    _origem = origem;
    Future.microtask(notifyListeners);
  }

  void calcularSimulacao(String origem) {
    if (_valor == 0 || _parcelas == 0 || _juros == 0) return;

    setOrigem(origem);

    // Calcula o total com juros
    _totalComJuros = _valor * (1 + (_juros / 100));
    double valorParcela = _totalComJuros / _parcelas;

    // Lista para armazenar as parcelas detalhadas
    _parcelasDetalhadas = List.generate(_parcelas, (i) {
      final diasPorParcela = _tipoParcela == 'Diárias'
          ? 1
          : _tipoParcela == 'Semanais'
          ? 7
          : _tipoParcela == 'Quinzenais'
          ? 15
          : 30; // Mensais como padrão

      // Gera a data de vencimento para cada parcela
      DateTime dataVencimento = (_dataVencimento ?? DateTime.now()).add(
        Duration(days: diasPorParcela * i),
      );

      return {
        'numero': i + 1,
        'valor': valorParcela,
        'dataVencimento': _dateFormat.format(dataVencimento),
        'status': 'No prazo', // Inicialmente, todas estão "No prazo"
      };
    });

    Future.microtask(notifyListeners);
  }

  Future<void> salvarSimulacao(Simulacao? simulacao) async {
    if (_parcelasDetalhadas.isEmpty) {
      return;
    }

    setLoading(true);

    try {
      final simulacaoToSave = Simulacao(
        id: simulacao?.id,
        nome: _nome,
        valor: _valor,
        parcelas: _parcelas,
        juros: _juros,
        data: DateTime.now(),
        tipoParcela: _tipoParcela,
        parcelasDetalhes: _parcelasDetalhadas,
        dataVencimento: _dataVencimento ?? DateTime.now(),
      );

      if (simulacao == null) {
        await _databaseHelper.criarSimulacao(simulacaoToSave);
      } else {
        // Atualizar uma simulação existente (você precisará adicionar esse método ao DatabaseHelper)
        // await _databaseHelper.updateSimulacao(simulacaoToSave);
      }
    } finally {
      setLoading(false);
    }
  }

  void carregarSimulacaoDetalhes(Simulacao simulacao) {
    setNome(simulacao.nome);
    setValor(simulacao.valor);
    setParcelas(simulacao.parcelas);
    setJuros(simulacao.juros);
    setTipoParcela(simulacao.tipoParcela);
    setDataVencimento(simulacao.dataVencimento!);
    setParcelasDetalhadas(simulacao.parcelasDetalhes);
    _totalComJuros = simulacao.valor * (1 + simulacao.juros / 100);
    setTotalComJuros(_totalComJuros);
  }

  Future<void> excluirSimulacao(Simulacao simulacao) async {
    try {
      // Você precisará adicionar esse método ao DatabaseHelper
      // await _databaseHelper.deleteSimulacao(simulacao.id!);
      _simulacoes.remove(simulacao); // Remova da lista local também
    } catch (e) {
      rethrow;
    } finally {
      notifyListeners(); // Notifique as mudanças após a exclusão
    }
  }

  Future<void> excluirEmprestimo(Emprestimo emprestimo) async {
    try {
      // Remove o empréstimo do banco de dados
      await _databaseHelper.deleteEmprestimo(emprestimo.id!);

      // Remove o empréstimo da lista local
      _emprestimosRecentes.removeWhere((e) => e.id == emprestimo.id);

      // Notifica os ouvintes para atualizar a interface
      notifyListeners();
    } catch (e) {
      // Trate o erro conforme necessário
      rethrow;
    }
  }


  Future<void> criarEmprestimo(String cpfCnpj, String whatsapp, String? email, String? endereco) async {
    if (_parcelasDetalhadas.isEmpty) {
      return;
    }

    setLoading(true);

    try {
      final emprestimo = Emprestimo(
        nome: _nome,
        valor: _valor,
        parcelas: _parcelas,
        juros: _juros,
        data: DateTime.now(),
        tipoParcela: _tipoParcela,
        cpfCnpj: cpfCnpj.trim(),
        whatsapp: whatsapp.trim(),
        email: email?.trim() ?? '',
        endereco: endereco?.trim() ?? '',
        parcelasDetalhes: _parcelasDetalhadas,
        dataVencimento: _dataVencimento ?? DateTime.now(),
      );

      await _databaseHelper.criarEmprestimo(emprestimo);
      _emprestimosRecentes.add(emprestimo); // Adiciona à lista local
    } finally {
      setLoading(false);
    }
  }

  Future<void> updateEmprestimo(Emprestimo emprestimo) async {
    try {
      await _databaseHelper.updateEmprestimo(emprestimo);
      // Atualizar a lista local
      int index = _emprestimosRecentes.indexWhere((e) => e.id == emprestimo.id);
      if (index != -1) {
        _emprestimosRecentes[index] = emprestimo;
      }
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  bool _listsAreEqualEmprestimo(List<Emprestimo> list1, List<Emprestimo> list2) {
    if (list1.length != list2.length) {
      return false;
    }
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) {
        return false;
      }
    }
    return true;
  }

  Future<Map<String, dynamic>> calcularRelatorioMensal(int mes, int ano) async {
    final emprestimos = await _databaseHelper.getEmprestimosPorMesEAno(mes, ano);

    double totalEmprestado = 0.0;
    double totalRecebido = 0.0;
    double lucro = 0.0;
    List<Map<String, dynamic>> tendenciaEmprestimos = [];

    // Calcular tendência de empréstimos para os últimos 6 meses
    for (int i = 5; i >= 0; i--) {
      DateTime data = DateTime(ano, mes - i, 1);
      double valorEmprestadoMes = 0.0;

      final emprestimosMes = await _databaseHelper.getEmprestimosPorMesEAno(data.month, data.year);

      for (final emprestimo in emprestimosMes) {
        valorEmprestadoMes += emprestimo.valor;
      }

      tendenciaEmprestimos.add({
        'mes': DateFormat('MMM').format(data), // Formato 'Jan', 'Fev', etc.
        'valor': valorEmprestadoMes,
      });
    }

    for (final emprestimo in emprestimos) {
      totalEmprestado += emprestimo.valor;
      final valorTotal = emprestimo.valor * (1 + emprestimo.juros / 100);
      final recebido = emprestimo.parcelasDetalhes
          .where((p) => p['status'] == 'Paga')
          .fold(0.0, (sum, p) => sum + p['valor']);
      totalRecebido += recebido;
      lucro += recebido - emprestimo.valor;
    }

    return {
      'totalEmprestado': totalEmprestado,
      'totalRecebido': totalRecebido,
      'lucro': lucro,
      'pendente': totalEmprestado - totalRecebido,
      'tendenciaEmprestimos': tendenciaEmprestimos,
    };
  }

  Future<List<Map<String, dynamic>>> calcularPrevisaoRecebimentos(int meses) async {
    final List<Map<String, dynamic>> previsao = [];
    final DateTime hoje = DateTime.now();

    for (int i = 0; i < meses; i++) {
      final DateTime inicioMes = DateTime(hoje.year, hoje.month + i, 1);
      final DateTime fimMes = DateTime(hoje.year, hoje.month + i + 1, 0);

      final String inicioMesFormatado = _dateFormat.format(inicioMes);
      final String fimMesFormatado = _dateFormat.format(fimMes);

      double totalReceberMes = 0.0;

      final List<Emprestimo> emprestimos = await _databaseHelper.getAllEmprestimos();

      for (final emprestimo in emprestimos) {
        for (final parcela in emprestimo.parcelasDetalhes) {
          if (parcela['status'] != 'Paga') {
            final DateTime dataVencimento = _dateFormat.parse(parcela['dataVencimento']);
            if (dataVencimento.isAfter(inicioMes.subtract(Duration(days: 1))) &&
                dataVencimento.isBefore(fimMes.add(Duration(days: 1)))) {
              totalReceberMes += parcela['valor'];
            }
          }
        }
      }

      previsao.add({
        'mes': DateFormat('MMM/yyyy', 'pt_BR').format(inicioMes),
        'valor': totalReceberMes,
      });
    }

    return previsao;
  }

}
