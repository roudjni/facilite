// lib/widgets/main_layout.dart

import 'package:flutter/material.dart';
import 'package:emprestafacil/widgets/custom_appbar.dart';
import 'package:emprestafacil/widgets/side_menu.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final String title;
  final List<Widget>? actions;

  const MainLayout({
    Key? key,
    required this.child,
    required this.title,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: title,
        actions: actions, // Passe as ações personalizadas aqui
      ),
      drawer: const SideMenu(),
      body: child,
    );
  }
}
