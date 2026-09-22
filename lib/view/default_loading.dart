import 'package:flutter/material.dart';

class DefaultLoading {
  // Construtor privado para evitar instanciação desnecessária
  DefaultLoading._();

  // ===========================================================================
  // OPÇÃO 1: Widget Inline (para compor telas/layouts no método build)
  // ===========================================================================
  static Widget showProgressIndicator({
    double padding = 32.0,
    double? value
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: CircularProgressIndicator(value: value),
      ),
    );
  }

  // ===========================================================================
  // OPÇÃO 2: Modal Overlay (para bloquear a tela durante requisições assíncronas)
  // ===========================================================================
  static void showOverlay(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PopScope(
        canPop: false, // Impede o usuário de fechar no botão 'Voltar' do Android
        child: Center(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ),
    );
  }

  static void hideOverlay(BuildContext context) {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}