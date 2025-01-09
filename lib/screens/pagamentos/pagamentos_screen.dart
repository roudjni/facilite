import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:facilite/app/app_state.dart';
import 'package:facilite/data/models/emprestimo.dart';
import 'package:intl/intl.dart';
import 'package:facilite/widgets/main_layout.dart';

class PagamentosScreen extends StatefulWidget {
  const PagamentosScreen({Key? key}) : super(key: key);

  @override
  _PagamentosScreenState createState() => _PagamentosScreenState();
}

class _PagamentosScreenState extends State<PagamentosScreen> {
  String filtroSelecionado = 'Todas';

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final pagamentos = _filtrarPagamentos(appState.emprestimosRecentes);

    return MainLayout(
      title: 'Pagamentos',
      child: Column(
        children: [
          _buildFiltros(),
          Expanded(
            child: pagamentos.isEmpty
                ? const Center(
              child: Text(
                'Nenhum pagamento encontrado.',
                style: TextStyle(color: Colors.white),
              ),
            )
                : ListView.builder(
              itemCount: pagamentos.length,
              itemBuilder: (context, index) {
                final emprestimo = pagamentos[index];
                return _buildPagamentoCard(emprestimo);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DropdownButton<String>(
            value: filtroSelecionado,
            dropdownColor: Colors.grey[900],
            style: const TextStyle(color: Colors.white),
            items: ['Todas', 'Pagas', 'Em Atraso', 'No Prazo']
                .map((filtro) => DropdownMenuItem(
              value: filtro,
              child: Text(filtro),
            ))
                .toList(),
            onChanged: (valor) {
              setState(() {
                filtroSelecionado = valor!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPagamentoCard(Emprestimo emprestimo) {
    final parcelas = emprestimo.parcelasDetalhes;
    final numeroPagas = parcelas.where((p) => p['status'] == 'Paga').length;
    final proximaParcela = parcelas.firstWhere(
          (p) => p['status'] != 'Paga',
      orElse: () => {'numero': 0, 'valor': 0.0, 'dataVencimento': '', 'status': 'Indefinido'},
    );

    return Card(
      color: const Color(0xFF2D2D2D),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () {
          Navigator.pushNamed(context, '/detalhes-emprestimo',
              arguments: emprestimo);
        },
        title: Text(
          emprestimo.nome,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Parcelas: $numeroPagas/${emprestimo.parcelas}',
              style: const TextStyle(color: Colors.grey),
            ),
            if (proximaParcela['dataVencimento'].isNotEmpty)
              Text(
                'Próximo Vencimento: ${proximaParcela['dataVencimento']}',
                style: const TextStyle(color: Colors.grey),
              ),
          ],
        ),
        trailing: Icon(
          _getStatusIcon(emprestimo),
          color: _getStatusColor(emprestimo),
        ),
      ),
    );
  }

  List<Emprestimo> _filtrarPagamentos(List<Emprestimo> emprestimos) {
    if (filtroSelecionado == 'Todas') {
      return emprestimos;
    } else if (filtroSelecionado == 'Pagas') {
      return emprestimos
          .where((e) => e.parcelasDetalhes.every((p) => p['status'] == 'Paga'))
          .toList();
    } else if (filtroSelecionado == 'Em Atraso') {
      return emprestimos
          .where((e) => e.parcelasDetalhes.any((p) {
        final vencimento = DateFormat('dd/MM/yyyy').parse(p['dataVencimento']);
        return vencimento.isBefore(DateTime.now()) && p['status'] != 'Paga';
      }))
          .toList();
    } else {
      return emprestimos
          .where((e) => e.parcelasDetalhes.any((p) {
        final vencimento = DateFormat('dd/MM/yyyy').parse(p['dataVencimento']);
        return !vencimento.isBefore(DateTime.now()) && p['status'] != 'Paga';
      }))
          .toList();
    }
  }

  IconData _getStatusIcon(Emprestimo emprestimo) {
    final atrasadas = emprestimo.parcelasDetalhes.where((p) {
      final vencimento = DateFormat('dd/MM/yyyy').parse(p['dataVencimento']);
      return vencimento.isBefore(DateTime.now()) && p['status'] != 'Paga';
    });

    if (atrasadas.isNotEmpty) {
      return Icons.warning;
    } else if (emprestimo.parcelasDetalhes.every((p) => p['status'] == 'Paga')) {
      return Icons.check_circle;
    } else {
      return Icons.schedule;
    }
  }

  Color _getStatusColor(Emprestimo emprestimo) {
    final atrasadas = emprestimo.parcelasDetalhes.where((p) {
      final vencimento = DateFormat('dd/MM/yyyy').parse(p['dataVencimento']);
      return vencimento.isBefore(DateTime.now()) && p['status'] != 'Paga';
    });

    if (atrasadas.isNotEmpty) {
      return Colors.red;
    } else if (emprestimo.parcelasDetalhes.every((p) => p['status'] == 'Paga')) {
      return Colors.green;
    } else {
      return Colors.blue;
    }
  }
}
