import 'package:flutter/material.dart';
import 'package:originais/models/associate_status_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:originais/services/my_supabase_client_service.dart';

class AssociateStatusController {
  final mySupabaseClient = getItMySupabaseClient<MySupabaseClient>();
  late SupabaseClient supabaseClient;

  final ValueNotifier<bool> loadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<List<AssociateStatusModel>> 
    statusNotifier = ValueNotifier<List<AssociateStatusModel>>([]);
  
  AssociateStatusController(){
    supabaseClient = mySupabaseClient.getSupabaseClient();
  }

  Future<void> loadAssociateStatus(String hldId) async {
    if (hldId.trim().isEmpty) {
      statusNotifier.value = [];
      return;
    }

    try {
      loadingNotifier.value = true;

      final resposta = await mySupabaseClient.safePostgrestCall(
        () => supabaseClient
          .from('associate_status')
          .select()
          .eq('as_hld_id', hldId)
      );

      statusNotifier.value =  resposta.map((item) =>
        AssociateStatusModel.fromMap(item)).toList();
    } catch (e) {
      debugPrint('❌ Erro ao carregar Associate Status: $e');
      statusNotifier.value = [];
    } finally {
      loadingNotifier.value = false;
    }
  }

  void dispose() {
    loadingNotifier.dispose();
    statusNotifier.dispose();
  }
}