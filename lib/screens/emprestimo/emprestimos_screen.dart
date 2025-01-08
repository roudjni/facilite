import 'package:emprestafacil/screens/emprestimo/detalhes_emprestimo_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:emprestafacil/app/app_state.dart';
import 'package:emprestafacil/widgets/side_menu.dart';
import 'package:emprestafacil/widgets/custom_appbar.dart';
import 'package:emprestafacil/data/models/emprestimo.dart';

class EmprestimosScreen extends StatefulWidget {
  @override
  _EmprestimosScreenState createState() => _EmprestimosScreenState();
}

class _EmprestimosScreenState extends State<EmprestimosScreen> {
  bool _isLoading = false;
  bool _isFirstLoad = true;
  bool _isSelecting = false; // Modo de seleção
  Set<int> _selectedEmprestimos = {}; // IDs dos empréstimos selecionados

  Future<void> _loadEmprestimos() async {
    setState(() {
      _isLoading = true;
    });
    await Provider.of<AppState>(context, listen: false).loadAllEmprestimos();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isFirstLoad) {
      _loadEmprestimos();
      _isFirstLoad = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelecting
            ? '${_selectedEmprestimos.length} selecionado(s)'
            : 'Todos os Empréstimos'),
        actions: [
          if (_isSelecting)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteSelectedEmprestimos,
            ),
          if (!_isSelecting)
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: () {
                setState(() {
                  _isSelecting = true;
                });
              },
            ),
          if (_isSelecting)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSelecting = false;
                  _selectedEmprestimos.clear();
                });
              },
            ),
        ],
      ),
      drawer: const SideMenu(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildQuickActionButton(
                  context: context,
                  icon: Icons.add_circle_outline,
                  label: 'Criar Empréstimo',
                  color: Colors.blue,
                  onTap: () => Navigator.pushNamed(context, '/criar-emprestimo'),
                ),
                _buildQuickActionButton(
                  context: context,
                  icon: Icons.calculate,
                  label: 'Simular Empréstimo',
                  color: Colors.orange,
                  onTap: () => Navigator.pushNamed(context, '/simulacao'),
                ),
                _buildQuickActionButton(
                  context: context,
                  icon: Icons.update,
                  label: 'Atualizar Status',
                  color: Colors.green,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Atualizando status...')),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : appState.paginatedEmprestimos.isEmpty
                      ? const Center(
                      child: Text('Nenhum empréstimo encontrado.'))
                      : Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: GridView.builder(
                      gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context)
                            .size
                            .width >
                            1200
                            ? 4
                            : 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 8,
                        childAspectRatio: 2,
                      ),
                      itemCount:
                      appState.paginatedEmprestimos.length,
                      itemBuilder: (context, index) {
                        final emprestimo =
                        appState.paginatedEmprestimos[index];
                        final isSelected = _selectedEmprestimos
                            .contains(emprestimo.id);

                        return InkWell(
                          onLongPress: () {
                            setState(() {
                              _isSelecting = true;
                              _selectedEmprestimos
                                  .add(emprestimo.id!);
                            });
                          },
                          onTap: _isSelecting
                              ? () {
                            setState(() {
                              if (isSelected) {
                                _selectedEmprestimos
                                    .remove(emprestimo.id);
                              } else {
                                _selectedEmprestimos
                                    .add(emprestimo.id!);
                              }
                            });
                          }
                              : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DetalhesEmprestimoScreen(
                                        emprestimo:
                                        emprestimo),
                              ),
                            );
                          },
                          child: Stack(
                            children: [
                              LoanCard(
                                loan: LoanData(
                                  id: emprestimo.id.toString(),
                                  clientName: emprestimo.nome,
                                  totalAmount: emprestimo.valor *
                                      (1 + emprestimo.juros / 100),
                                  nextPaymentDate:
                                  _calculateNextPaymentDate(
                                      emprestimo),
                                  paidInstallments: emprestimo
                                      .parcelasDetalhes
                                      .where((p) =>
                                  p['status'] == 'Paga')
                                      .length,
                                  totalInstallments:
                                  emprestimo.parcelas,
                                  status: _getLoanStatus(
                                      emprestimo),
                                ),
                              ),
                              if (_isSelecting)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Checkbox(
                                    value: isSelected,
                                    onChanged: (selected) {
                                      setState(() {
                                        if (selected ?? false) {
                                          _selectedEmprestimos
                                              .add(emprestimo.id!);
                                        } else {
                                          _selectedEmprestimos
                                              .remove(emprestimo.id);
                                        }
                                      });
                                    },
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 24,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .primaryColor
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left, size: 20),
                              onPressed: appState.currentPage > 0
                                  ? () => appState.previousPage()
                                  : null,
                              tooltip: 'Anterior',
                              padding: EdgeInsets.zero,
                              color: appState.currentPage > 0
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                            Container(
                              constraints:
                              const BoxConstraints(minWidth: 32),
                              alignment: Alignment.center,
                              child: Text(
                                '${appState.currentPage + 1}',
                                style: TextStyle(
                                  color:
                                  Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right,
                                  size: 20),
                              onPressed: (appState.currentPage + 1) *
                                  appState.itemsPerPage <
                                  appState
                                      .emprestimosRecentes.length
                                  ? () => appState.nextPage()
                                  : null,
                              tooltip: 'Próxima',
                              padding: EdgeInsets.zero,
                              color: (appState.currentPage + 1) *
                                  appState.itemsPerPage <
                                  appState
                                      .emprestimosRecentes.length
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _deleteSelectedEmprestimos() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Empréstimos'),
        content: Text(
            'Você tem certeza que deseja excluir ${_selectedEmprestimos.length} empréstimo(s)?'),
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

    if (!confirm) return;

    final appState = Provider.of<AppState>(context, listen: false);
    for (var id in _selectedEmprestimos) {
      final emprestimo = appState.emprestimosRecentes.firstWhere((e) => e.id == id);
      await appState.excluirEmprestimo(emprestimo);
    }

    setState(() {
      _isSelecting = false;
      _selectedEmprestimos.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_selectedEmprestimos.length} empréstimo(s) excluído(s)!'),
        backgroundColor: Colors.green,
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
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 72,
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
      ),
    );
  }

  LoanStatus _getLoanStatus(Emprestimo emprestimo) {
    int paidInstallments = emprestimo.parcelasDetalhes.where((parcela) => parcela['status'] == 'Paga').length;
    bool hasLateInstallment = emprestimo.parcelasDetalhes.any((parcela) {
      final dueDate = DateFormat('dd/MM/yyyy').parse(parcela['dataVencimento']);
      return dueDate.isBefore(DateTime.now()) && parcela['status'] != 'Paga';
    });

    if (paidInstallments == emprestimo.parcelas) {
      return LoanStatus.quitado;
    } else if (hasLateInstallment) {
      return LoanStatus.atrasado;
    } else {
      return LoanStatus.emDia;
    }
  }

  String _calculateNextPaymentDate(Emprestimo emprestimo) {
    final parcelasNaoPagas = emprestimo.parcelasDetalhes
        .where((p) => p['status'] != 'Paga')
        .toList();

    if (parcelasNaoPagas.isEmpty) return 'Não há parcelas pendentes';

    parcelasNaoPagas.sort((a, b) {
      final dataA = DateFormat('dd/MM/yyyy').parse(a['dataVencimento']);
      final dataB = DateFormat('dd/MM/yyyy').parse(b['dataVencimento']);
      return dataA.compareTo(dataB);
    });

    return parcelasNaoPagas.first['dataVencimento'];
  }
}

class LoanCard extends StatelessWidget {
  final LoanData loan;

  const LoanCard({required this.loan, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: loan.status.color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          final appState = Provider.of<AppState>(context, listen: false);
          final emprestimoCorrespondente = appState.paginatedEmprestimos
              .firstWhere((emp) => emp.id.toString() == loan.id);

          Navigator.pushNamed(
            context,
            '/detalhes-emprestimo',
            arguments: emprestimoCorrespondente,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: Text(
                      loan.clientName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loan.clientName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Contrato #${loan.id}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(loan.status),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoColumn(
                    label: 'Valor Total',
                    value: 'R\$ ${loan.totalAmount.toStringAsFixed(2)}',
                  ),
                  _buildInfoColumn(
                    label: 'Próximo Pgto.',
                    value: loan.nextPaymentDate,
                    alignment: CrossAxisAlignment.end,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: loan.paidInstallments / loan.totalInstallments,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation(loan.status.color),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${loan.paidInstallments}/${loan.totalInstallments} parcelas pagas',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(LoanStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: status.color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 12, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(fontSize: 11, color: status.color),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn({
    required String label,
    required String value,
    CrossAxisAlignment alignment = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class LoanData {
  final String id;
  final String clientName;
  final double totalAmount;
  final String nextPaymentDate;
  final int paidInstallments;
  final int totalInstallments;
  final LoanStatus status;

  const LoanData({
    required this.id,
    required this.clientName,
    required this.totalAmount,
    required this.nextPaymentDate,
    required this.paidInstallments,
    required this.totalInstallments,
    required this.status,
  });
}

class LoanStatus {
  final String label;
  final Color color;
  final IconData icon;

  const LoanStatus({
    required this.label,
    required this.color,
    required this.icon,
  });

  static const emDia = LoanStatus(
    label: 'Em dia',
    color: Colors.green,
    icon: Icons.check_circle,
  );

  static const pendente = LoanStatus(
    label: 'Pendente',
    color: Colors.orange,
    icon: Icons.warning,
  );

  static const atrasado = LoanStatus(
    label: 'Atrasado',
    color: Colors.red,
    icon: Icons.error,
  );

  static const quitado = LoanStatus(
    label: 'Quitado',
    color: Colors.blue,
    icon: Icons.task_alt,
  );
}