// lib/main.dart
import 'package:facilite/data/models/emprestimo.dart';
import 'package:facilite/data/models/simulacao.dart';
import 'package:facilite/screens/emprestimo/criar_emprestimo.dart';
import 'package:facilite/screens/emprestimo/detalhes_emprestimo_screen.dart';
import 'package:facilite/screens/emprestimo/emprestimos_screen.dart';
import 'package:facilite/screens/seguranca/seguranca_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:facilite/app/app_state.dart';
import 'package:facilite/screens/login/recover_password_screen.dart';
import 'package:facilite/screens/login/reset_password_screen.dart';
import 'package:facilite/screens/simulacao/simulacao_emprestimo.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/login/login_screen.dart';
import 'package:facilite/screens/dashboard/dashboard_screen.dart';
import 'package:facilite/screens/emprestimo/editar_emprestimo_screen.dart';

void main() async {
  // Inicializar o Sqflite para ambientes de desktop
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Configuração inicial do Flutter e janelas
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 720),
    center: true,
    title: 'Facilite+',
    titleBarStyle: TitleBarStyle.normal,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.maximize();
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Facilite+',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white70),
          bodyMedium: TextStyle(color: Colors.white),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[800],
          labelStyle: const TextStyle(color: Colors.white70),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white38),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.blue),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      initialRoute: '/dashboard',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/simulacao':
            final simulacao = settings.arguments as Simulacao?;
            return MaterialPageRoute(
              builder: (context) => SimulacaoEmprestimoScreen(simulacao: simulacao),
            );
          case '/criar-emprestimo':
            final simulacao = settings.arguments as Simulacao?;
            return MaterialPageRoute(
              builder: (context) => CriarEmprestimoScreen(simulacao: simulacao),
            );
          case '/detalhes-emprestimo':
            if (settings.arguments is Emprestimo) {
              final emprestimo = settings.arguments as Emprestimo;
              return MaterialPageRoute(
                builder: (context) => DetalhesEmprestimoScreen(emprestimo: emprestimo),
              );
            } else {
              return MaterialPageRoute(
                builder: (context) => const Scaffold(
                  body: Center(child: Text('Erro: Empréstimo inválido')),
                ),
              );
            }
          case '/editar-emprestimo':
            final emprestimo = settings.arguments as Emprestimo;
            return MaterialPageRoute(
              builder: (context) => EditarEmprestimoScreen(emprestimo: emprestimo),
            );

          default:
            return null;
        }
      },
      routes: {
        '/dashboard': (context) => DashboardScreen(),
        '/recover-password': (context) => RecoverPasswordScreen(),
        '/reset-password': (context) => ResetPasswordScreen(),
        '/login': (context) => LoginScreen(),
        '/loans': (context) => EmprestimosScreen(),
        '/seguranca': (context) => SegurancaScreen(),
      },
    );
  }
}