import 'package:flutter/material.dart';

class AppConstants {
  // Textos padrões
  static const String appTitle = 'Emprestafácil';
  static const String adminUser = 'admin';
  static const String defaultUserName = 'Usuário';
  static const String defaultErrorMessage = 'Ocorreu um erro inesperado.';
  static const String defaultSuccessMessage = 'Operação realizada com sucesso!';
  static const String defaultLoadingMessage = 'Carregando...';

  // Rotas
  static const String routeLogin = '/login';
  static const String routeDashboard = '/dashboard';
  static const String routeRecoverPassword = '/recover-password';
  static const String routeResetPassword = '/reset-password';
  static const String routeSimulacao = '/simulacao';
  static const String routeCriarEmprestimo = '/criar-emprestimo';
  static const String routeLoans = '/loans';
  static const String routeSeguranca = '/seguranca';
  static const String routeDetalhesEmprestimo = '/detalhes-emprestimo';

  // Outros
  static const double defaultCardElevation = 1;
  static const double defaultButtonPadding = 16;
  static const double defaultBorderRadius = 8;
  static const double defaultTextFieldPadding = 8;
  static const double defaultIconSize = 20;
  static const int defaultLimitRecents = 8;

}