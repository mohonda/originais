import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:originais/models/mensalidades_model.dart';
import 'package:originais/services/general_service.dart';
import 'package:originais/services/my_supabase_client_service.dart';
import 'package:originais/controllers/open_bar_ticket_ticketitem_controller.dart';

final getItbdMonthlyPaymentsController = GetIt.instance;

void setupGetItBdMonthlyPaymentsController() {
  getItbdMonthlyPaymentsController
      .registerLazySingleton<BdMonthlyPaymentsController>(
        () => BdMonthlyPaymentsController(),
      );
}

class BdMonthlyPaymentsController extends ChangeNotifier {
  final mySupabaseClient = getItMySupabaseClient<MySupabaseClient>();
  late SupabaseClient supabaseClient;

  final ValueNotifier<List<MensalidadesModel>> monthlyPaymentsNotifier =
      ValueNotifier<List<MensalidadesModel>>([]);

  final ValueNotifier<MensalidadesModel?> monthlyPaymentsIndividual =
      ValueNotifier<MensalidadesModel?>(null);

  // 🟢 Notifier específico para o histórico do perfil selecionado
  final ValueNotifier<List<MensalidadesModel>> monthlyPaymentsProfileNotifier =
      ValueNotifier<List<MensalidadesModel>>([]);

  final ValueNotifier<bool> loadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);

  final generalService = getItGeneralService<GeneralService>();

  String idConfirmacao = '';
  String nameConfirmacao = '';

  RealtimeChannel? _realtimeChannel;

  // ==========================================
  BdMonthlyPaymentsController() {
    supabaseClient = mySupabaseClient.getSupabaseClient();
    idConfirmacao = mySupabaseClient.getUserId();
  }

  // ==========================================
  void initRealtime(String hldId) {
    disposeRealtime();

    _realtimeChannel = supabaseClient
        .channel('public:mensalidades:$hldId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'mensalidades',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'mes_hld_id',
            value: hldId,
          ),
          callback: (payload) {
            loadCurrentMonthlyPayment(showLoading: false);
          },
        )
        .subscribe();
  }

  // ==========================================
  void disposeRealtime() {
    if (_realtimeChannel != null) {
      supabaseClient.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
    }
  }

  // ==========================================
  Future<void> loadCurrentMonthlyPayment({bool showLoading = true}) async {
    try {
      if (showLoading) loadingNotifier.value = true;
      errorNotifier.value = null;

      final resposta = await mySupabaseClient.safePostgrestCall(
        () => supabaseClient
            .from('vmensalidades_tickets')
            .select()
      );

      monthlyPaymentsNotifier.value = resposta
          .map((item) => MensalidadesModel.fromJson(item))
          .toList();
    } catch (e, stackTrace) {
      monthlyPaymentsNotifier.value = [];
      errorNotifier.value = "loadCurrentMonthlyPayment: $e\n$stackTrace";
    } finally {
      if (showLoading) loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> insertMonthlyGeneration(List<Map<String, dynamic>> filteredList,) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;
      
      final openTicket = OpenBarTicketTicketitemController();

      await Future.wait(
        filteredList.map((item) {
          return openTicket.openBarTicketTicketitem(
            p_hld_id: item['p_hld_id'].toString(),
            p_pfl_id: item['p_pfl_id'],
            p_pfl_name: item['p_pfl_name'],
            p_date_start: item['p_date_start'].toString(),
            p_desc: item['p_desc'],
            p_tss_id: item['p_tss_id'].toString(),
            p_table_number: item['p_table_number'].toString(),
            p_pdt_id: item['p_pdt_id'].toString(),
            p_pdt_quant: item['p_pdt_quant'].toString(),
            p_valor: item['p_valor'].toString(),
            p_tkt_vpg_id: item['p_tkt_vpg_id'].toString(),
            p_tkt_pas_id: item['p_tkt_pas_id'].toString(),
          );
        }),
      );

    } catch (e, stackTrace) {
      monthlyPaymentsIndividual.value = null;
      errorNotifier.value =
          'insertMonthlyGeneration: $e \n$stackTrace';
    } finally {
      loadingNotifier.value = false;
      loadCurrentMonthlyPayment();
    }
  }

  // ==========================================
  Future<void> loadMonthlyPaymentsByProfile(String pflId, String hldId) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final resposta = await mySupabaseClient.safePostgrestCall(
        () => supabaseClient
            .from('vmensalidades')
            .select()
            .eq('mes_hld_id', hldId)
            .eq('mes_pfl_id', pflId)
            .order('mes_ano_referencia', ascending: false)
            .order('mes_mes_referencia', ascending: false)
            .order('mes_pfl_full_name', ascending: false)
      );

      monthlyPaymentsProfileNotifier.value = resposta
          .map((item) => MensalidadesModel.fromJson(item))
          .toList();
    } catch (e, stackTrace) {
      monthlyPaymentsProfileNotifier.value = [];
      errorNotifier.value = "loadMonthlyPaymentsByProfile: $e\n$stackTrace";
    } finally {
      loadingNotifier.value = false;
    }
  }
}
