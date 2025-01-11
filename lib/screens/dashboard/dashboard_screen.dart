import 'package:facilite/data/models/emprestimo.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:facilite/app/app_state.dart';
import 'package:facilite/widgets/main_layout.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<Map<String, dynamic>> quickActions = [
    {
      'icon': Icons.add_circle_outline,
      'label': 'Criar Empréstimo',
      'route': '/criar-emprestimo',
      'color': Colors.blue,
    },
    {
      'icon': Icons.calculate,
      'label': 'Simulação',
      'route': '/simulacao',
      'color': Colors.orange,
    },
    {
      'icon': Icons.assessment_outlined,
      'label': 'Relatórios',
      'route': '/relatorios',
      'color': Colors.green,
    },
    {
      'icon': Icons.account_balance_wallet,
      'label': 'Financeiro',
      'route': '/financeiro',
      'color': Colors.purple, // Escolha a cor desejada
    },
  ];
  bool _isFirstLoad = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isFirstLoad) {
      Provider.of<AppState>(context, listen: false).loadRecentEmprestimos();
      _isFirstLoad = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return MainLayout(
      title: 'Dashboard',
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      title: 'Saldo Disponível',
                      value: appState.numberFormat.format(appState.saldoDisponivel),
                      icon: Icons.account_balance_wallet,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoCard(
                      title: 'Total Emprestado',
                      value: appState.numberFormat.format(appState.totalEmprestado),
                      icon: Icons.payments,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ações Rápidas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: quickActions.map((action) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: action != quickActions.last ? 12.0 : 0,
                          ),
                          child: SizedBox(
                            height: 72,
                            child: _buildQuickActionButton(
                              context,
                              icon: action['icon'],
                              label: action['label'],
                              route: action['route'],
                              color: action['color'],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              RecentLoansSection(
                loans: appState.emprestimosRecentes.map((emprestimo) {
                  return LoanData(
                    id: emprestimo.id.toString(),
                    clientName: emprestimo.nome,
                    totalAmount: emprestimo.valor * (1 + emprestimo.juros / 100),
                    nextPaymentDate: _calculateNextPaymentDate(emprestimo),
                    paidInstallments: emprestimo.parcelasDetalhes.where((p) => p['status'] == 'Paga').length,
                    totalInstallments: emprestimo.parcelas,
                    status: _getLoanStatus(emprestimo),
                  );
                }).toList(),
                onViewAll: () => Navigator.pushNamed(context, '/loans'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
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
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
      BuildContext context, {
        required IconData icon,
        required String label,
        required String route,
        required Color color,
      }) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
            Icon(
              icon,
              size: 22,
              color: color,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
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
}

class RecentLoansSection extends StatelessWidget {
  final List<LoanData> loans;
  final VoidCallback onViewAll;

  const RecentLoansSection({
    required this.loans,
    required this.onViewAll,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Empréstimos Recentes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: onViewAll,
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Ver todos', style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 8,
            childAspectRatio: 2,
          ),
          itemCount: loans.length,
          itemBuilder: (context, index) {
            final loan = loans[index];
            return InkWell(
              onTap: () {
                Future.microtask(() {
                  final appState = Provider.of<AppState>(context, listen: false);
                  final emprestimoCorrespondente = appState.emprestimosRecentes
                      .firstWhere((emp) => emp.id.toString() == loan.id);

                  Navigator.pushNamed(
                    context,
                    '/detalhes-emprestimo',
                    arguments: emprestimoCorrespondente,
                  );
                });
              },
              child: LoanCard(
                loan: loan,
              ),
            );
          },
        ),
      ],
    );
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
          final emprestimoCorrespondente = appState.emprestimosRecentes
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