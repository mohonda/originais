import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:originais/services/my_supabase_client_service.dart';

final getItBdVProfilesSanctionsController = GetIt.instance;

void setupGetItBdVProfilesSanctionsController() {
  getItBdVProfilesSanctionsController
      .registerLazySingleton<OpenBarTicketTicketitemController>(
        () => OpenBarTicketTicketitemController(),
      );
}

class OpenBarTicketTicketitemController extends ChangeNotifier {
  final mySupabaseClient = getItMySupabaseClient<MySupabaseClient>();
  late SupabaseClient supabaseClient;

  final ValueNotifier<bool> loadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);

  // ==========================================
  OpenBarTicketTicketitemController() {
    supabaseClient = mySupabaseClient.getSupabaseClient();
  }

  // ==========================================
  Future<void> openBarTicketTicketitem({
      required String p_hld_id,
      required String p_pfl_id,
      required String p_pfl_name,
      required String p_date_start,
      required String p_desc,
      required String p_tss_id,
      required String p_table_number,
      required String p_pdt_id,
      required String p_pdt_quant,
      required String p_valor,
    }) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      await mySupabaseClient.safePostgrestCall(
        () => supabaseClient.rpc(
          'open_bar_ticket_item',
          params: {
            'p_hld_id': p_hld_id.toString(),
            'p_pfl_id': p_pfl_id,
            'p_pfl_name': p_pfl_name.toString(),
            'p_date_start': p_date_start.toString(),
            'p_desc': p_desc.toString(),
            'p_tss_id': p_tss_id.toString(),
            'p_table_number': p_table_number.toString(),
            'p_pdt_id': p_pdt_id.toString(),
            'p_pdt_quant': p_pdt_quant.toString(),
            'p_valor': double.parse(p_valor),
          },
        ),
      );

    } catch (e, stackTrace) {
      errorNotifier.value =
          ("OpenBarTicketTicketitemController::openBarTicketTicketitem: $e \n$stackTrace");
      debugPrint( errorNotifier.value.toString() );
    } finally {
      loadingNotifier.value = false;
    }
  }

}