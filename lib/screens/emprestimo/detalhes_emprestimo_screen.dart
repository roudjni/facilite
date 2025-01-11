import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:facilite/app/app_state.dart';
import 'package:facilite/data/models/emprestimo.dart';
import 'package:facilite/widgets/main_layout.dart';
import 'package:intl/intl.dart';
import 'package:facilite/utils/pdf_generator.dart';
import 'package:facilite/widgets/shared/calendar_dialog.dart';

class DetalhesEmprestimoScreen extends StatefulWidget {
  final Emprestimo emprestimo;

  const DetalhesEmprestimoScreen({Key? key, required this.emprestimo}) : super(key: key);

  @override
  _DetalhesEmprestimoScreenState createState() => _DetalhesEmprestimoScreenState();
}

class _DetalhesEmprestimoScreenState extends State<DetalhesEmprestimoScreen> {
  String filtroSelecionado = 'Todas'; // Opções: Todas, Pagas, No prazo, Em atraso
  final darkBackground = const Color(0xFF1A1A1A);
  final cardBackground = const Color(0xFF2D2D2D);
  final accentColor = Colors.blue;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Detalhes do Empréstimo',
      actions: [
        IconButton(
          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
          onPressed: () async {
            final confirm = await _showConfirmDeleteDialog(context);
            if (confirm) {
              await _deleteLoan(context);
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.share, size: 20), // Ajusta o tamanho do ícone
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.edit, size: 20), // Ajusta o tamanho do ícone
          onPressed: () => Navigator.pushNamed(
            context,
            '/editar-emprestimo',
            arguments: widget.emprestimo,
          ),
        ),
        PopupMenuButton(
          icon: const Icon(Icons.more_vert, size: 20, color: Colors.white),
          color: Colors.grey[800],
          itemBuilder: (context) => [
            PopupMenuItem(
              onTap: () async {
                await Future.microtask(() => gerarPdfEmprestimo(widget.emprestimo));
              },
              child: const Row(
                children: [
                  Icon(Icons.picture_as_pdf, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text('Gerar PDF'),
                ],
              ),
            ),
            PopupMenuItem(
              onTap: () async {
                await Future.microtask(() => gerarContratoEmprestimo(widget.emprestimo));
              },
              child: const Row(
                children: [
                  Icon(Icons.description, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text('Gerar Contrato'),
                ],
              ),
            ),
          ],
        ),
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTopCards(context),
                  const SizedBox(height: 16),
                  _buildDetalhamentoParcelas(context),
                  const SizedBox(height: 16),
                  _buildHistorico(context),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 300,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
              child: _buildEstatisticasWidget(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstatisticasWidget(BuildContext context) {
    final parcelasDetalhes = widget.emprestimo.parcelasDetalhes;
    final parcelasPagas = parcelasDetalhes.where((p) => p['status'] == 'Paga').length;
    final totalParcelas = parcelasDetalhes.length;
    final progresso = parcelasPagas / totalParcelas;

    final valorTotal = widget.emprestimo.valor * (1 + widget.emprestimo.juros / 100);
    final valorPago = parcelasDetalhes
        .where((p) => p['status'] == 'Paga')
        .fold(0.0, (sum, p) => sum + (p['valor'] as double));
    final valorFaltante = valorTotal - valorPago;
    final parcelasRestantes = totalParcelas - parcelasPagas;

    return Card(
      color: cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Visão Geral',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Valor Total
            _buildMiniStatCard(
              'Valor devedor',
              context.read<AppState>().numberFormat.format(valorTotal),
              Icons.account_balance_wallet,
              Colors.purple,
            ),
            const SizedBox(height: 8),

            // Progresso
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(progresso * 100).toStringAsFixed(0)}% Concluído',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    Text(
                      '$parcelasPagas/$totalParcelas parcelas',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progresso,
                    minHeight: 6,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Mini Cards - Primeira Linha
            Row(
              children: [
                Expanded(
                  child: _buildMiniStatCard(
                    'Já foi pago',
                    context.read<AppState>().numberFormat.format(valorPago),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMiniStatCard(
                    'Falta pagar',
                    context.read<AppState>().numberFormat.format(valorFaltante),
                    Icons.pending,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Mini Cards - Segunda Linha
            Row(
              children: [
                Expanded(
                  child: _buildMiniStatCard(
                    'Faltam',
                    parcelasRestantes.toString(),
                    Icons.calendar_today,
                    Colors.indigo,
                    showSuffix: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMiniStatCard(
                    'Em atraso',
                    _getParcelasAtrasadas(parcelasDetalhes),
                    Icons.warning,
                    Colors.red,
                    showSuffix: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Mini Cards - Terceira Linha
            _buildMiniStatCard(
              'Próximo vencimento',
              _proximoVencimento(),
              Icons.event,
              Colors.blue,
              isDate: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStatCard(
      String label,
      String value,
      IconData icon,
      Color color, {
        bool isDate = false,
        bool showSuffix = false,
      }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isDate ? value : showSuffix ? '$value parcelas' : value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getParcelasAtrasadas(List<dynamic> parcelasDetalhes) {
    final atrasadas = parcelasDetalhes.where((p) {
      final dataVencimento = DateFormat('dd/MM/yyyy').parse(p['dataVencimento']);
      return DateTime.now().isAfter(dataVencimento) && p['status'] != 'Paga';
    }).length;
    return atrasadas.toString();
  }

  Widget _buildTopCards(BuildContext context) {
    return IntrinsicHeight( // Garante que os widgets dentro do Row tenham a mesma altura
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch, // Faz os widgets se esticarem verticalmente
        children: [
          Expanded(
            flex: 1, // Ambos os cards têm a mesma largura
            child: _buildClienteCard(context),
          ),
          const SizedBox(width: 16), // Espaçamento entre os cards
          Expanded(
            flex: 1, // Ambos os cards têm a mesma largura
            child: _buildValoresCard(context),
          ),
        ],
      ),
    );
  }

  Widget _buildClienteCard(BuildContext context) {
    final parcelasDetalhes = widget.emprestimo.parcelasDetalhes;
    final todasPagas = parcelasDetalhes.every((parcela) => parcela['status'] == 'Paga');
    final temParcelasAtrasadas = parcelasDetalhes.any((parcela) {
      final DateTime dataVencimento = DateFormat('dd/MM/yyyy').parse(parcela['dataVencimento']);
      return DateTime.now().isAfter(dataVencimento) && parcela['status'] != 'Paga';
    });
    final String statusGeral = todasPagas ? 'Quitado' : temParcelasAtrasadas ? 'Em atraso' : 'Em dia';

    return Card(
      color: cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with client info and status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: accentColor.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: accentColor.withOpacity(0.2),
                    child:  Text(
                      widget.emprestimo.nome.isNotEmpty ? widget.emprestimo.nome[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.emprestimo.nome,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Cliente desde ${Provider.of<AppState>(context, listen: false).dateFormat.format(widget.emprestimo.data)}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(statusGeral).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(statusGeral).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(statusGeral),
                        color: _getStatusColor(statusGeral),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusGeral,
                        style: TextStyle(
                          color: _getStatusColor(statusGeral),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Divider with improved spacing
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Divider(
                color: Colors.grey.withOpacity(0.2),
                thickness: 1,
              ),
            ),

            // Client details with CPF and Phone on the same line
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // First row: CPF and Phone
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        'CPF/CNPJ',
                        widget.emprestimo.cpfCnpj,
                        Icons.assignment_ind,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildDetailItem(
                        'Telefone',
                        widget.emprestimo.whatsapp,
                        Icons.phone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Email
                _buildDetailItem(
                  'Email',
                  widget.emprestimo.email ?? 'Não informado',
                  Icons.email,
                ),
                const SizedBox(height: 16),
                // Address
                _buildDetailItem(
                  'Endereço',
                  widget.emprestimo.endereco ?? 'Não informado',
                  Icons.location_on,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.grey[400],
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Quitado':
        return Colors.green;
      case 'Em atraso':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Quitado':
        return Icons.check_circle;
      case 'Em atraso':
        return Icons.warning;
      default:
        return Icons.schedule;
    }
  }

  Widget _buildValoresCard(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final valorTotal = widget.emprestimo.valor * (1 + widget.emprestimo.juros / 100);
    final valorParcela = valorTotal / widget.emprestimo.parcelas;
    final lucro = valorTotal - widget.emprestimo.valor;
    // Removida a variável taxaMensal

    return Card(
      color: cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header mais compacto
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: Colors.blue, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Valores e Condições',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Principais valores em cards menores
            Row(
              children: [
                Expanded(
                  child: _buildMainValueCard(
                    'Valor do empréstimo',
                    appState.numberFormat.format(widget.emprestimo.valor),
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMainValueCard(
                    'Valor com juros',
                    appState.numberFormat.format(valorTotal),
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Grid de informações compacto
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildCompactInfo(
                          'Parcelas',
                          '${widget.emprestimo.parcelas}x',
                          Colors.orange,
                        ),
                      ),
                      Expanded(
                        child: _buildCompactInfo(
                          'Valor da parcela',
                          appState.numberFormat.format(valorParcela),
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCompactInfo(
                          'Taxa de juros',
                          '${widget.emprestimo.juros.toStringAsFixed(0)}%',
                          Colors.purple,
                        ),
                      ),
                      Expanded(
                        child: _buildCompactInfo(
                          'Periodicidade',
                          widget.emprestimo.tipoParcela,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Lucro em formato compacto
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.trending_up, color: Colors.green, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Lucro Total',
                            style: TextStyle(
                              color: Colors.green[300],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appState.numberFormat.format(lucro),
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Por Parcela',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appState.numberFormat.format(lucro / widget.emprestimo.parcelas),
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainValueCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInfo(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDetalhamentoParcelas(BuildContext context) {
    return Card(
      color: cardBackground,
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section with filter
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Detalhamento das Parcelas',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                _buildFilterButton(),
              ],
            ),
          ),
          // Parcelas list
          _buildParcelasList(),
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextButton.icon(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        icon: const Icon(Icons.filter_list, color: Colors.blue, size: 20),
        label: Text(
          'Filtrar: $filtroSelecionado',
          style: const TextStyle(color: Colors.blue),
        ),
        onPressed: () async {
          final filtro = await _mostrarFiltro(context);
          if (filtro != null) {
            setState(() {
              filtroSelecionado = filtro;
            });
          }
        },
      ),
    );
  }

  Widget _buildParcelasList() {
    final appState = Provider.of<AppState>(context, listen: false);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.emprestimo.parcelasDetalhes.length,
      itemBuilder: (context, index) {
        final parcela = widget.emprestimo.parcelasDetalhes[index];
        final DateTime dataVencimento = dateFormat.parse(parcela['dataVencimento']);
        final bool estaPaga = parcela['status'] == 'Paga';
        final bool estaAtrasada = DateTime.now().isAfter(dataVencimento) && !estaPaga;
        final String status = estaPaga ? 'Paga' : estaAtrasada ? 'Em atraso' : 'No prazo';

        if (filtroSelecionado != 'Todas' && status != filtroSelecionado) {
          return const SizedBox.shrink();
        }

        return _buildParcelaCard(parcela, estaPaga, estaAtrasada, status, appState);
      },
    );
  }

  Widget _buildParcelaCard(
      Map<String, dynamic> parcela,
      bool estaPaga,
      bool estaAtrasada,
      String status,
      AppState appState,
      ) {
    final Color statusColor = estaPaga
        ? Colors.green
        : estaAtrasada
        ? Colors.red
        : Colors.blue;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              estaPaga
                  ? Icons.check_circle
                  : estaAtrasada
                  ? Icons.error
                  : Icons.schedule,
              color: statusColor,
            ),
          ),
          title: Row(
            children: [
              Text(
                '${parcela['numero']}ª Parcela',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Text(
            'Vencimento: ${parcela['dataVencimento']}',
            style: TextStyle(color: Colors.grey[400]),
          ),
          trailing: Text(
            appState.numberFormat.format(parcela['valor']),
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Data do Pagamento
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Data do pagamento',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            parcela['dataPagamento'] ?? 'Não realizado',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),

                      // Botões para ações
                      estaPaga
                          ? // Botão "Desfazer Pagamento"
                      ElevatedButton.icon(
                        onPressed: () async {
                          setState(() {
                            parcela['status'] = 'No prazo';
                            parcela['dataPagamento'] = null;
                          });
                          await appState.removerSaldoDisponivel(parcela['valor'], appState.username); // Remove o valor do saldo
                          final emprestimo = widget.emprestimo;
                          emprestimo.parcelasDetalhes =
                              widget.emprestimo.parcelasDetalhes;
                          await appState.updateEmprestimo(emprestimo);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Pagamento desfeito com sucesso!'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                        icon: const Icon(Icons.undo, size: 18),
                        label: const Text('Desfazer pagamento'),
                      )
                          : // Botões "Pagar Hoje" e "Pagar Outra Data"
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              final hoje = DateTime.now();
                              setState(() {
                                parcela['status'] = 'Paga';
                                parcela['dataPagamento'] =
                                    DateFormat('dd/MM/yyyy').format(hoje);
                              });
                              await appState.adicionarSaldoDisponivel(parcela['valor'], appState.username); // Adiciona o valor ao saldo
                              final emprestimo = widget.emprestimo;
                              emprestimo.parcelasDetalhes =
                                  widget.emprestimo.parcelasDetalhes;
                              await appState.updateEmprestimo(emprestimo);

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                  Text('Pagamento registrado para hoje!'),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                            icon: const Icon(Icons.today, size: 18),
                            label: const Text('Pagar hoje'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final initialDate = parcela['dataPagamento'] != null
                                  ? DateFormat('dd/MM/yyyy').parse(parcela['dataPagamento'])
                                  : DateTime.now();


                              final dataEscolhida = await showDialog<DateTime>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AppCalendarDialog(initialDate: initialDate); // Usando o novo Widget
                                },
                              );



                              if (dataEscolhida != null) {
                                setState(() {
                                  parcela['status'] = 'Paga';
                                  parcela['dataPagamento'] =
                                      DateFormat('dd/MM/yyyy')
                                          .format(dataEscolhida);
                                });
                                await appState.adicionarSaldoDisponivel(parcela['valor'], appState.username); // Adiciona o valor ao saldo

                                final emprestimo = widget.emprestimo;
                                emprestimo.parcelasDetalhes =
                                    widget.emprestimo.parcelasDetalhes;
                                await appState.updateEmprestimo(emprestimo);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Pagamento registrado para ${DateFormat('dd/MM/yyyy').format(dataEscolhida)}!',
                                    ),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                            icon:
                            const Icon(Icons.calendar_today, size: 18),
                            label: const Text('Pagar outra data'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _mostrarFiltro(BuildContext context) async {
    return await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Filtrar parcelas'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'Todas'),
              child: const Text('Todas'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'Paga'),
              child: const Text('Pagas'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'No prazo'),
              child: const Text('No prazo'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'Em atraso'),
              child: const Text('Em atraso'),
            ),
          ],
        );
      },
    );
  }

  String _proximoVencimento() {
    final hoje = DateTime.now();
    final parcelasNaoPagas = widget.emprestimo.parcelasDetalhes
        .where((p) => p['status'] != 'Paga')
        .toList();

    if (parcelasNaoPagas.isEmpty) return 'Não há parcelas pendentes';

    final proximaParcela = parcelasNaoPagas.reduce((a, b) {
      final dataA = DateFormat('dd/MM/yyyy').parse(a['dataVencimento']);
      final dataB = DateFormat('dd/MM/yyyy').parse(b['dataVencimento']);
      return dataA.isBefore(dataB) ? a : b;
    });

    return proximaParcela['dataVencimento'];
  }

  Widget _buildHistorico(BuildContext context) {
    return Card(
      color: cardBackground,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Histórico',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            _buildEventosHistoricoList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEventoHistorico(
      String titulo,
      String data,
      String descricao,
      IconData icone,
      Color cor,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icone, color: cor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  data,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  descricao,
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventosHistoricoList() {
    final eventos = [
      _buildEventoHistorico(
        'Empréstimo criado',
        Provider.of<AppState>(context, listen: false)
            .dateFormat
            .format(widget.emprestimo.data),
        'Empréstimo registrado no sistema',
        Icons.add_circle,
        Colors.blue,
      ),
    ];

    // Adicionar eventos de pagamento
    for (var parcela in widget.emprestimo.parcelasDetalhes) {
      if (parcela['status'] == 'Paga' && parcela['dataPagamento'] != null) {
        eventos.add(
          _buildEventoHistorico(
            'Parcela ${parcela['numero']} paga',
            parcela['dataPagamento'],
            'Pagamento da ${parcela['numero']}ª parcela registrado',
            Icons.payment,
            Colors.green,
          ),
        );
      }
    }

    return Column(children: eventos);
  }

  Future<void> _deleteLoan(BuildContext context) async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.excluirEmprestimo(widget.emprestimo);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Empréstimo excluído com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true); // Retorna para a tela anterior
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir o empréstimo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showConfirmDeleteDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Empréstimo'),
        content: const Text('Tem certeza de que deseja excluir este empréstimo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ??
        false;
  }
}
