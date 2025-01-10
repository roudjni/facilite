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
      _saldoAtual = appState.saldoDisponivel;
      _lucroMesAnterior = dadosFinanceiroAnterior['lucro'] ?? 0.0;
      _isLoading = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return MainLayout(
      title: 'Financeiro',
      actions: [
        IconButton(
          onPressed: _adicionarDinheiroDialog,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
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
                labelStyle: TextStyle(color: Colors.white70)
            ),
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
              onPressed: () {
                final valorAdicionado = double.tryParse(dinheiroController.text.replaceAll(',', '.'));
                if(valorAdicionado != null)
                {
                  appState.adicionarSaldoDisponivel(valorAdicionado);
                  setState(() {
                    _saldoAtual = appState.saldoDisponivel;
                  });
                  Navigator.of(context).pop();
                }
                else {
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

  Widget _buildCard(BuildContext context, String title, String value, IconData icon, Color color) {
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

  Widget _buildLucroComparativoCard(BuildContext context,String title, String valorAtual, String valorAnterior) {
    final appState = Provider.of<AppState>(context, listen: false);
    String cleanedValorAnterior = valorAnterior.replaceAll(RegExp(r'[^\d.-]'), '').trim();
    String cleanedValorAtual = valorAtual.replaceAll(RegExp(r'[^\d.-]'), '').trim();

    double parsedValorAnterior = double.tryParse(cleanedValorAnterior) ?? 0.0;
    double parsedValorAtual = double.tryParse(cleanedValorAtual) ?? 0.0;

    final double diferenca = parsedValorAtual - parsedValorAnterior;
    final percentual = parsedValorAnterior > 0
        ? (diferenca / parsedValorAnterior) * 100
        : 0.0;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child:  Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  appState.numberFormat.format(parsedValorAtual),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${percentual.isNaN ? 0.0 : percentual.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 18,
                    color: diferenca > 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Mês Anterior: ${appState.numberFormat.format(parsedValorAnterior)}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}