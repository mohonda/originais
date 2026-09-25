import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:originais/services/my_supabase_client_service.dart';
import 'package:originais/models/ticket_model.dart';

final getItTicketController = GetIt.instance;

void setupGetItTicketController() {
  getItTicketController.registerLazySingleton<TicketController>(
  // getItTicketController.registerFactory<TicketController>(
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

  final ValueNotifier<List<TicketsModel>> ticketsBarTypeSalesNotifier =
      ValueNotifier<List<TicketsModel>>([]);

  final ValueNotifier<bool> loadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<String?> successNotifier = ValueNotifier<String?>(null);

  final ValueNotifier<List<TicketsModel>> profileTicketsNotifier =
      ValueNotifier<List<TicketsModel>>([]);

  final ValueNotifier<List<TicketsModel>> profileTicketsWithItemsNotifier =
      ValueNotifier<List<TicketsModel>>([]);

  // 🟢 Canais do Supabase Realtime
  RealtimeChannel? _realtimeChannel;
  RealtimeChannel? _realtimeProfileChannel;

  // ==========================================
  TicketController() {
    supabaseClient = mySupabaseClient.getSupabaseClient();
  }

  // ==========================================
  void initRealtime(String barId, String openDate, String hldId) {
    disposeRealtime();

    _realtimeChannel = supabaseClient
        .channel('public:tickets:$hldId:$openDate')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tickets',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'tkt_hld_id',
            value: hldId,
          ),
          callback: (payload) {
            loadTickets(barId, openDate, hldId, showLoading: false);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tickets_items',
          callback: (payload) {
            loadTickets(barId, openDate, hldId, showLoading: false);
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
  void initRealtimeProfile(String pflId, String hldId) {
    disposeRealtimeProfile();

    _realtimeProfileChannel = supabaseClient
        .channel('public:tickets_profile:$hldId:$pflId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tickets',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'tkt_pfl_id',
            value: pflId,
          ),
          callback: (payload) {
            loadTicketsByProfileWithItems(pflId, hldId, showLoading: false);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tickets_items',
          callback: (payload) {
            loadTicketsByProfileWithItems(pflId, hldId, showLoading: false);
          },
        )
        .subscribe();
  }

  // ==========================================
  void disposeRealtimeProfile() {
    if (_realtimeProfileChannel != null) {
      supabaseClient.removeChannel(_realtimeProfileChannel!);
      _realtimeProfileChannel = null;
    }
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
      errorNotifier.value = "loadTicketStatus: $e \n$stackTrace";
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> loadTickets(
    String barId,
    String openDate,
    String hldId,
    {bool showLoading = true}) async {
    try {
      if (showLoading) loadingNotifier.value = true;
      errorNotifier.value = null;

      final resposta = await mySupabaseClient.safePostgrestCall(
        () => supabaseClient
            .from('vtickets')
            .select('''*, vtickets_items(*)''')
            .eq('tkt_bar_id', barId)
            .eq('tkt_hld_id', hldId)
            .order('tkt_table_number', ascending: true)
      );

      ticketNotifier.value = resposta
          .map((item) => TicketsModel.fromJson(item))
          .toList();
    } catch (e, stackTrace) {
      errorNotifier.value = "loadTickets: $e \n$stackTrace";
    } finally {
      if (showLoading) loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> loadTicketsByProfileWithItems(
    String pfl_id,
    String hldId, {
    bool showLoading = true,
  }) async {
    try {
      if (showLoading) loadingNotifier.value = true;
      errorNotifier.value = null;

      final resposta = await mySupabaseClient.safePostgrestCall(
        () => supabaseClient
            .from('vtickets')
            .select('''*, vtickets_items(*)''')
            .eq('tkt_pfl_id', pfl_id)
            .eq('tkt_hld_id', hldId)
            .order('tkt_bar_open_date', ascending: false)
            .order('tkt_id', ascending: false)
      );

      profileTicketsWithItemsNotifier.value = resposta
          .map((item) => TicketsModel.fromJson(item))
          .toList();
    } catch (e, stackTrace) {
      profileTicketsWithItemsNotifier.value = [];
      errorNotifier.value = "loadTicketsByProfileWithItems: $e \n$stackTrace";
    } finally {
      if (showLoading) loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> loadTicketsBarTypeSales({
    String? barId,
    String? tssId,
    String? hldId
  }) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final resposta = await mySupabaseClient.safePostgrestCall(
        () => supabaseClient
            .from('vtickets')
            .select('''*, vtickets_items(*)''')
            .eq('tkt_bar_id', barId.toString() )
            .eq('bar_tss_id', tssId.toString() )
            .eq('tkt_hld_id', hldId.toString() )
            .order('tkt_bar_open_date', ascending: false)
            .order('tkt_id', ascending: false)
      );

      ticketsBarTypeSalesNotifier.value = resposta
          .map((item) => TicketsModel.fromJson(item))
          .toList();
    } catch (e, stackTrace) {
      ticketsBarTypeSalesNotifier.value = [];
      errorNotifier.value = "loadTicketsByProfileWithItems: $e \n$stackTrace";
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> loadTicketsByProfile(String pflId, String hldId) async {
    try {
      loadingNotifier.value = true;
      
      final resposta = await mySupabaseClient.safePostgrestCall(() =>
        supabaseClient
          .from('vtickets')
          .select()
          .eq('tkt_hld_id', hldId)
          .eq('tkt_pfl_id', pflId)
      );

      profileTicketsNotifier.value = 
          resposta.map((item) => TicketsModel.fromJson(item)).toList();

    } catch (e, stackTrace) {
      profileTicketsNotifier.value = [];
      errorNotifier.value = "loadTicketsByProfile: $e\n$stackTrace";
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<String> insertTickets({
    String? hldId,
    String? openDate,
    String? nTable,
    String? clienteName,
    String? pflId,
    String? barId
    }) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final resposta = await mySupabaseClient.safePostgrestCall(
        () => supabaseClient
          .from('tickets')
          .insert({
            'tkt_hld_id': hldId,
            'tkt_bar_open_date': openDate,
            'tkt_table_number': nTable,
            'tkt_client_name': clienteName,
            'tkt_pfl_id' : pflId,
            'tkt_bar_id': barId,
          })
          .select('tkt_id')
          .single(),
      );
      return resposta['tkt_id'].toString();

    } catch (e, stackTrace) {
      errorNotifier.value = "insertTickets: $e \n$stackTrace";
      return '-1';
    } finally {
      successNotifier.value = 'Ticket inserido com sucesso.';
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> openTicketsFunction(
    TicketsModel openTickets,
    String barId,
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
            'p_bar_id': openTickets.tkt_bar_id.toString(),
            'p_bar_open_date': openTickets.tkt_bar_open_date.toString(),
            'p_client_name': openTickets.tkt_client_name.toString(),
            'p_pfl_id': openTickets.tkt_pfl_id,
            'p_has_discount': openTickets.tkt_has_discount.toString(),
            'p_tst_id': openTickets.tkt_tst_id.toString(),
          },
        ),
      );
      await loadTickets( barId, openDate, hldId );

    } catch (e, stackTrace) {
      errorNotifier.value = "openTicketsFunction: $e \n$stackTrace";
    } finally {
      successNotifier.value = 'Ticket aberto com sucesso.';
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> closeTicketsWithoutPayment(
    String tktId,
    String tktTstId,
    String barId,
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
      await loadTickets( barId, openDate, hldId );

    } catch (e, stackTrace) {
      errorNotifier.value = "closeTicketsWithoutPayment: $e \n$stackTrace";
    } finally {
      successNotifier.value = 'Ticket closed withou payment.';
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> updateTicketsDate(
    String tktId,
    String openDate,
  ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      await mySupabaseClient.safePostgrestCall(
        () => supabaseClient
          .from('tickets')
          .update({'tkt_bar_open_date': openDate})
          .eq('tkt_id', tktId)          
      );

    } catch (e, stackTrace) {
      errorNotifier.value = "closeTicketsWithoutPayment: $e \n$stackTrace";
    } finally {
      successNotifier.value = 'Ticket date updated.';
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> insertTicketsItems(
    TicketsItemsModel ticketsItems,
    String barId,
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
      await loadTickets( barId, openDate, hldId );
    } catch (e, stackTrace) {
      errorNotifier.value = "insertTicketsItems: $e \n$stackTrace";
    } finally {
      successNotifier.value = 'Item inserido com sucesso.';
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> updateTicketsItems(
    String tit_id,
    int tit_quantities,
    String barId,
    String openDate,
    String hldId
  ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      await mySupabaseClient.safePostgrestCall(
        () => supabaseClient
          .from( 'tickets_items' )
          .update({'tit_quantities': tit_quantities})
          .eq( 'tit_id', tit_id )
      );
      await loadTickets( barId, openDate, hldId );

    } catch (e, stackTrace) {
      errorNotifier.value = "updateTicketsItems: $e \n$stackTrace";
    } finally {
      successNotifier.value = 'Ticket updated com sucesso.';
      loadingNotifier.value = false;
    }
  }
  
  // ==========================================
  Future<void> updateTicketsItems_value(
    String tit_id,
    int tit_quantities,
    double titValue,
    String barId,
    String openDate,
    String hldId
  ) async {
    try {
      debugPrint(titValue.toString());
      debugPrint(tit_id.toString());
      loadingNotifier.value = true;
      errorNotifier.value = null;

      await mySupabaseClient.safePostgrestCall(
        () => supabaseClient
          .from( 'tickets_items' )
          .update({
            'tit_quantities': tit_quantities,
            'tit_unit_value': titValue,
            })
          .eq( 'tit_id', tit_id )
      );
      await loadTickets( barId, openDate, hldId );

    } catch (e, stackTrace) {
      errorNotifier.value = "updateTicketsItems: $e \n$stackTrace";
    } finally {
      successNotifier.value = 'Ticket updated com sucesso.';
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> deleteTicketsItems(
    String tit_id,
    String barId,
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
      await loadTickets( barId, openDate, hldId );

    } catch (e, stackTrace) {
      errorNotifier.value = "deleteTicketsItems: $e \n$stackTrace";
    } finally {
      successNotifier.value = 'Item deleted com sucesso.';
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> deleteTit(
    String tit_id
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
      errorNotifier.value = "deleteTit: $e \n$stackTrace";
    } finally {
      successNotifier.value = 'Item deleted com sucesso.';
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> deleteTkt(
    String tkt_id
  ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      await mySupabaseClient.safePostgrestCall(
        () => supabaseClient
          .from( 'tickets' )
          .delete()
          .eq( 'tkt_id', tkt_id )
      );

    } catch (e, stackTrace) {
      errorNotifier.value = "deleteTkt: $e \n$stackTrace";
    } finally {
      successNotifier.value = 'Ticket deleted com sucesso.';
      loadingNotifier.value = false;
    }
  } 

  // ==========================================
  Future<void> deleteBar(
    String bar_id
  ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      await mySupabaseClient.safePostgrestCall(
        () => supabaseClient
          .from( 'headquarters_bar' )
          .delete()
          .eq( 'bar_id', bar_id )
      );

    } catch (e, stackTrace) {
      errorNotifier.value = "deleteTkt: $e \n$stackTrace";
    } finally {
      successNotifier.value = 'Opened bar deleted com sucesso.';
      loadingNotifier.value = false;
    }
  } 
  
  }