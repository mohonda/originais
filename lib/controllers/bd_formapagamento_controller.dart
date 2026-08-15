import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:gorouter_exemplo/models/formapagamento_model.dart';
import 'package:gorouter_exemplo/services/bd_formapagamento_service.dart';

final getItBdFormaPagamentoController = GetIt.instance;

void setupGetItBdFormaPagamentoController() {
  getItBdFormaPagamentoController.registerLazySingleton<BdFormaPagamentoController>(
    () => BdFormaPagamentoController(),
  );
}

class BdFormaPagamentoController extends ChangeNotifier {
  final BdFormaPagamentoService bdFormaPagamentoService = BdFormaPagamentoService();

  final ValueNotifier<List<FormaPagamentoModel>> formaPagamentoNotifier =
    ValueNotifier<List<FormaPagamentoModel>>([]);

  final ValueNotifier<bool> loadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);

  Future<void> loadFormaPagamento() async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      formaPagamentoNotifier.value = await bdFormaPagamentoService.loadFormaPagamento();
    } catch (e) {
      formaPagamentoNotifier.value = ([]);
      errorNotifier.value = 'Erro BdFormaPagamentoController::loadFormaPagamento: $e';
    } finally {
      loadingNotifier.value = false;
    }
  }
}
