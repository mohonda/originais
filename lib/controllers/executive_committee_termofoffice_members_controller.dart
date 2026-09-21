import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:originais/services/my_supabase_client_service.dart';
import 'package:originais/models/executive_committee_termofoffice_members_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:originais/models/executive_committee_vacancy_model.dart';

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

  // Canal do Supabase para escuta Realtime
  RealtimeChannel? _executiveCommitteeChannel;

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
  // Inicia a escuta Realtime na tabela executive_committee_termofoffice_members
  void subscribeToRealtime(String pflId, String hldId) {
    unsubscribeRealtime();

    _executiveCommitteeChannel = supabaseClient
        .channel('public:executive_committee_termofoffice_members:pfl_$pflId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all, // Ouve INSERT, UPDATE e DELETE
          schema: 'public',
          table: 'executive_committee_termofoffice_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'ectm_pfl_id',
            value: pflId,
          ),
          callback: (payload) async {
            // Atualiza os membros da diretoria executiva em tempo real
            await loadExecutiveOrderByDateStart(pflId, hldId);
          },
        )
        .subscribe();
  }

  // Cancela a subscrição do canal Realtime
  void unsubscribeRealtime() {
    if (_executiveCommitteeChannel != null) {
      supabaseClient.removeChannel(_executiveCommitteeChannel!);
      _executiveCommitteeChannel = null;
    }
  }

  // ==========================================
  Future<void> loadExecutiveOrderByDateStart(String pflId, String hldId) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final resposta = await mySupabaseClient.safePostgrestCall(
        () => supabaseClient
            .from('vexecutive_committee_termofoffice_members')
            .select()
            .eq('ectm_pfl_id', pflId)
            .eq('ectm_hld_id', hldId)
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
          "loadExecutiveOrderByDateStart: $e \n$stackTrace";
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

      // O Realtime atualizará a interface em todas as instâncias
    } catch (e, stackTrace) {
      errorNotifier.value =
          "deleteExecutiveCommitteeMember: $e \n$stackTrace";
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

      // O Realtime atualizará a interface em todas as instâncias
    } catch (e, stackTrace) {
      errorNotifier.value =
          "insertExecutiveCommitteeMember: $e \n$stackTrace";
    } finally {
      loadingNotifier.value = false;
    }
  }
  
  // ==========================================
  Future<void> updateExecutiveCommitteeMember(
    String ectm_id,
    String ectm_pfl_id,
    String ectm_hld_id,
    String date_start,
    String date_end,
    String motivo_saida,
  ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      await mySupabaseClient.safePostgrestCall(
        () => supabaseClient
            .from('executive_committee_termofoffice_members')
            .update({
              'date_start': date_start,
              'date_end': date_end.isNotEmpty ? date_end : null,
              'motivo_saida': motivo_saida
            })
            .eq('ectm_id', ectm_id)
      );

      // O Realtime atualizará a interface em todas as instâncias
    } catch (e, stackTrace) {
      errorNotifier.value =
          "updateExecutiveCommitteeMember: $e \n$stackTrace";
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

      final List<dynamic> rawList = resposta as List<dynamic>;

      final List<ExecutiveCommitteeVacancyModel> 
        cargosVagos = rawList.map(
            (item) => ExecutiveCommitteeVacancyModel.fromMap(item as Map<String, dynamic>),
          ).toList();

      return cargosVagos;
    } catch (e, stackTrace) {
      errorNotifier.value =
          "loadExecutiveCommitteeVacancy: $e \n$stackTrace";
      return [];
    } finally {
      loadingNotifier.value = false;
    }
  }

  @override
  void dispose() {
    unsubscribeRealtime();
    executiveOrderByDateStart.dispose();
    loadingNotifier.dispose();
    errorNotifier.dispose();
    super.dispose();
  }
}