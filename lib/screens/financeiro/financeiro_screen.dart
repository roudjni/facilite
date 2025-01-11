import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:facilite/app/app_state.dart';
import 'package:facilite/widgets/main_layout.dart';

class FinanceiroScreen extends StatefulWidget {
  const FinanceiroScreen({Key? key}) : super(key: key);

  @override
  _FinanceiroScreenState createState() => _FinanceiroScreenState();
}

class _FinanceiroScreenState extends State<FinanceiroScreen> {
  bool _isLoading = true;
  double _totalEmprestado = 0.0;
  double _totalRecebido = 0.0;
  double _lucroTotal = 0.0;
  double _totalPendente = 0.0;
  double _saldoAtual = 0.0;
  double _lucroMesAnterior = 0.0;
  List<Map<String, dynamic>> _logs = [];

  // Pagination variables
  int _currentPage = 0;
  static const int _itemsPerPage = 7;
  List<Map<String, dynamic>> _currentPageLogs = [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  void _updateCurrentPageLogs() {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    setState(() {
      _currentPageLogs = _logs.length > startIndex
          ? _logs.sublist(startIndex, endIndex > _logs.length ? _logs.length : endIndex)
          : [];
    });
  }

  Future<void> _carregarDados() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final now = DateTime.now();

    final dadosFinanceiro = await appState.calcularRelatorioMensal(now.month, now.year);
    final dadosFinanceiroAnterior = await appState.calcularRelatorioMensal(now.month - 1, now.year);

    final logs = await appState.carregarLogsFinanceiros();

    setState(() {
      _totalEmprestado = dadosFinanceiro['totalEmprestado'] ?? 0.0;
      _totalRecebido = dadosFinanceiro['totalRecebido'] ?? 0.0;
      _lucroTotal = dadosFinanceiro['lucro'] ?? 0.0;
      _totalPendente = dadosFinanceiro['pendente'] ?? 0.0;
      _saldoAtual = appState.saldoDisponivel;
      _lucroMesAnterior = dadosFinanceiroAnterior['lucro'] ?? 0.0;
      _logs = logs;
      _currentPage = 0;
      _isLoading = false;
    });
    _updateCurrentPageLogs();
  }

  Widget _buildLogs() {
    if (_logs.isEmpty) {
      return const Center(
        child: Text(
          'Sem transações',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
      );
    }

    final dateFormat = DateFormat("dd/MM", 'pt_BR');

    return Card(
      margin: const EdgeInsets.all(0),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.45,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              width: double.infinity,
              color: Colors.black12,
              child: const Text(
                'Histórico de Transações',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _currentPageLogs.length,
              itemBuilder: (context, index) {
                final log = _currentPageLogs[index];
                final DateTime dataHora = DateTime.parse(log['data_hora']);
                final bool isAdicao = log['tipo'] == 'adicao';
                final valor = log['valor'] as double;

                return Column(
                  children: [
                    InkWell(
                      onTap: () {
                        // Opcional: Adicionar detalhes da transação aqui
                      },
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isAdicao ? Colors.green[400] : Colors.red[400],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${DateFormat("HH:mm").format(dataHora)} | ${dateFormat.format(dataHora)}',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'R\$ ${valor.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: isAdicao ? Colors.green[400] : Colors.red[400],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1, thickness: 0.5, color: Colors.white12),
                  ],
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 16, color: Colors.white54),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minHeight: 32, minWidth: 32),
                    onPressed: _currentPage > 0
                        ? () {
                      setState(() {
                        _currentPage--;
                      });
                      _updateCurrentPageLogs();
                    }
                        : null,
                  ),
                  Text(
                    '${_currentPage + 1}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minHeight: 32, minWidth: 32),
                    onPressed: (_currentPage + 1) * _itemsPerPage < _logs.length
                        ? () {
                      setState(() {
                        _currentPage++;
                      });
                      _updateCurrentPageLogs();
                    }
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return MainLayout(
      title: 'Financeiro',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _carregarDados,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildCard(
                context,
                'Saldo Atual',
                appState.numberFormat.format(_saldoAtual),
                Icons.account_balance,
                Colors.cyan,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionButton(
                      context: context,
                      icon: Icons.add_circle_outline,
                      label: 'Adicionar Dinheiro',
                      color: Colors.blue,
                      onTap: _adicionarDinheiroDialog,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQuickActionButton(
                      context: context,
                      icon: Icons.remove_circle_outline,
                      label: 'Remover Dinheiro',
                      color: Colors.red,
                      onTap: _removerDinheiroDialog,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildLogs(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _adicionarDinheiroDialog() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final dinheiroController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Adicionar Dinheiro', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.grey[900],
          content: TextField(
            controller: dinheiroController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Valor',
                labelStyle: TextStyle(color: Colors.white70)),
            style: const TextStyle(color: Colors.white),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Adicionar', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                final valorAdicionado = double.tryParse(dinheiroController.text.replaceAll(',', '.'));
                if (valorAdicionado != null && valorAdicionado > 0) {
                  await appState.adicionarSaldoDisponivel(valorAdicionado, appState.username);
                  await _carregarDados();
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Valor inválido!", style: TextStyle(color: Colors.white)),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _removerDinheiroDialog() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final dinheiroController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remover Dinheiro', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.grey[900],
          content: TextField(
            controller: dinheiroController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Valor',
                labelStyle: TextStyle(color: Colors.white70)),
            style: const TextStyle(color: Colors.white),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Remover', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                final valorRemovido = double.tryParse(dinheiroController.text.replaceAll(',', '.'));
                if (valorRemovido != null && valorRemovido > 0) {
                  if (valorRemovido <= appState.saldoDisponivel) {
                    await appState.removerSaldoDisponivel(valorRemovido, appState.username);
                    await _carregarDados();
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Saldo insuficiente!", style: TextStyle(color: Colors.white)),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Valor inválido!", style: TextStyle(color: Colors.white)),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Container(
      height: 72,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}