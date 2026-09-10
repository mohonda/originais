import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:originais/services/my_supabase_client_service.dart';
import 'package:originais/models/sanctions_model.dart';

class SanctionsController {
  // Notifiers para controle de estado reativo nas telas (ValueListenableBuilder)
  
  final mySupabaseClient = getItMySupabaseClient<MySupabaseClient>();
  late SupabaseClient supabaseClient;

  final ValueNotifier<bool> loadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<List<SanctionsModel>> sanctionsNotifier = ValueNotifier<List<SanctionsModel>>([]);
  
  SanctionsController(){
    supabaseClient = mySupabaseClient.getSupabaseClient();
  }
  
  /// Carrega as sanções cadastradas para a Holding (hld_id)
  Future<void> loadSanctions(String hldId) async {
    if (hldId.trim().isEmpty) {
      sanctionsNotifier.value = [];
      return;
    }

    try {
      loadingNotifier.value = true;

      // 🟢 Execute a consulta no seu Banco de Dados / Supabase / API aqui.
      // Exemplo com Supabase:
      final resposta = await mySupabaseClient.safePostgrestCall(
        () => supabaseClient
          .from('sanctions')
          .select()
          .eq('san_hld_id', hldId)
          // .order('san_name', ascending: true)
      );

      sanctionsNotifier.value =  resposta.map((item) =>
        SanctionsModel.fromJson(item)).toList();
    } catch (e) {
      debugPrint('❌ Erro ao carregar sanções: $e');
      sanctionsNotifier.value = [];
    } finally {
      loadingNotifier.value = false;
    }
  }

  /// Limpa as instâncias dos ValueNotifiers da memória ao encerrar o controller
  void dispose() {
    loadingNotifier.dispose();
    sanctionsNotifier.dispose();
  }
}