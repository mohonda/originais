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
  
  // ==========================================
  BdHeadquartersBarController() {
    supabaseClient = mySupabaseClient.getSupabaseClient();
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
      debugPrint(resposta.length.toString());
    
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
