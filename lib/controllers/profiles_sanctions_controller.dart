import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:originais/models/profiles_sanctions_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:originais/services/my_supabase_client_service.dart';
import 'package:originais/models/sanction_model.dart';
import 'package:originais/controllers/open_bar_ticket_ticketitem_controller.dart';

final getItBdVProfilesSanctionsController = GetIt.instance;

void setupGetItBdVProfilesSanctionsController() {
  getItBdVProfilesSanctionsController
      .registerFactory<BdVProfilesSanctionsController>(
        () => BdVProfilesSanctionsController(),
      );
}

class BdVProfilesSanctionsController extends ChangeNotifier {
  final mySupabaseClient = getItMySupabaseClient<MySupabaseClient>();
  late SupabaseClient supabaseClient;

  // Canal do Supabase para escuta em tempo real
  RealtimeChannel? _sanctionsChannel;

  final ValueNotifier<List<VProfilesSanctionsModel>>
  vProfilesSanctionsNotifier = ValueNotifier<List<VProfilesSanctionsModel>>([]);

  final ValueNotifier<List<SanctionModel>> sanctionsNotifier =
      ValueNotifier<List<SanctionModel>>([]);

  final ValueNotifier<bool> loadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);

  // ==========================================
  BdVProfilesSanctionsController() {
    supabaseClient = mySupabaseClient.getSupabaseClient();
  }

  // ==========================================
  // Inicia a escuta Realtime para alterações na tabela profiles_sanctions
  void subscribeToRealtime(String pflId, String hldId) {
    // Remove inscrição anterior se houver
    unsubscribeRealtime();

    _sanctionsChannel = supabaseClient
        .channel('public:profiles_sanctions:pfl_$pflId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all, // Ouve INSERT, UPDATE e DELETE
          schema: 'public',
          table: 'profiles_sanctions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'psan_pfl_id',
            value: pflId,
          ),
          callback: (payload) {
            // Sempre que houver mudança feita por QUALQUER instância, recarrega a View
            loadProfileSanctionsStatus(pflId, hldId);
          },
        )
        .subscribe();
  }

  // Cancela a inscrição do canal
  void unsubscribeRealtime() {
    if (_sanctionsChannel != null) {
      supabaseClient.removeChannel(_sanctionsChannel!);
      _sanctionsChannel = null;
    }
  }

  // ==========================================
  Future<void> loadProfileSanctionsStatus(String pflId, String hldId) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final resposta = await mySupabaseClient.safePostgrestCall(
        () => supabaseClient
            .from('vprofiles_sanctions')
            .select()
            .eq('psan_pfl_id', pflId)
            .eq('psan_hld_id', hldId),
      );

      vProfilesSanctionsNotifier.value = resposta
          .map((item) => VProfilesSanctionsModel.fromJson(item))
          .toList();
    } catch (e, stackTrace) {
      vProfilesSanctionsNotifier.value = [];
      errorNotifier.value = "loadProfileSanctionsStatus: $e \n$stackTrace";
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<List<SanctionModel>> loadAvailableSanctions(String hld) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final resposta = await mySupabaseClient.safePostgrestCall(
        () => supabaseClient
          .from('sanctions')
          .select()
          .eq('san_hld_id', hld),
      );

      sanctionsNotifier.value = resposta
          .map((item) => SanctionModel.fromMap(item))
          .toList();

      return sanctionsNotifier.value;
    } catch (e, stackTrace) {
      errorNotifier.value = "loadAvailableSanctions: $e \n$stackTrace";
      return sanctionsNotifier.value = [];
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> insertProfileSanction(
    String psanPflId,
    String pflName,
    String psanHldId,
    String psanSanId,
    String psanValor,
    String psanDateStart,
    String psanDateEnd,
    String psanDesc,
  ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      await mySupabaseClient.safePostgrestCall(
        () => supabaseClient
        .from('profiles_sanctions')
        .insert({
          'psan_pfl_id': psanPflId,
          'psan_hld_id': psanHldId,
          'psan_san_id': psanSanId,
          'psan_valor': psanValor,
          'psan_date_start': psanDateStart,
          'psan_date_end': psanDateEnd,
          'psan_desc': psanDesc,
        })
      );
      
      final openTicket = OpenBarTicketTicketitemController();
      openTicket.openBarTicketTicketitem(
        p_hld_id: psanHldId,
        p_pfl_id: psanPflId,
        p_pfl_name: pflName,
        p_date_start: psanDateStart,
        p_desc: psanDesc,
        p_tss_id: '3',
        p_table_number: '-1',
        p_pdt_id: '32',
        p_pdt_quant: '1',
        p_valor: psanValor,
        p_tkt_vpg_id: '',
        p_tkt_pas_id: '',
      );

      // Não é necessário chamar loadProfileSanctionsStatus aqui, pois o Realtime reage ao INSERT
    } catch (e, stackTrace) {
      errorNotifier.value = "insertProfileSanction: $e \n$stackTrace";
      debugPrint(errorNotifier.value.toString());
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> updateProfileSanction(
    String psanid,
    String psanPflId,
    String psanHldIid,
    String psanSanId,
    String psanValor,
    String psanDateStart,
    String psanDateEnd,
    String psanDesc,
  ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      await mySupabaseClient.safePostgrestCall(
        () => supabaseClient.from('profiles_sanctions')
          .update({
            'psan_san_id': psanSanId,
            'psan_valor': psanValor,
            'psan_date_start': psanDateStart,
            'psan_date_end': psanDateEnd,
            'psan_desc': psanDesc
          })
          .eq('psan_id', psanid)
      );
    } catch (e, stackTrace) {
      errorNotifier.value = "updateProfileSanction: $e \n$stackTrace";
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> deleteProfileSanction(
    String psanid,
    String psanPflId,
    String psanHldIid,
  ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      await mySupabaseClient.safePostgrestCall(
        () => supabaseClient.from('profiles_sanctions')
          .delete()
          .eq('psan_id', psanid)
      );
    } catch (e, stackTrace) {
      errorNotifier.value = "deleteProfileSanction: $e \n$stackTrace";
    } finally {
      loadingNotifier.value = false;
    }
  }

  @override
  void dispose() {
    unsubscribeRealtime();
    vProfilesSanctionsNotifier.dispose();
    sanctionsNotifier.dispose();
    loadingNotifier.dispose();
    errorNotifier.dispose();
    super.dispose();
  }
}