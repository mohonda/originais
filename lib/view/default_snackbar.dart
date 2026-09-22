import 'package:flutter/material.dart';

class DefaultSnackbar {
  /// Associa um ValueNotifier<String?> a um SnackBar customizado
  static void attachListener({
    required BuildContext context,
    required ValueNotifier<String?> notifier,
    required Color backgroundColor,
    IconData icon = Icons.info_outline,
    Duration duration = const Duration(seconds: 3),
  }) {
    notifier.addListener(() {
      final message = notifier.value;

      if (message != null && message.isNotEmpty && context.mounted) {
        // Oculta o SnackBar anterior se ainda estiver visível
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: backgroundColor,
            behavior: SnackBarBehavior.floating,
            duration: duration,
          ),
        );

        // Reseta o notifier para permitir novos disparos com a mesma mensagem
        notifier.value = null;
      }
    });
  }

  /// Atalho para mensagens de Erro
  static void attachErrorListener(
    BuildContext context,
    ValueNotifier<String?> notifier,
  ) {
    attachListener(
      context: context,
      notifier: notifier,
      backgroundColor: Colors.red.shade700,
      icon: Icons.error_outline,
    );
  }

  /// Atalho para mensagens de Sucesso
  static void attachSuccessListener(
    BuildContext context,
    ValueNotifier<String?> notifier,
  ) {
    attachListener(
      context: context,
      notifier: notifier,
      backgroundColor: Colors.green.shade800,
      icon: Icons.check_circle_outline,
    );
  }
}