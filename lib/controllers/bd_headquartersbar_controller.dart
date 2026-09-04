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
    // 1. Cancela se já houver um canal aberto
    disposeRealtime();

    // 2. Inscreve no canal escutando apenas o 'hldId' do seu estabelecimento
    _realtimeChannel = supabaseClient
        .channel('public:headquarters_bar:$hldId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all, // INSERT, UPDATE ou DELETE
          schema: 'public',
          table: 'headquarters_bar',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'bar_hld_id',
            value: hldId,
          ),
          callback: (payload) {
            // Quando QUALQUER aparelho abrir o bar, esse callback roda em todos os outros
            // e recarrega a lista automaticamente através da sua View!
            loadHeadquartersBar(hldId);
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
  Future<void> loadHeadquartersBar( String hldId ) async {
    try {
      loadingNotifier.value = true;
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
      loadingNotifier.value = false;
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