// lib/screens/financeiro/financeiro_screen.dart
import 'package:facilite/widgets/main_layout.dart';
import 'package:flutter/material.dart';

class FinanceiroScreen extends StatelessWidget {
  const FinanceiroScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MainLayout(
      title: 'Financeiro',
      child: Center(
        child: Text(
          'Tela de Financeiro',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}