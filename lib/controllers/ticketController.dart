import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gorouter_exemplo/services/my_supabase_client_service.dart';
import 'package:gorouter_exemplo/models/ticketModel.dart';

final getItTicketController = GetIt.instance;

void setupGetItTicketController() {
  getItTicketController.registerLazySingleton<TicketController>(
    () => TicketController(),
  );
}

class TicketController extends ChangeNotifier {
  final mySupabaseClient = getItMySupabaseClient<MySupabaseClient>();
  late SupabaseClient supabaseClient;

  final ValueNotifier<List<TicketStatusModel>> ticketStatusNotifier =
      ValueNotifier<List<TicketStatusModel>>([]);

  final ValueNotifier<List<TicketsItemsModel>> ticketItemsNotifier =
      ValueNotifier<List<TicketsItemsModel>>([]);

  final ValueNotifier<List<TicketsModel>> ticketNotifier =
      ValueNotifier<List<TicketsModel>>([]);

  final ValueNotifier<bool> loadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);

  // ==========================================
  TicketController() {
    supabaseClient = mySupabaseClient.getSupabaseClient();
  }

  // ==========================================
  Future<void> loadTicketStatus(String hld_id) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final resposta = await mySupabaseClient.safePostgrestCall(
        () => supabaseClient
            .from('ticket_status')
            .select()
            .eq('tst_hld_id', hld_id),
      );

      ticketStatusNotifier.value = resposta
          .map((item) => TicketStatusModel.fromJson(item))
          .toList();
    } catch (e, stackTrace) {
      ticketStatusNotifier.value = [];
      errorNotifier.value =
          ("TicketController::loadProdutos: $e \n$stackTrace");
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> loadTicketsItems(String hld_id) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final resposta = await mySupabaseClient.safePostgrestCall(
        () => supabaseClient
            .from('vtickets_items')
            .select()
            .eq('tit_hld_id', hld_id),
      );

      ticketItemsNotifier.value = resposta
          .map((item) => TicketsItemsModel.fromJson(item))
          .toList();
    } catch (e, stackTrace) {
      ticketItemsNotifier.value = [];
      errorNotifier.value =
          ("TicketController::loadProdutos: $e \n$stackTrace");
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> loadTickets(String openDate, String hld_id) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final resposta = await mySupabaseClient.safePostgrestCall(
        () => supabaseClient
            .from('vtickets')
            .select('''*, vtickets_items(*)''')
            .eq('tkt_bar_open_date', openDate)
            .eq('tkt_hld_id', hld_id),
      );

      ticketNotifier.value = resposta
          .map((item) => TicketsModel.fromJson(item))
          .toList();
    } catch (e, stackTrace) {
      ticketNotifier.value = [];
      errorNotifier.value =
          ("TicketController::loadProdutos: $e \n$stackTrace");
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> openTickets(TicketsModel openTickets) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final resposta = await mySupabaseClient.safePostgrestCall(
        () => supabaseClient
            .from('tickets')
            .insert(openTickets.toJson())
            .select(),
      );

    } catch (e, stackTrace) {
      ticketNotifier.value = [];
      errorNotifier.value =
          ("TicketController::loadProdutos: $e \n$stackTrace");
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<TicketsModel?> openTicketsFunction(TicketsModel openTickets) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final List<dynamic> resposta = await mySupabaseClient.safePostgrestCall(
        () => supabaseClient.rpc(
          'insert_ticket_with_table_number',
          params: {
            'p_hld_id': openTickets.tkt_hld_id.toString(),
            'p_bar_open_date': openTickets.tkt_bar_open_date.toString(),
            'p_client_name': openTickets.tkt_client_name.toString(),
            'p_pfl_id': openTickets.tkt_pfl_id,
            'p_has_discount': openTickets.tkt_has_discount.toString(),
            'p_tst_id': openTickets.tkt_tst_id.toString(),
          },
        ),
      );

      final tmp = TicketsModel.fromJson(resposta.single);
      return tmp;
    } catch (e, stackTrace) {
      ticketNotifier.value = [];
      errorNotifier.value =
          ("TicketController::loadProdutos: $e \n$stackTrace");
      debugPrint("TicketController::loadProdutos: $e \n$stackTrace");
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> closeTicketsWithoutPayment( String tkt_id, String tkt_tst_id ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      await mySupabaseClient.safePostgrestCall(
        () => supabaseClient
          .from('tickets')
          .update({'tkt_tst_id': tkt_tst_id})
          .eq('tkt_id', tkt_id)          
      );

    } catch (e, stackTrace) {
      ticketNotifier.value = [];
      errorNotifier.value =
          ("TicketController::loadProdutos: $e \n$stackTrace");
      debugPrint("TicketController::loadProdutos: $e \n$stackTrace");
    } finally {
      loadingNotifier.value = false;
    }
  }

}
