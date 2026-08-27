
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gorouter_exemplo/services/my_supabase_client_service.dart';
import 'package:gorouter_exemplo/models/payment_value.dart';

final getItBdPaymentValueController = GetIt.instance;

void setupGetItBdPaymentValueController() {
  getItBdPaymentValueController.registerLazySingleton<BdPaymentValueController>(
    () => BdPaymentValueController(),
  );
}

class BdPaymentValueController extends ChangeNotifier {
  final mySupabaseClient = getItMySupabaseClient<MySupabaseClient>();
  late SupabaseClient supabaseClient;
 
  final ValueNotifier<List<PaymentValueModel>> bdPaymentValueNotifier =
    ValueNotifier<List<PaymentValueModel>>([]);

  final ValueNotifier<bool> loadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);
  
  // ==========================================
  BdPaymentValueController() {
    supabaseClient = mySupabaseClient.getSupabaseClient();
  }

  // ==========================================
  Future<void> loadPaymentValue() async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final resposta = await mySupabaseClient.safePostgrestCall(()=>
        supabaseClient
        .from('valor_pagamento')
        .select()
      );
    
      bdPaymentValueNotifier.value = resposta.map(
        ( item ) => PaymentValueModel.fromJson( item )
      ).toList();
      
    } catch (e, stackTrace) {
      bdPaymentValueNotifier.value = [];
      errorNotifier.value = ("BdPaymentValueController::loadPaymentValue: $e \n$stackTrace");
    } finally {
      loadingNotifier.value = false;
    }
  }

}
