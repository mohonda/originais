import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:gorouter_exemplo/models/formapagamento_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gorouter_exemplo/services/my_supabase_client_service.dart';
final getItBdFormaPagamentoController = GetIt.instance;

void setupGetItBdFormaPagamentoController() {
  getItBdFormaPagamentoController.registerLazySingleton<BdFormaPagamentoController>(
    () => BdFormaPagamentoController(),
  );
}

class BdFormaPagamentoController extends ChangeNotifier {
  final mySupabaseClient = getItMySupabaseClient<MySupabaseClient>();
  late SupabaseClient supabaseClient;

  final ValueNotifier<List<FormaPagamentoModel>> formaPagamentoNotifier =
    ValueNotifier<List<FormaPagamentoModel>>([]);

  final ValueNotifier<bool> loadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);

  // ==========================================
  BdFormaPagamentoController() {
    supabaseClient = mySupabaseClient.getSupabaseClient();
  }

  // ==========================================
  Future<void> loadFormaPagamento() async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final resposta = await supabaseClient
        .from('forma_pagamento')
        .select();

    formaPagamentoNotifier.value = resposta.map((item) =>
      FormaPagamentoModel.fromJson(item)).toList();

    } catch (e, stackTrace) {
      formaPagamentoNotifier.value = [];
      errorNotifier.value = "BdFormaPagamentoController::loadFormaPagamento: $e\n$stackTrace";
    } finally {
      loadingNotifier.value = false;
    }
  }

}
