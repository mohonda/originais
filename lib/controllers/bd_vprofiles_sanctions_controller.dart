
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:gorouter_exemplo/models/vprofiles_sanctions_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gorouter_exemplo/services/my_supabase_client_service.dart';

final getItBdVProfilesSanctionsController = GetIt.instance;

void setupGetItBdVProfilesSanctionsController() {
  getItBdVProfilesSanctionsController.registerLazySingleton<BdVProfilesSanctionsController>(
    () => BdVProfilesSanctionsController(),
  );
}

class BdVProfilesSanctionsController extends ChangeNotifier {
  final mySupabaseClient = getItMySupabaseClient<MySupabaseClient>();
  late SupabaseClient supabaseClient;
 
  final ValueNotifier<List<VProfilesSanctionsModel>> vProfilesSanctionsNotifier =
    ValueNotifier<List<VProfilesSanctionsModel>>([]);

  final ValueNotifier<bool> loadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);
  
  // ==========================================
  BdVProfilesSanctionsController() {
    supabaseClient = mySupabaseClient.getSupabaseClient();
  }

  // ==========================================
  Future<void> loadProfileSanctionsStatus( String id, String hld ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final resposta = await mySupabaseClient.safePostgrestCall(()=>
        supabaseClient
        .from('vprofiles_sanctions')
        .select()
        .eq('psan_pfl_id', id)
        .eq('psan_hld_id', hld)
      );
    
      vProfilesSanctionsNotifier.value = resposta.map(
        ( item ) => VProfilesSanctionsModel.fromJson( item )
      ).toList();
      
    } catch (e, stackTrace) {
      vProfilesSanctionsNotifier.value = [];
      errorNotifier.value = ("BdVProfilesSanctionsController::loadProfileSanctionsStatus: $e \n$stackTrace");
    } finally {
      loadingNotifier.value = false;
    }
  }

}
