import 'package:flutter/material.dart';
import 'package:emprestafacil/data/models/emprestimo.dart';
import 'package:intl/intl.dart';

class LoanCard extends StatelessWidget {
  final Emprestimo loan;

  LoanCard({required this.loan});

  @override
  Widget build(BuildContext context) {
    // Função para determinar o status com base nas parcelas pagas e atrasadas
    String getLoanStatus() {
      int paidInstallments = loan.parcelasDetalhes.where((parcela) => parcela['status'] == 'Paga').length;
      bool hasLateInstallment = loan.parcelasDetalhes.any((parcela) {
        // Formata a string de data 'dataVencimento' para DateTime
        final dueDate = DateFormat('dd/MM/yyyy').parse(parcela['dataVencimento']);
        return dueDate.isBefore(DateTime.now()) && parcela['status'] != 'Paga';
      });

      if (paidInstallments == loan.parcelas) {
        return 'Quitado';
      } else if (hasLateInstallment) {
        return 'Em Atraso';
      } else {
        return 'Em Dia';
      }
    }

    // Formatação de data
    String formattedDate(DateTime date) {
      return DateFormat('dd/MM/yyyy').format(date); // Usa DateFormat como classe
    }

    // Formatação de moeda
    String formattedCurrency(double value) {
      return "R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}";
    }

    // Obtém o número de parcelas pagas
    int paidInstallments = loan.parcelasDetalhes.where((parcela) => parcela['status'] == 'Paga').length;

    // Determina o status do empréstimo
    String loanStatus = getLoanStatus();

    return Card(
      color: const Color(0xFF2D2D2D),
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
            Text(
              loan.nome,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.blue, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Valor Total: ${formattedCurrency(loan.valor * (1 + loan.juros / 100))}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.blue, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Próx. Vencimento: ${formattedDate(loan.dataVencimento!)}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.payment, color: Colors.blue, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Parcelas: $paidInstallments/${loan.parcelas}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(loanStatus).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                loanStatus,
                style: TextStyle(
                  color: _getStatusColor(loanStatus),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Função auxiliar para obter a cor do status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Quitado':
        return Colors.green;
      case 'Em Atraso':
        return Colors.red;
      case 'Em Dia':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}