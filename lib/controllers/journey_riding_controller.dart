import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:originais/services/my_supabase_client_service.dart';
import 'package:originais/models/journeyriding_model.dart';

final getItBdJourneyRidingController = GetIt.instance;

void setupGetItBdJourneyRidingController() {
  getItBdJourneyRidingController.registerFactory<BdJourneyRidingController>(
    () => BdJourneyRidingController(),
  );
}

class BdJourneyRidingController extends ChangeNotifier {
  final mySupabaseClient = getItMySupabaseClient<MySupabaseClient>();
  late SupabaseClient supabaseClient;

  // Canal do Supabase para escuta Realtime
  RealtimeChannel? _journeyChannel;

  final ValueNotifier<List<JourneyRidingModel>> bdJourneyRidingNotifier =
    ValueNotifier<List<JourneyRidingModel>>([]);
    
  final ValueNotifier<List<JourneyRidingModel>> journeyRidingOrderByLevelNotifier =
    ValueNotifier<List<JourneyRidingModel>>([]);
  
  final ValueNotifier<List<JourneyRidingModel>> vProfileJourneyridingDetaisNotifier =
    ValueNotifier<List<JourneyRidingModel>>([]);

  final ValueNotifier<bool> loadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<String?> successNotifier = ValueNotifier<String?>(null);

  // ==========================================
  BdJourneyRidingController() {
    supabaseClient = mySupabaseClient.getSupabaseClient();
  }

  // ==========================================
  // Subscrição em Tempo Real para a tabela user_journey
  void subscribeToRealtime(String pflId, String hldId) {
    unsubscribeRealtime();

    _journeyChannel = supabaseClient
        .channel('public:user_journey:pfl_$pflId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all, // Ouve INSERT, UPDATE e DELETE
          schema: 'public',
          table: 'user_journey',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'uj_pfl_id',
            value: pflId,
          ),
          callback: (payload) async {
            // Atualiza os detalhes do percurso do perfil
            await loadJourneyRidingDetais(pflId, hldId);
          },
        )
        .subscribe();
  }

  // ==========================================
  void unsubscribeRealtime() {
    if (_journeyChannel != null) {
      supabaseClient.removeChannel(_journeyChannel!);
      _journeyChannel = null;
    }
  }

  // ==========================================
  @override
  void dispose() {
    unsubscribeRealtime();
    bdJourneyRidingNotifier.dispose();
    journeyRidingOrderByLevelNotifier.dispose();
    vProfileJourneyridingDetaisNotifier.dispose();
    loadingNotifier.dispose();
    errorNotifier.dispose();
    super.dispose();
  }

  // ==========================================
  Future<void> loadJourneyRiding(String hld_id) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final resposta = await mySupabaseClient.safePostgrestCall(() =>
        supabaseClient
        .from('v_journey_riding')
        .select()
        .eq('jr_hld_id', hld_id)
      );
      
      bdJourneyRidingNotifier.value = resposta.map((item) =>
        JourneyRidingModel.fromJson(item)).toList();
      
    } catch (e, stackTrace) {
      bdJourneyRidingNotifier.value = [];
      errorNotifier.value = ("loadJourneyRiding: $e \n$stackTrace");
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> loadJourneyRidingOrderByLevel(String hld_id) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final resposta = await mySupabaseClient.safePostgrestCall(() =>
        supabaseClient
        .from('v_journey_riding')
        .select()
        .eq('jr_hld_id', hld_id)
        .order('jr_level', ascending: true)
      );
      
      journeyRidingOrderByLevelNotifier.value = resposta.map((item) =>
        JourneyRidingModel.fromJson(item)).toList();
      
    } catch (e, stackTrace) {
      journeyRidingOrderByLevelNotifier.value = [];
      errorNotifier.value = ("loadJourneyRidingOrderByLevel: $e \n$stackTrace");
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> loadJourneyRidingDetais(String id, String hld) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final resposta = await mySupabaseClient.safePostgrestCall(() =>
        supabaseClient
        .from('vprofile_journeyriding')
        .select()
        .eq('pfl_id', id)
        .eq('hld_id', hld)
        .order('uj_promotion_date', ascending: false)
        .order('pfl_full_name', ascending: true) 
      );
      
      vProfileJourneyridingDetaisNotifier.value = resposta.map((item) =>
        JourneyRidingModel.fromJson(item)).toList();
      
    } catch (e, stackTrace) {
      vProfileJourneyridingDetaisNotifier.value = [];
      errorNotifier.value = ("loadJourneyRidingDetais: $e \n$stackTrace");
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> insertProfileJourneyRiding(
    String ujPflId,
    String ujHldId,
    String ujJrId,
    String ujPromotionDate,
  ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      await supabaseClient
          .from('user_journey')  
          .insert({
            'uj_pfl_id': ujPflId,
            'uj_hld_id': ujHldId,
            'uj_jr_id': ujJrId,
            'uj_promotion_date': ujPromotionDate
          }); 
      
      // O Realtime atualizará a interface em todas as instâncias
    } catch (e, stackTrace) {
      errorNotifier.value = ("insertProfileJourneyRiding: $e \n$stackTrace");
    } finally {
      successNotifier.value = "Journey of the Riding inserted with sucess!";
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> updateProfileJourneyRiding(
    String ujId,
    String ujPflId,
    String ujHldId,
    String ujJrId,
    String ujPromotionDate,
  ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      await supabaseClient
          .from('user_journey')  
          .update({
            'uj_jr_id': ujJrId,
            'uj_promotion_date': ujPromotionDate
          })
          .eq('uj_id', ujId);

      // O Realtime atualizará a interface em todas as instâncias
    } catch (e, stackTrace) {
      errorNotifier.value = ("updateProfileJourneyRiding: $e \n$stackTrace");
    } finally {
      successNotifier.value = "Journey of the Riding updated with sucess!";
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> deleteProfileJourneyRiding(
    String ujId,
    String ujPflId,
    String ujHldId,
  ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      await supabaseClient
          .from('user_journey')  
          .delete()
          .eq('uj_id', ujId);

      // O Realtime atualizará a interface em todas as instâncias
    } catch (e, stackTrace) {
      errorNotifier.value = ("deleteProfileJourneyRiding: $e \n$stackTrace");
    } finally {
      successNotifier.value = "Journey of the Riding deleted with sucess!";
      loadingNotifier.value = false;
    }
  }

}