
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:originais/services/my_supabase_client_service.dart';
import 'package:originais/models/profile_associate_status_model.dart';
import 'package:originais/models/associate_status_model.dart';
import 'package:originais/controllers/profile_controller.dart';

final getItBdVProfileAssociateStatusController = GetIt.instance;

void setupGetItBdVProfileAssociateStatusController() {
  getItBdVProfileAssociateStatusController.registerLazySingleton<BdVProfileAssociateStatusController>(
    () => BdVProfileAssociateStatusController(),
  );
}

class BdVProfileAssociateStatusController extends ChangeNotifier {
  final mySupabaseClient = getItMySupabaseClient<MySupabaseClient>();
  late SupabaseClient supabaseClient;

  final bdProfileController =
    getItBdProfileController<BdProfileController>();
 
  final ValueNotifier<List<VProfileAssociateStatusModel>> vProfileAssociateStatusNotifier =
    ValueNotifier<List<VProfileAssociateStatusModel>>([]);
  
  final ValueNotifier<List<AssociateStatusModel>> availableAssociateStatus =
    ValueNotifier<List<AssociateStatusModel>>([]);

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

    // ==========================================
  Future<void> insertProfileAssociateStatus(
      String paspflid,
      String pashldid,

      String pasasid,
      String pasdate,
      String? pasmonthlypercent
    ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      await mySupabaseClient.safePostgrestCall(()=>
        supabaseClient
        .from('profile_associatestatus')
        .insert({
          'pas_pfl_id': paspflid,
          'pas_hld_id': pashldid,
          'pas_as_id': pasasid,
          'pas_date': pasdate,
          'pas_monthly_percent': pasmonthlypercent,
        })
      );
      await loadProfileAssociateStatus( paspflid, pashldid );

      await bdProfileController.loadProfiles(pashldid);

      
    } catch (e, stackTrace) {
      errorNotifier.value = ("BdItemController::loadItems: $e \n$stackTrace");
    } finally {
      loadingNotifier.value = false;
    }
  }
    // ==========================================
  Future<void> updateProfileAssociateStatus(
      String pasid,
      String paspflid,
      String pashldid,

      String pasdate,
      String? pasmonthlypercent
    ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      await mySupabaseClient.safePostgrestCall(()=>
        supabaseClient
        .from('profile_associatestatus')
        .update({
          'pas_date': pasdate,
          'pas_monthly_percent': pasmonthlypercent,
        })
        .eq('pas_id', pasid)
      );
      await loadProfileAssociateStatus( paspflid, pashldid );
      await bdProfileController.loadProfiles(pashldid);
      
    } catch (e, stackTrace) {
      errorNotifier.value = ("BdItemController::loadItems: $e \n$stackTrace");
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> deleteProfileAssociateStatus(
      String pasid,
      String paspflid,
      String pashldid,
    ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      await mySupabaseClient.safePostgrestCall(()=>
        supabaseClient
        .from('profile_associatestatus')
        .delete()
        .eq('pas_id', pasid)
      );
      await loadProfileAssociateStatus( paspflid, pashldid );
      await bdProfileController.loadProfiles(pashldid);
      
    } catch (e, stackTrace) {
      errorNotifier.value = ("BdItemController::loadItems: $e \n$stackTrace");
    } finally {
      loadingNotifier.value = false;
    }
  }

}
