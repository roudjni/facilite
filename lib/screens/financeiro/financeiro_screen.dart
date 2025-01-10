import 'package:flutter/material.dart';
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
  List<Map<String, dynamic>> _previsaoRecebimentos = [];



  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final dadosFinanceiro = await appState.calcularRelatorioMensal(DateTime.now().month, DateTime.now().year);

    final previsao = await appState.calcularPrevisaoRecebimentos(6);

    setState(() {
      _totalEmprestado = dadosFinanceiro['totalEmprestado'] ?? 0.0;
      _totalRecebido = dadosFinanceiro['totalRecebido'] ?? 0.0;
      _lucroTotal = dadosFinanceiro['lucro'] ?? 0.0;
      _totalPendente = dadosFinanceiro['pendente'] ?? 0.0;
      _saldoAtual = _totalRecebido - (_totalEmprestado - _totalPendente);
      _previsaoRecebimentos = previsao;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);


    return MainLayout(
      title: 'Financeiro',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumo Financeiro',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Cards de resumo
            Row(
              children: [
                Expanded(
                  child: _buildResumoCard(
                    'Total Emprestado',
                    appState.numberFormat.format(_totalEmprestado),
                    Icons.monetization_on,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildResumoCard(
                    'Total a Receber',
                    appState.numberFormat.format(_totalPendente),
                    Icons.attach_money,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildResumoCard(
                    'Total Recebido',
                    appState.numberFormat.format(_totalRecebido),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildResumoCard(
                    'Lucro Total',
                    appState.numberFormat.format(_lucroTotal),
                    Icons.trending_up,
                    Colors.lime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Análise de Fluxo de Caixa',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildResumoCard(
              'Saldo Atual',
              appState.numberFormat.format(_saldoAtual),
              Icons.account_balance,
              Colors.cyan,
            ),
            const SizedBox(height: 16),
            const Text(
              'Previsão de Recebimentos (Próximos Meses)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150, // Defina uma altura fixa ou ajuste conforme necessário
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _previsaoRecebimentos.length,
                itemBuilder: (context, index) {
                  final previsao = _previsaoRecebimentos[index];
                  return  Container(
                    width: 150,
                    margin: const EdgeInsets.only(right: 16),
                    child:  _buildPrevisaoCard(
                      previsao['mes'],
                      appState.numberFormat.format(previsao['valor']),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildResumoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
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
    );
  }

  Widget _buildPrevisaoCard(String mes, String valor) {
    return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:  Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child:  Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              mes,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 8),
            Text(
              valor,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16
              ),
            ),
          ],
        )
    );
  }
}