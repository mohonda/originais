
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:originais/services/my_supabase_client_service.dart';
import 'package:originais/models/vprofile_associatestatus_model.dart';

final getItBdVProfileAssociateStatusController = GetIt.instance;

void setupGetItBdVProfileAssociateStatusController() {
  getItBdVProfileAssociateStatusController.registerLazySingleton<BdVProfileAssociateStatusController>(
    () => BdVProfileAssociateStatusController(),
  );
}

class BdVProfileAssociateStatusController extends ChangeNotifier {
  final mySupabaseClient = getItMySupabaseClient<MySupabaseClient>();
  late SupabaseClient supabaseClient;
 
  final ValueNotifier<List<VProfileAssociateStatusModel>> vProfileAssociateStatusNotifier =
    ValueNotifier<List<VProfileAssociateStatusModel>>([]);

  final ValueNotifier<bool> loadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);
  
  // ==========================================
  BdVProfileAssociateStatusController() {
    supabaseClient = mySupabaseClient.getSupabaseClient();
  }

  // ==========================================
  Future<void> loadProfileAssociateStatus( String id, String hld ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final resposta = await mySupabaseClient.safePostgrestCall(()=>
        supabaseClient
        .from('vprofile_associatestatus')
        .select()
        .eq('pas_pfl_id', id)
        .eq('pas_hld_id', hld)
      );
    
      vProfileAssociateStatusNotifier.value = resposta.map(
        ( item ) => VProfileAssociateStatusModel.fromJson( item )
      ).toList();
      
    } catch (e, stackTrace) {
      vProfileAssociateStatusNotifier.value = [];
      errorNotifier.value = ("BdItemController::loadItems: $e \n$stackTrace");
    } finally {
      loadingNotifier.value = false;
    }
  }

}
