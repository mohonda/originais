import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:originais/services/my_supabase_client_service.dart';
import 'package:originais/models/ticketModel.dart';

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
  Future<void> loadTicketStatus(String hldId) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final resposta = await mySupabaseClient.safePostgrestCall(
        () => supabaseClient
            .from('ticket_status')
            .select()
            .eq('tst_hld_id', hldId),
      );

      ticketStatusNotifier.value = resposta
          .map((item) => TicketStatusModel.fromJson(item))
          .toList();
    } catch (e, stackTrace) {
      errorNotifier.value =
          ("TicketController::loadProdutos: $e \n$stackTrace");
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> loadTickets(String openDate, String hldId) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final resposta = await mySupabaseClient.safePostgrestCall(
        () => supabaseClient
            .from('vtickets')
            .select('''*, vtickets_items(*)''')
            .eq('tkt_bar_open_date', openDate)
            .eq('tkt_hld_id', hldId),
      );

      ticketNotifier.value = resposta
          .map((item) => TicketsModel.fromJson(item))
          .toList();
    } catch (e, stackTrace) {
      errorNotifier.value =
          ("TicketController::loadProdutos: $e \n$stackTrace");
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> openTicketsFunction(
    TicketsModel openTickets,
    String openDate,
    String hldId
    ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      await mySupabaseClient.safePostgrestCall(
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
    } catch (e, stackTrace) {
      errorNotifier.value =
          ("TicketController::loadProdutos: $e \n$stackTrace");
    } finally {
      loadingNotifier.value = false;
      loadTickets( openDate, hldId );
    }
  }

  // ==========================================
  Future<void> closeTicketsWithoutPayment(
    String tktId,
    String tktTstId,
    String openDate,
    String hldId
  ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      await mySupabaseClient.safePostgrestCall(
        () => supabaseClient
          .from('tickets')
          .update({'tkt_tst_id': tktTstId})
          .eq('tkt_id', tktId)          
      );

    } catch (e, stackTrace) {
      errorNotifier.value =
          ("TicketController::loadProdutos: $e \n$stackTrace");
    } finally {
      loadingNotifier.value = false;
      loadTickets( openDate, hldId );
    }
  }

  // ==========================================
  Future<void> insertTicketsItems(
    TicketsItemsModel ticketsItems,
    String openDate,
    String hldId)
  async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      await mySupabaseClient.safePostgrestCall(
        () => supabaseClient
          .from( 'tickets_items' )
          .insert( ticketsItems.toJson() )
      );
    } catch (e, stackTrace) {
      errorNotifier.value =
          ("TicketController::insertTicketsItems: $e \n$stackTrace");
    } finally {
      loadingNotifier.value = false;
      loadTickets( openDate, hldId );
    }
  }

  // ==========================================
    Future<void> updateTicketsItems(
      String tit_id,
      int tit_quantities,
      String openDate,
      String hldId
    ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      await mySupabaseClient.safePostgrestCall(
        () => supabaseClient
          .from( 'tickets_items' )
          .update({'tit_quantities': tit_quantities })
          .eq( 'tit_id', tit_id )
      );

    } catch (e, stackTrace) {
      errorNotifier.value =
          ("TicketController::insertTicketsItems: $e \n$stackTrace");
    } finally {
      loadingNotifier.value = false;
      loadTickets( openDate, hldId );
    }
  }

  // ==========================================
  Future<void> deleteTicketsItems(
    String tit_id,
    String openDate,
    String hldId
  ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      await mySupabaseClient.safePostgrestCall(
        () => supabaseClient
          .from( 'tickets_items' )
          .delete()
          .eq( 'tit_id', tit_id )
      );

    } catch (e, stackTrace) {
      errorNotifier.value =
          ("TicketController::insertTicketsItems: $e \n$stackTrace");
    } finally {
      loadingNotifier.value = false;
      loadTickets( openDate, hldId );
    }
  }

}
