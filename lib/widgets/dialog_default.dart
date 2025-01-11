// lib/widgets/dialog_default.dart

import 'package:flutter/material.dart';

class DialogDefault extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final Widget content;
  final List<Widget> actions;
  final bool isProcessing;

  const DialogDefault({
    Key? key,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.content,
    required this.actions,
    this.isProcessing = false,
  }) : super(key: key);

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color accentColor,
    required Widget content,
    required List<Widget> actions,
    bool isProcessing = false,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return DialogDefault(
          title: title,
          icon: icon,
          accentColor: accentColor,
          content: content,
          actions: actions,
          isProcessing: isProcessing,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accentColor, width: 1),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: content,
      actions: actions,
    );
  }

  // Widgets auxiliares para criar botões padronizados
  static Widget createCancelButton({
    required VoidCallback onPressed,
    bool disabled = false,
  }) {
    return TextButton(
      onPressed: disabled ? null : onPressed,
      child: Text(
        'Cancelar',
        style: TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static Widget createActionButton({
    required String text,
    required Color color,
    required VoidCallback onPressed,
    bool isProcessing = false,
  }) {
    return ElevatedButton(
      onPressed: isProcessing ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: isProcessing
          ? const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      )
          : Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Widget auxiliar para criar campos de texto padronizados
  static Widget createTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    required Color accentColor,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(prefixIcon, color: accentColor),
          suffixIcon: suffixIcon,
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: onChanged,
      ),
    );
  }
}