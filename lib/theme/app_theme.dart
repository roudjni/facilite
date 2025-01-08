// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const cardPadding = EdgeInsets.all(16.0);
  static final cardBorderRadius = BorderRadius.circular(12);
  static const textFieldPadding = EdgeInsets.symmetric(vertical: 8.0);

  static final borderSide = BorderSide(
    color: Colors.blue.withOpacity(0.2),
    width: 1,
  );

  static final inputDecoration = InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: borderSide,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: borderSide,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.blue),
    ),
    fillColor: Colors.blue.withOpacity(0.05),
    filled: true,
    labelStyle: TextStyle(color: Colors.white70),
  );
}