import 'package:flutter/material.dart';

class AppCalendarTheme {
  static ThemeData calendarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      colorScheme: ColorScheme.dark(
        primary: Colors.blue[400]!,
        onPrimary: Colors.white,
        surface: const Color(0xFF2D2D2D),
        onSurface: Colors.grey[300]!,
        secondary: Colors.blue[300]!,
        background: const Color(0xFF1A1A1A),
      ),
      dialogBackgroundColor: const Color(0xFF1A1A1A),
      scaffoldBackgroundColor: const Color(0xFF1A1A1A),
      canvasColor: const Color(0xFF1A1A1A),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.blue[300],
        ),
      ),

    );
  }
}