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

  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);
  
  // ==========================================
  AssociateStatusController(){
    supabaseClient = mySupabaseClient.getSupabaseClient();
  }

  // ==========================================
  void dispose() {
    loadingNotifier.dispose();
    statusNotifier.dispose();
  }

  // ==========================================
  Future<void> loadAssociateStatus(String hldId) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final resposta = await mySupabaseClient.safePostgrestCall(
        () => supabaseClient
          .from('associate_status')
          .select()
          .eq('as_hld_id', hldId)
      );

      statusNotifier.value =  resposta.map((item) =>
        AssociateStatusModel.fromMap(item)).toList();
    } catch (e, stackTrace) {
      statusNotifier.value = [];
      errorNotifier.value = ('loadAssociateStatus:$e\n$stackTrace');
    } finally {
      loadingNotifier.value = false;
    }
  }

}