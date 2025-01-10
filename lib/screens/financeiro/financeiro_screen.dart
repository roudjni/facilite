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
  double _lucroMesAnterior = 0.0;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final now = DateTime.now();

    final dadosFinanceiro = await appState.calcularRelatorioMensal(now.month, now.year);
    final dadosFinanceiroAnterior = await appState.calcularRelatorioMensal(now.month -1 , now.year);

    setState(() {
      _totalEmprestado = dadosFinanceiro['totalEmprestado'] ?? 0.0;
      _totalRecebido = dadosFinanceiro['totalRecebido'] ?? 0.0;
      _lucroTotal = dadosFinanceiro['lucro'] ?? 0.0;
      _totalPendente = dadosFinanceiro['pendente'] ?? 0.0;
      _saldoAtual = _totalRecebido - (_totalEmprestado - _totalPendente);
      _lucroMesAnterior = dadosFinanceiroAnterior['lucro'] ?? 0.0;
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildCard(
                    context,
                    'Saldo Atual',
                    appState.numberFormat.format(_saldoAtual),
                    Icons.account_balance,
                    Colors.cyan,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return  Card(
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
        child:  Column(
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
}