// lib/widgets/custom_appbar.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emprestafacil/app/app_state.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return AppBar(
      elevation: 0,
      toolbarHeight: 48,
      automaticallyImplyLeading: false,
      leading: Builder(
        builder: (BuildContext context) {
          return IconButton(
            icon: const Icon(Icons.menu, color: Colors.white70),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        },
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: actions ??
          [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 20),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.account_circle_outlined, size: 20),
              onPressed: () {},
            ),
          ],
    );
  }
}
