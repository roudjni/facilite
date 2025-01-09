import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:facilite/app/app_state.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Drawer(
          backgroundColor: Colors.black87,
          child: Column(
            children: [
              _buildHeader(context, appState),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: [
                    _buildSectionTitle('Principal'),
                    _buildMenuItem(
                      icon: Icons.dashboard_outlined,
                      label: 'Dashboard',
                      route: '/dashboard',
                      context: context,
                      color: Colors.blue,
                    ),
                    _buildMenuItem(
                      icon: Icons.payments,
                      label: 'Empréstimos',
                      route: '/loans',
                      context: context,
                      color: Colors.green,
                    ),
                    _buildMenuItem(
                      icon: Icons.people_outline,
                      label: 'Clientes',
                      route: '/clientes',
                      context: context,
                      color: Colors.orange,
                    ),
                    _buildMenuItem(
                      icon: Icons.monetization_on_outlined,
                      label: 'Pagamentos',
                      route: '/pagamentos',
                      context: context,
                      color: Colors.purple,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Gestão'),
                    _buildMenuItem(
                      icon: Icons.assessment_outlined,
                      label: 'Relatórios',
                      route: '/relatorios',
                      context: context,
                      color: Colors.teal,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Sistema'),
                    _buildMenuItem(
                      icon: Icons.security_outlined,
                      label: 'Segurança',
                      route: '/seguranca',
                      context: context,
                      color: Colors.red,
                    ),
                    _buildMenuItem(
                      icon: Icons.settings_outlined,
                      label: 'Configurações',
                      route: '/configuracoes',
                      context: context,
                      color: Colors.blueGrey,
                    ),
                    _buildMenuItem(
                      icon: Icons.support_agent_outlined,
                      label: 'Suporte',
                      route: '/suporte',
                      context: context,
                      color: Colors.cyan,
                    ),
                  ],
                ),
              ),
              _buildFooter(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AppState appState) {
    final userName = appState.username;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.blue.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Facilite+',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Gestão de Empréstimos',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required String route,
    required BuildContext context,
    required Color color,
  }) {
    final isSelected = ModalRoute.of(context)?.settings.name == route;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          width: 1,
        ),
      ),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        leading: Icon(
          icon,
          color: isSelected ? color : Colors.white54,
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 14,
          ),
        ),
        onTap: () {
          Navigator.pushReplacementNamed(context, route); // Alterado
        },
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Consumer<AppState>(
        builder: (context, appState, child) {
        final userName = appState.username;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue,
                child: Text(
                  userName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Administrador',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () async {
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Sair do Sistema'),
                      content: const Text('Tem certeza que deseja sair?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Sair'),
                        ),
                      ],
                    ),
                  );

                  if (shouldLogout == true) {
                    await appState.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/login',
                            (route) => false,
                      );
                    }
                  }
                },
                icon: const Icon(
                  Icons.logout,
                  color: Colors.white54,
                  size: 20,
                ),
                tooltip: 'Sair do Sistema',
              ),
            ],
          ),
        );
        },
    );
  }
}