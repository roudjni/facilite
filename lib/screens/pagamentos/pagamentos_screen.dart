import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:facilite/app/app_state.dart';
import 'package:facilite/data/models/emprestimo.dart';
import 'package:facilite/widgets/main_layout.dart';
import 'package:url_launcher/url_launcher.dart';

class PagamentosScreen extends StatefulWidget {
  const PagamentosScreen({Key? key}) : super(key: key);

  @override
  _PagamentosScreenState createState() => _PagamentosScreenState();
}

class _PagamentosScreenState extends State<PagamentosScreen> {
  String _filtroSelecionado = 'Todas';
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final pagamentos = _filtrarPagamentos(appState.emprestimosRecentes);

    return MainLayout(
      title: 'Pagamentos',
      actions: [_buildFilterButton()],
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF161616), Color(0xFF0A0A0A)],
            stops: [0.0, 1.0],
          ),
        ),
        child: Column(
          children: [
            _buildStatusBar(pagamentos),
            Expanded(
              child: pagamentos.isEmpty
                  ? _buildEmptyState()
                  : _buildPagamentosList(pagamentos),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: IconButton(
        icon: Stack(
          children: [
            const Icon(Icons.tune, size: 20),
            if (_filtroSelecionado != 'Todas')
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00B4D8),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        onPressed: _showFilterSheet,
      ),
    );
  }

  Widget _buildStatusBar(List<Emprestimo> pagamentos) {
    final emAtraso = pagamentos.where((e) => _getStatusText(e) == 'Atrasado').length;
    final aVencer = pagamentos.where((e) => _getStatusText(e) == 'A vencer').length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[900]!, Colors.grey[850]!],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatusItem('Em atraso', emAtraso, Colors.redAccent),
          _buildStatusDivider(),
          _buildStatusItem('A vencer', aVencer, Colors.greenAccent),
        ],
      ),
    );
  }

  Widget _buildStatusDivider() {
    return Container(
      height: 24,
      width: 1,
      color: Colors.grey[700],
    );
  }

  Widget _buildStatusItem(String label, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: ['Todas', 'A vencer', 'Atrasado']
                    .map((filtro) => _buildFilterOption(filtro))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String filtro) {
    final isSelected = _filtroSelecionado == filtro;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() => _filtroSelecionado = filtro);
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00B4D8).withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF00B4D8) : Colors.grey[700]!,
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                size: 18,
                color: isSelected ? const Color(0xFF00B4D8) : Colors.grey[400],
              ),
              const SizedBox(width: 12),
              Text(
                filtro,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF00B4D8) : Colors.grey[300],
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPagamentosList(List<Emprestimo> pagamentos) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: pagamentos.length,
      itemBuilder: (context, index) => _buildPagamentoCard(pagamentos[index]),
    );
  }

  Widget _buildPagamentoCard(Emprestimo emprestimo) {
    final parcelas = emprestimo.parcelasDetalhes;
    final proximaParcela = parcelas.firstWhere(
          (p) => p['status'] != 'Paga',
      orElse: () => {'numero': 0, 'valor': 0.0, 'dataVencimento': '', 'status': 'Indefinido'},
    );

    final vencimento = DateFormat('dd/MM/yyyy').parse(proximaParcela['dataVencimento']);
    final diasParaVencer = vencimento.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[850]!, Colors.grey[900]!],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!, width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.pushNamed(
            context,
            '/detalhes-emprestimo',
            arguments: emprestimo,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        emprestimo.nome,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    _buildStatusBadge(emprestimo),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'R\$ ${proximaParcela['valor']?.toStringAsFixed(2) ?? "0.00"}',
                          style: const TextStyle(
                            color: Color(0xFF00B4D8),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Venc. ${proximaParcela['dataVencimento']}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (_deveMostrarIconeLembrete(emprestimo.tipoParcela, diasParaVencer))
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _buildActionButton(
                          Icons.notifications_none,
                          const Color(0xFF00B4D8),
                              () => _enviarLembreteWhatsApp(emprestimo, [proximaParcela]),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Emprestimo emprestimo) {
    final status = _getStatusText(emprestimo);
    final color = _getStatusColor(emprestimo);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  bool _deveMostrarIconeLembrete(String tipoParcela, int diasParaVencer) {
    switch (tipoParcela) {
      case 'Diárias':
        return diasParaVencer < 0 && diasParaVencer >= -1; // Ícone aparece apenas se atrasado
      case 'Semanais':
        return diasParaVencer <= 2 && diasParaVencer >= 0; // Ícone aparece até 2 dias antes do vencimento
      case 'Quinzenais':
        return diasParaVencer <= 3 && diasParaVencer >= 0; // Ícone aparece até 3 dias antes do vencimento
      case 'Mensais':
        return diasParaVencer <= 4 && diasParaVencer >= 0; // Ícone aparece até 4 dias antes do vencimento
      default:
        return false;
    }
  }

  List<Emprestimo> _filtrarPagamentos(List<Emprestimo> emprestimos) {
    return emprestimos.where((emprestimo) {
      final parcelas = emprestimo.parcelasDetalhes;
      final proximaParcela = parcelas.firstWhere(
            (p) => p['status'] != 'Paga',
        orElse: () => {'dataVencimento': ''},
      );
      final vencimento = DateFormat('dd/MM/yyyy').parse(proximaParcela['dataVencimento']);
      final diasParaVencer = vencimento.difference(DateTime.now()).inDays;

      bool filtroSelecionadoValido = false;
      switch (_filtroSelecionado) {
        case 'A vencer':
          filtroSelecionadoValido = diasParaVencer >= 0 && parcelas.any((parcela) => parcela['status'] != 'Paga');
          break;
        case 'Atrasado':
          filtroSelecionadoValido = diasParaVencer < 0 && parcelas.any((parcela) => parcela['status'] != 'Paga');
          break;
        default:
          filtroSelecionadoValido = true;
      }

      bool tipoParcelaValido = false;
      switch (emprestimo.tipoParcela) {
        case 'Diárias':
          tipoParcelaValido = true;
          break;
        case 'Semanais':
          tipoParcelaValido = diasParaVencer <= 2 && diasParaVencer >= -1;
          break;
        case 'Quinzenais':
          tipoParcelaValido = diasParaVencer <= 3 && diasParaVencer >= -1;
          break;
        case 'Mensais':
          tipoParcelaValido = diasParaVencer <= 4 && diasParaVencer >= -1;
          break;
        default:
          tipoParcelaValido = false;
      }

      return filtroSelecionadoValido && tipoParcelaValido;
    }).toList();
  }

  String _getStatusText(Emprestimo emprestimo) {
    final atrasadas = emprestimo.parcelasDetalhes.where((p) {
      final vencimento = DateFormat('dd/MM/yyyy').parse(p['dataVencimento']);
      return vencimento.isBefore(DateTime.now()) && p['status'] != 'Paga';
    });

    if (atrasadas.isNotEmpty) return 'Atrasado';
    return 'A vencer';
  }

  Color _getStatusColor(Emprestimo emprestimo) {
    switch (_getStatusText(emprestimo)) {
      case 'Atrasado':
        return Colors.redAccent;
      default:
        return const Color(0xFF00B4D8);
    }
  }

  Future<void> _enviarLembreteWhatsApp(Emprestimo emprestimo, List<Map<String, dynamic>> parcelas) async {
    final numero = emprestimo.whatsapp.replaceAll(RegExp(r'[^\d]'), '');
    if (numero.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Número de WhatsApp inválido'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final mensagem = _gerarMensagemWhatsApp(emprestimo.nome, parcelas);
    final url = "whatsapp://send?phone=55$numero&text=${Uri.encodeComponent(mensagem)}";

    try {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        throw 'Não foi possível abrir o WhatsApp';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _gerarMensagemWhatsApp(String nome, List<Map<String, dynamic>> parcelas) {
    final now = DateTime.now();
    final formatter = DateFormat('dd/MM/yyyy');

    final status = _getStatusTextFromParcela(parcelas.first);

    String mensagem = "💳 *Lembrete de Pagamento*\n\n"
        "Olá, $nome!\n\n";

    if (status == 'A vencer') {
      mensagem += "Lembrete que sua parcela está próxima do vencimento:\n\n";
    } else {
      mensagem += "⚠️ Sua parcela está em atraso. Confira os detalhes abaixo:\n\n";
    }

    for (var parcela in parcelas) {
      mensagem += "📅 *Parcela ${parcela['numero']}*\n"
          "💰 Valor: R\$ ${parcela['valor'].toStringAsFixed(2)}\n"
          "📆 Vencimento: ${parcela['dataVencimento']}\n\n";
    }

    mensagem += "Por favor, entre em contato para mais informações. Obrigado!";
    return mensagem;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.payments_outlined,
            size: 48,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum pagamento encontrado',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: color),
        onPressed: onPressed,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(
          minHeight: 32,
          minWidth: 32,
        ),
      ),
    );
  }

  String _getStatusTextFromParcela(Map<String, dynamic> parcela) {
    final vencimento = DateFormat('dd/MM/yyyy').parse(parcela['dataVencimento']);
    if (vencimento.isBefore(DateTime.now()) && parcela['status'] != 'Paga') {
      return 'Atrasado';
    }
    return 'A vencer';
  }

}
