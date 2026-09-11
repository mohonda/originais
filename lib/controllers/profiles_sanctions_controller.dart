import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:originais/models/profiles_sanctions_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:originais/services/my_supabase_client_service.dart';
import 'package:originais/models/sanction_model.dart';

import 'package:originais/controllers/headquarters_bar_controller.dart';
import 'package:originais/controllers/ticket_controller.dart';
import 'package:originais/models/ticket_model.dart';
import 'package:originais/controllers/open_bar_ticket_ticketitem_controller.dart';

final getItBdVProfilesSanctionsController = GetIt.instance;

void setupGetItBdVProfilesSanctionsController() {
  getItBdVProfilesSanctionsController
      .registerLazySingleton<BdVProfilesSanctionsController>(
        () => BdVProfilesSanctionsController(),
      );
}

class BdVProfilesSanctionsController extends ChangeNotifier {
  final mySupabaseClient = getItMySupabaseClient<MySupabaseClient>();
  late SupabaseClient supabaseClient;

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
  Future<void> loadProfileSanctionsStatus(String id, String hld) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final resposta = await mySupabaseClient.safePostgrestCall(
        () => supabaseClient
            .from('vprofiles_sanctions')
            .select()
            .eq('psan_pfl_id', id)
            .eq('psan_hld_id', hld),
      );

      vProfilesSanctionsNotifier.value = resposta
          .map((item) => VProfilesSanctionsModel.fromJson(item))
          .toList();
    } catch (e, stackTrace) {
      vProfilesSanctionsNotifier.value = [];
      errorNotifier.value =
          ("BdVProfilesSanctionsController::loadProfileSanctionsStatus: $e \n$stackTrace");
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
        () => supabaseClient.from('sanctions').select().eq('san_hld_id', hld),
      );

      sanctionsNotifier.value = resposta
          .map((item) => SanctionModel.fromMap(item))
          .toList();

      return sanctionsNotifier.value;
    } catch (e, stackTrace) {
      errorNotifier.value =
          ("BdVProfilesSanctionsController::loadProfileSanctionsStatus: $e \n$stackTrace");
      return sanctionsNotifier.value = [];
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> insertProfileSanction(
    String psanPflIid,
    String pflName,
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

      final resposta = await mySupabaseClient.safePostgrestCall(
        () => supabaseClient
        .from('profiles_sanctions')
        .insert({
          'psan_pfl_id': psanPflIid,
          'psan_hld_id': psanHldIid,

          'psan_san_id': psanSanId,

          'psan_valor': psanValor,
          'psan_date_start': psanDateStart,
          'psan_date_end': psanDateEnd,
          'psan_desc': psanDesc,
        })
        .select()
      );

      sanctionsNotifier.value = resposta
          .map((item) => SanctionModel.fromMap(item))
          .toList();
      
      final openTicket = OpenBarTicketTicketitemController();
      openTicket.openBarTicketTicketitem(
        p_hld_id: psanHldIid,
        p_pfl_id: psanPflIid,
        p_pfl_name: pflName,
        p_date_start: psanDateStart,
        p_desc: psanDesc,
        p_tss_id: '3', // table type_sales
        p_table_number: '-1',
        p_pdt_id: '32', // table produtos
        p_pdt_quant: '1',
        p_valor: psanValor,
      );
      
      // final bar = BdHeadquartersBarController();

      // final String barId = await bar.openHeadquartersBar(
      //   psanPflIid,
      //   psanHldIid,
      //   psanDateStart,
      //   psanDesc,
      //   '3'
      // );
      // debugPrint('---->${barId.toString()}');

      // final tkt = TicketController();
      // final tktId = await tkt.insertTickets(
      //   psanHldIid,
      //   psanDateStart,
      //   '-1',
      //   pflName,
      //   psanPflIid,
      //   barId
      // );

      // final ticketsItems2Controller = TicketsItemsModel(
      //   tit_hld_id: psanHldIid,
      //   tit_tkt_id: tktId,
      //   tit_pdt_id: '32',
      //   tit_quantities: 1,
      //   tit_unit_value: double.parse(psanValor),
      //   tit_value: double.parse(psanValor),
      // );
      // await tkt.insertTicketsItems(
      //   ticketsItems2Controller,
      //   barId,
      //   psanDateStart,
      //   psanHldIid,
      // );

      // return sanctionsNotifier.value;
    } catch (e, stackTrace) {
      errorNotifier.value =
          ("BdVProfilesSanctionsController::loadProfileSanctionsStatus: $e \n$stackTrace");
      // return sanctionsNotifier.value = [];
      debugPrint( errorNotifier.value.toString() );
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
            'psan_desc': psanDesc})
          .eq('psan_id', psanid)
      );

      await loadProfileSanctionsStatus( psanPflId, psanHldIid);

    } catch (e, stackTrace) {
      errorNotifier.value =
          ("BdVProfilesSanctionsController::loadProfileSanctionsStatus: $e \n$stackTrace");
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

      await loadProfileSanctionsStatus( psanPflId, psanHldIid);
    } catch (e, stackTrace) {
      errorNotifier.value =
          ("BdVProfilesSanctionsController::loadProfileSanctionsStatus: $e \n$stackTrace");
    } finally {
      loadingNotifier.value = false;
    }
  }

}
