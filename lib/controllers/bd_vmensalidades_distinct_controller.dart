
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:gorouter_exemplo/models/vmensalidades_distinct_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gorouter_exemplo/services/my_supabase_client_service.dart';

final getItBdVMensalidadesDistinctController = GetIt.instance;

void setupGetItBdVMensalidadesDistinctController() {
  getItBdVMensalidadesDistinctController.registerLazySingleton<BdVMensalidadesDistinctController>(
    () => BdVMensalidadesDistinctController(),
  );
}

class BdVMensalidadesDistinctController extends ChangeNotifier {
  final mySupabaseClient = getItMySupabaseClient<MySupabaseClient>();
  late SupabaseClient supabaseClient;
 
  final ValueNotifier<List<VMensalidadeDistinctModel>> vMensalidadeDistinctNotifier =
    ValueNotifier<List<VMensalidadeDistinctModel>>([]);

  final ValueNotifier<bool> loadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);
  
  // ==========================================
  BdVMensalidadesDistinctController() {
    supabaseClient = mySupabaseClient.getSupabaseClient();
  }

  // ==========================================
  Future<void> loadMensalidadesDistincts() async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final resposta = await mySupabaseClient.safePostgrestCall(()=>
        supabaseClient
        .from('vmes_ano_mensalidades_distinct')
        .select()
      );
    
      vMensalidadeDistinctNotifier.value = resposta.map(
        ( item ) => VMensalidadeDistinctModel.fromJson( item )
      ).toList();
      
    } catch (e, stackTrace) {
      vMensalidadeDistinctNotifier.value = [];
      errorNotifier.value = ("BdVMensalidadesDistinctController::loadMensalidadesDistincts: $e \n$stackTrace");
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> deleteMensalidadesDistincts(
    String month,
    String year,
    String hld_id,
  ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      await mySupabaseClient.safePostgrestCall(()=>
        supabaseClient
        .from('mensalidades')
        .delete()
        .eq('mes_mes_referencia', month)
        .eq('mes_ano_referencia', year)
        .eq('mes_hld_id', hld_id)
      );
          
    } catch (e, stackTrace) {
      vMensalidadeDistinctNotifier.value = [];
      errorNotifier.value = ("BdVMensalidadesDistinctController::loadMensalidadesDistincts: $e \n$stackTrace");
    } finally {
      loadingNotifier.value = false;
      loadMensalidadesDistincts();
    }
  }

}
