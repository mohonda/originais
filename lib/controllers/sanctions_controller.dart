import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:originais/services/my_supabase_client_service.dart';
import 'package:originais/models/sanctions_model.dart';

class SanctionsController {
  // Notifiers para controle de estado reativo nas telas (ValueListenableBuilder)
  
  final mySupabaseClient = getItMySupabaseClient<MySupabaseClient>();
  late SupabaseClient supabaseClient;

  final ValueNotifier<List<SanctionsModel>>
    sanctionsNotifier = ValueNotifier<List<SanctionsModel>>([]);
  
  final ValueNotifier<bool>
    loadingNotifier = ValueNotifier<bool>(false);
  
  final ValueNotifier<String?>
    errorNotifier = ValueNotifier<String?>(null);

  
  // ==========================================
  SanctionsController(){
    supabaseClient = mySupabaseClient.getSupabaseClient();
  }
  
  // ==========================================
  void dispose() {
    loadingNotifier.dispose();
    sanctionsNotifier.dispose();
  }

  // ==========================================
  Future<void> loadSanctions(String hldId) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;


      final resposta = await mySupabaseClient.safePostgrestCall(
        () => supabaseClient
          .from('sanctions')
          .select()
          .eq('san_hld_id', hldId)
      );

      sanctionsNotifier.value =  resposta.map((item) =>
        SanctionsModel.fromJson(item)).toList();
    } catch (e, stackTrace) {
      sanctionsNotifier.value = [];
      errorNotifier.value = 'loadSanctions: $e \n$stackTrace';
    } finally {
      loadingNotifier.value = false;
    }
  }

}