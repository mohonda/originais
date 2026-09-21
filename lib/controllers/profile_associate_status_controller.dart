import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:originais/services/my_supabase_client_service.dart';
import 'package:originais/models/profile_associate_status_model.dart';
import 'package:originais/models/associate_status_model.dart';
import 'package:originais/controllers/profile_controller.dart';

final getItBdVProfileAssociateStatusController = GetIt.instance;

void setupGetItBdVProfileAssociateStatusController() {
  getItBdVProfileAssociateStatusController.registerFactory<BdVProfileAssociateStatusController>(
    () => BdVProfileAssociateStatusController(),
  );
}

class BdVProfileAssociateStatusController extends ChangeNotifier {
  final mySupabaseClient = getItMySupabaseClient<MySupabaseClient>();
  late SupabaseClient supabaseClient;

  final bdProfileController =
    getItBdProfileController<BdProfileController>();

  // Canal do Supabase para escuta Realtime
  RealtimeChannel? _associateStatusChannel;
  
  final ValueNotifier<List<AssociateStatusModel>> 
    statusNotifier = ValueNotifier<List<AssociateStatusModel>>([]);
 
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
  // Inicia a escuta Realtime na tabela profile_associatestatus
  void subscribeToRealtime(String pflId, String hldId) {
    unsubscribeRealtime();

    _associateStatusChannel = supabaseClient
        .channel('public:profile_associatestatus:pfl_$pflId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all, // Escuta INSERT, UPDATE e DELETE
          schema: 'public',
          table: 'profile_associatestatus',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'pas_pfl_id',
            value: pflId,
          ),
          callback: (payload) async {
            // Recarrega o estado do perfil e a lista geral de perfis ao detetar alterações
            await loadProfileAssociateStatus(pflId, hldId);
            await bdProfileController.loadProfiles(hldId);
          },
        )
        .subscribe();
  }

  // Cancela a subscrição do canal Realtime
  void unsubscribeRealtime() {
    if (_associateStatusChannel != null) {
      supabaseClient.removeChannel(_associateStatusChannel!);
      _associateStatusChannel = null;
    }
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

      statusNotifier.value = resposta.map((item) =>
        AssociateStatusModel.fromMap(item)).toList();
    } catch (e, stackTrace) {
      statusNotifier.value = [];
      errorNotifier.value = ('loadAssociateStatus:$e\n$stackTrace');
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> loadProfileAssociateStatus(String id, String hld) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final resposta = await mySupabaseClient.safePostgrestCall(() =>
        supabaseClient
        .from('vprofile_associatestatus')
        .select()
        .eq('pas_pfl_id', id)
        .eq('pas_hld_id', hld)
        .order('pas_date', ascending: false)
      );
    
      vProfileAssociateStatusNotifier.value = resposta.map(
        (item) => VProfileAssociateStatusModel.fromJson(item)
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

      await mySupabaseClient.safePostgrestCall(() =>
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
      
      // O Realtime irá tratar da atualização automática da interface
    } catch (e, stackTrace) {
      errorNotifier.value = "insertProfileAssociateStatus: $e \n$stackTrace";
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

      await mySupabaseClient.safePostgrestCall(() =>
        supabaseClient
        .from('profile_associatestatus')
        .update({
          'pas_date': pasdate,
          'pas_monthly_percent': pasmonthlypercent,
        })
        .eq('pas_id', pasid)
      );

      // O Realtime irá tratar da atualização automática da interface
    } catch (e, stackTrace) {
      errorNotifier.value = "updateProfileAssociateStatus: $e \n$stackTrace";
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

      await mySupabaseClient.safePostgrestCall(() =>
        supabaseClient
        .from('profile_associatestatus')
        .delete()
        .eq('pas_id', pasid)
      );

      // O Realtime irá tratar da atualização automática da interface
    } catch (e, stackTrace) {
      errorNotifier.value = "deleteProfileAssociateStatus: $e \n$stackTrace";
    } finally {
      loadingNotifier.value = false;
    }
  }

  @override
  void dispose() {
    unsubscribeRealtime();
    statusNotifier.dispose();
    vProfileAssociateStatusNotifier.dispose();
    availableAssociateStatus.dispose();
    loadingNotifier.dispose();
    errorNotifier.dispose();
    super.dispose();
  }
}