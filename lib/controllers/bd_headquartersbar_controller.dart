import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:originais/models/headquartersbar_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:originais/services/my_supabase_client_service.dart';

final getItBdHeadquartersBarController = GetIt.instance;

void setupGetItBdHeadquartersBarController() {
  getItBdHeadquartersBarController
    .registerLazySingleton<BdHeadquartersBarController>(
      () => BdHeadquartersBarController(),
  );
}

class BdHeadquartersBarController extends ChangeNotifier {
  final mySupabaseClient = getItMySupabaseClient<MySupabaseClient>();
  late SupabaseClient supabaseClient;
 
  final ValueNotifier<List<HeadquartersBarModel>> headquartersBarNotifier =
    ValueNotifier<List<HeadquartersBarModel>>([]);

  final ValueNotifier<bool> loadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);

  // 🟢 Guardará o canal ativo do Supabase
  RealtimeChannel? _realtimeChannel;
  
  // ==========================================
  BdHeadquartersBarController() {
    supabaseClient = mySupabaseClient.getSupabaseClient();
  }

  // 🟢 INICIA A ESCUTA EM TEMPO REAL
void initRealtime(String hldId) {
  disposeRealtime();

  _realtimeChannel = supabaseClient
      .channel('public:headquarters_bar:$hldId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'headquarters_bar',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'bar_hld_id',
          value: hldId,
        ),
        callback: (payload) {
          // 🟢 Recarrega em segundo plano sem travar a interface
          loadHeadquartersBar(hldId, showLoading: false);
        },
      )
      .subscribe();
}

  // 🟢 ENCERRA A ESCUTA
  void disposeRealtime() {
    if (_realtimeChannel != null) {
      supabaseClient.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
    }
  }

  // ==========================================
// 2. Adicione o parâmetro opcional 'showLoading' no seu método
Future<void> loadHeadquartersBar(String hldId, {bool showLoading = true}) async {
  try {
    if (showLoading) loadingNotifier.value = true;
    errorNotifier.value = null;

    final resposta = await mySupabaseClient.safePostgrestCall(()=>
      supabaseClient
      .from('vheadquarters_bar')
      .select()
      .eq('bar_hld_id', hldId)
    );
 
    headquartersBarNotifier.value = resposta.map(
      ( item ) => HeadquartersBarModel.fromJson( item )).toList();
    
  } catch (e, stackTrace) {
    headquartersBarNotifier.value = [];
    errorNotifier.value = ("BdHeadquartersBarController::loadHeadquartersBar: $e \n$stackTrace");
  } finally {
    if (showLoading) loadingNotifier.value = false;
  }
}
  // ==========================================
  Future<void> openHeadquartersBar(
    String pflId,
    String hldId,
    String openDate,
    String barDesc ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      await mySupabaseClient.safePostgrestCall(()=>
        supabaseClient
        .from('headquarters_bar')
        .insert({
          'bar_open_pfl_id': pflId,
          'bar_hld_id': hldId,
          'bar_open_date': openDate,
          'bar_desc': barDesc,
        })
      );
     
    } catch (e, stackTrace) {
      headquartersBarNotifier.value = [];
      errorNotifier.value = ("BdHeadquartersBarController::openHeadquartersBar: $e \n$stackTrace");
    } finally {
      loadingNotifier.value = false;
    }
  }

}