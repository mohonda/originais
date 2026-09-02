
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:originais/services/my_supabase_client_service.dart';
import 'package:originais/models/vexecutive_committee_termofoffice_members_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final getItBdVExecutiveCommitteeTermOfOfficeMembersController = GetIt.instance;

void setupGetItBdVExecutiveCommitteeTermOfOfficeMembersController() {
  getItBdVExecutiveCommitteeTermOfOfficeMembersController
    .registerLazySingleton<BdVExecutiveCommitteeTermOfOfficeMembersController>(
    () => BdVExecutiveCommitteeTermOfOfficeMembersController(),
  );
}

 
class BdVExecutiveCommitteeTermOfOfficeMembersController extends ChangeNotifier {
  final mySupabaseClient = getItMySupabaseClient<MySupabaseClient>();
  late SupabaseClient supabaseClient;
 
  final ValueNotifier<List<VExecutiveCommitteeTermOfOfficeMembersModel>>
    vExecutiveCommitteeTermOfOfficeMembersNotifier =
    ValueNotifier<List<VExecutiveCommitteeTermOfOfficeMembersModel>>([]);

  final ValueNotifier<bool> loadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);
  
  // ==========================================
  BdVExecutiveCommitteeTermOfOfficeMembersController() {
    supabaseClient = mySupabaseClient.getSupabaseClient();
  }

  // ==========================================
  Future<void> loadExecutiveCommitteeTermOfOfficeMembers( String id, String hld ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final resposta = await mySupabaseClient.safePostgrestCall(()=>
        supabaseClient
        .from('vexecutive_committee_termofoffice_members')
        .select()
        .eq('ectm_pfl_id', id)
        .eq('ectm_hld_id', hld)        
      );
    
      vExecutiveCommitteeTermOfOfficeMembersNotifier.value = resposta.map(
        ( item ) => VExecutiveCommitteeTermOfOfficeMembersModel.fromJson( item )
      ).toList();
      
    } catch (e, stackTrace) {
      vExecutiveCommitteeTermOfOfficeMembersNotifier.value = [];
      errorNotifier.value = ("BdVProfilesSanctionsController::loadProfileSanctionsStatus: $e \n$stackTrace");
    } finally {
      loadingNotifier.value = false;
    }
  }

}
