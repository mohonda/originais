import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:originais/services/my_supabase_client_service.dart';
import 'package:originais/models/vexecutive_committee_termofoffice_members_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:originais/models/executiveCommitteeVacancyModel.dart';

final getItBdVExecutiveCommitteeTermOfOfficeMembersController = GetIt.instance;

void setupGetItBdVExecutiveCommitteeTermOfOfficeMembersController() {
  getItBdVExecutiveCommitteeTermOfOfficeMembersController
      .registerFactory<BdVExecutiveCommitteeTermOfOfficeMembersController>(
        () => BdVExecutiveCommitteeTermOfOfficeMembersController(),
      );
}

class BdVExecutiveCommitteeTermOfOfficeMembersController
    extends ChangeNotifier {
  final mySupabaseClient = getItMySupabaseClient<MySupabaseClient>();
  late SupabaseClient supabaseClient;

  final ValueNotifier<List<VExecutiveCommitteeTermOfOfficeMembersModel>>
  vExecutiveCommitteeTermOfOfficeMembersNotifier =
      ValueNotifier<List<VExecutiveCommitteeTermOfOfficeMembersModel>>([]);

  final ValueNotifier<List<VExecutiveCommitteeTermOfOfficeMembersModel>>
  executiveOrderByDateStart =
      ValueNotifier<List<VExecutiveCommitteeTermOfOfficeMembersModel>>([]);

  final ValueNotifier<bool> loadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);

  // ==========================================
  BdVExecutiveCommitteeTermOfOfficeMembersController() {
    supabaseClient = mySupabaseClient.getSupabaseClient();
  }

  // ==========================================
  Future<void> loadExecutiveCommitteeTermOfOfficeMembers(
    String id,
    String hld,
  ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final resposta = await mySupabaseClient.safePostgrestCall(
        () => supabaseClient
            .from('vexecutive_committee_termofoffice_members')
            .select()
            .eq('ectm_pfl_id', id)
            .eq('ectm_hld_id', hld),
      );

      vExecutiveCommitteeTermOfOfficeMembersNotifier.value = resposta
          .map(
            (item) =>
                VExecutiveCommitteeTermOfOfficeMembersModel.fromJson(item),
          )
          .toList();
    } catch (e, stackTrace) {
      vExecutiveCommitteeTermOfOfficeMembersNotifier.value = [];
      errorNotifier.value =
          ("BdVProfilesSanctionsController::loadProfileSanctionsStatus: $e \n$stackTrace");
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> loadExecutiveOrderByDateStart(String id, String hld) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final resposta = await mySupabaseClient.safePostgrestCall(
        () => supabaseClient
            .from('vexecutive_committee_termofoffice_members')
            .select()
            .eq('ectm_pfl_id', id)
            .eq('ectm_hld_id', hld)
            .order('ectm_date_start', ascending: false),
      );

      executiveOrderByDateStart.value = resposta
          .map(
            (item) =>
                VExecutiveCommitteeTermOfOfficeMembersModel.fromJson(item),
          )
          .toList();
    } catch (e, stackTrace) {
      executiveOrderByDateStart.value = [];
      errorNotifier.value =
          ("BdVProfilesSanctionsController::loadProfileSanctionsStatus: $e \n$stackTrace");
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> deleteExecutiveCommitteeMember(
    String ectmId,
    String pflId,
    String hldId,
  ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      await mySupabaseClient.safePostgrestCall(
        () => supabaseClient
            .from('executive_committee_termofoffice_members')
            .delete()
            .eq('ectm_id', ectmId),
      );

      // await loadExecutiveOrderByDateStart( pflId, hldId );
    } catch (e, stackTrace) {
      errorNotifier.value =
          ("BdVProfilesSanctionsController::loadProfileSanctionsStatus: $e \n$stackTrace");
      debugPrint('$e \n$stackTrace');
    } finally {
      loadingNotifier.value = false;
    }
  }
  
  // ==========================================
  Future<void> insertExecutiveCommitteeMember(
    String ect_id,
    String ectm_ecm_id,
    String ectm_pfl_id,
    String ectm_hld_id,
    String date_start,
    String motivo_saida,
  ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      await mySupabaseClient.safePostgrestCall(
        () => supabaseClient
            .from('executive_committee_termofoffice_members')
            .insert({
              'ectm_ect_id': ect_id,
              'ectm_ecm_id': ectm_ecm_id,
              'ectm_pfl_id': ectm_pfl_id,
              'ectm_hld_id': ectm_hld_id,
              'date_start': date_start,
              'motivo_saida': motivo_saida
            })
      );

      // await loadExecutiveOrderByDateStart( pflId, hldId );
    } catch (e, stackTrace) {
      errorNotifier.value =
          ("BdVProfilesSanctionsController::loadProfileSanctionsStatus: $e \n$stackTrace");
      debugPrint('$e \n$stackTrace');
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<List<ExecutiveCommitteeVacancyModel>> loadExecutiveCommitteeVacancy(
    String hldIid,
  ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final resposta = await mySupabaseClient.safePostgrestCall(
        () => supabaseClient
            .from('vexecutive_committee_vacancy')
            .select()
            .eq('ecm_hld_id', hldIid),
      );

      if (resposta == null) return [];

      // 2. Garante que a resposta é tratada como uma Lista
      final List<dynamic> rawList = resposta as List<dynamic>;

      // 3. Mapeamento Seguro (Iterable -> List<ExecutiveCommitteeVacancyModel>)
      final List<ExecutiveCommitteeVacancyModel> cargosVagos = rawList
          .map(
            (item) =>
                ExecutiveCommitteeVacancyModel.fromMap(item as Map<String, dynamic>),
          )
          .toList(); // ⚠️ Não esqueça o .toList() ao final!

      return cargosVagos;
    } catch (e, stackTrace) {
      vExecutiveCommitteeTermOfOfficeMembersNotifier.value = [];
      errorNotifier.value =
          ("BdVProfilesSanctionsController::loadProfileSanctionsStatus: $e \n$stackTrace");
      return [];
    } finally {
      loadingNotifier.value = false;
    }
  }
}


