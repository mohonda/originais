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

  final ValueNotifier<bool> loadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);

  final ValueNotifier<List<TicketsModel>> profileTicketsNotifier =
      ValueNotifier<List<TicketsModel>>([]);

  final ValueNotifier<List<TicketsModel>> profileTicketsWithItemsNotifier =
      ValueNotifier<List<TicketsModel>>([]);

  // 🟢 Canais do Supabase Realtime
  RealtimeChannel? _realtimeChannel;
  RealtimeChannel? _realtimeProfileChannel; // 👈 Canal dedicado para o perfil

  TicketController() {
    supabaseClient = mySupabaseClient.getSupabaseClient();
  }

  // ==========================================
  // 🟢 REALTIME DO BAR (VENDA DIÁRIA)
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

  void disposeRealtime() {
    if (_realtimeChannel != null) {
      supabaseClient.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
    }
  }

  // ==========================================
  // 🟢 REALTIME DO PERFIL DO USUÁRIO
  // ==========================================
  void initRealtimeProfile(String pflId, String hldId) {
    disposeRealtimeProfile();

    _realtimeProfileChannel = supabaseClient
        .channel('public:tickets_profile:$hldId:$pflId')
        // 1. Escuta alterações em tickets vinculados ao perfil selecionado
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
            // Recarrega os dados em segundo plano sem piscar o loading na tela
            loadTicketsByProfileWithItems(pflId, hldId, showLoading: false);
          },
        )
        // 2. Escuta inclusão/alteração/remoção de itens em comandas
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

  void disposeRealtimeProfile() {
    if (_realtimeProfileChannel != null) {
      supabaseClient.removeChannel(_realtimeProfileChannel!);
      _realtimeProfileChannel = null;
    }
  }

  // ==========================================
  // MÉTODOS DE CARREGAMENTO DE DADOS
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
          ("TicketController::loadTicketStatus: $e \n$stackTrace");
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
            .eq('tkt_hld_id', hldId),
      );
      debugPrint('-----> $barId');

      ticketNotifier.value = resposta
          .map((item) => TicketsModel.fromJson(item))
          .toList();
    } catch (e, stackTrace) {
      errorNotifier.value =
          ("TicketController::loadTickets: $e \n$stackTrace");
    } finally {
      if (showLoading) loadingNotifier.value = false;
    }
  }

  // 🟢 CORRIGIDO: Removido o reset inicial (profileTicketsWithItemsNotifier.value = []) 
  // para evitar o efeito de tela piscando durante atualizações realtime
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
      );

      profileTicketsWithItemsNotifier.value = resposta
          .map((item) => TicketsModel.fromJson(item))
          .toList();
    } catch (e, stackTrace) {
      profileTicketsWithItemsNotifier.value = [];
      errorNotifier.value =
          ("TicketController::loadTicketsByProfileWithItems: $e \n$stackTrace");
    } finally {
      if (showLoading) loadingNotifier.value = false;
    }
  }

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
      debugPrint("TicketController::loadTicketsByProfile: $e\n$stackTrace");
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  // AÇÕES DO TICKET (INSERT, UPDATE, DELETE)
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

      debugPrint(openTickets.tkt_bar_id.toString());

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
      errorNotifier.value =
          ("TicketController::openTicketsFunction: $e \n$stackTrace");
          debugPrint( "$e \n$stackTrace");
    } finally {
      loadingNotifier.value = false;
    }
  }

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
      errorNotifier.value =
          ("TicketController::closeTicketsWithoutPayment: $e \n$stackTrace");
    } finally {
      loadingNotifier.value = false;
    }
  }

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
      errorNotifier.value =
          ("TicketController::insertTicketsItems: $e \n$stackTrace");
    } finally {
      loadingNotifier.value = false;
    }
  }

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
          .update({'tit_quantities': tit_quantities })
          .eq( 'tit_id', tit_id )
      );
      await loadTickets( barId, openDate, hldId );

    } catch (e, stackTrace) {
      errorNotifier.value =
          ("TicketController::updateTicketsItems: $e \n$stackTrace");
    } finally {
      loadingNotifier.value = false;
    }
  }

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
      errorNotifier.value =
          ("TicketController::deleteTicketsItems: $e \n$stackTrace");
    } finally {
      loadingNotifier.value = false;
    }
  }
}