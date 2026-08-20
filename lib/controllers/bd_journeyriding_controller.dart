import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../models/Journeyriding_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gorouter_exemplo/services/my_supabase_client_service.dart';

final getItBdJourneyRidingController = GetIt.instance;

void setupGetItBdJourneyRidingController() {
  getItBdJourneyRidingController.registerLazySingleton<BdJourneyRidingController>(
    () => BdJourneyRidingController(),
  );
}

class BdJourneyRidingController extends ChangeNotifier {
  final mySupabaseClient = getItMySupabaseClient<MySupabaseClient>();
  late SupabaseClient supabaseClient;

  final ValueNotifier<List<JourneyRidingModel>> bdJourneyRidingNotifier =
    ValueNotifier<List<JourneyRidingModel>>([]);

  final ValueNotifier<bool> loadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);
  
  // ==========================================
  BdJourneyRidingController() {
    supabaseClient = mySupabaseClient.getSupabaseClient();
  }

  // ==========================================
  Future<void> loadJourneyRiding() async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final resposta = await supabaseClient
        .from('v_journey_riding')
        .select();
      
        bdJourneyRidingNotifier.value = resposta.map( ( item ) =>
          JourneyRidingModel.fromJson( item ) ).toList();
      
    } catch (e, stackTrace) {
      bdJourneyRidingNotifier.value = [];
      errorNotifier.value = ("BdItemController::loadItems: $e \n$stackTrace");
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  // Future<void> saveItem(String name) async {
  //   try {
  //     loadingNotifier.value = true;
  //     errorNotifier.value = null;

  //     final newItem = JourneyRidingModel( id: DateTime.now().toString(), nome: name );

  //     await supabaseClient
  //       .from('itens')
  //       .update({ 'nome': newItem.nome })
  //       .eq( 'id', newItem.id ); 

  //     itensNotifier.value.add(newItem);

  //   } catch (e, stackTrace) {
  //     itensNotifier.value = [];
  //     errorNotifier.value = ("BdItemController::loadItems: $e \n$stackTrace");
  //   } finally {
  //     loadingNotifier.value = false;
  //   }
  // }

    // ==========================================
  // Future<void> updateItem(String id, String name) async {
  //   try {
  //     loadingNotifier.value = true;
  //     errorNotifier.value = null;

  //     final index = itensNotifier.value.indexWhere( (item) => item.id == id );

  //     if (index != -1) {
  //       await supabaseClient
  //         .from('itens')  
  //         .update({ 'nome': name })
  //         .eq( 'id', id ); 

  //       itensNotifier.value[index].nome = name;
  //     }
  //   } catch (e, stackTrace) {
  //     itensNotifier.value = [];
  //     errorNotifier.value = ("BdItemController::updateItem: $e \n$stackTrace");
  //   } finally {
  //     loadingNotifier.value = false;
  //   }
  // }

  // ==========================================
  // Future<void> deleteItem(String id) async {
  //   try {
  //     loadingNotifier.value = true;
  //     errorNotifier.value = null;

  //     await supabaseClient.from( 'itens' )
  //       .delete()
  //       .eq( 'id', id );

  //     itensNotifier.value.removeWhere( (item) => item.id == id );

  //   } catch (e, stackTrace) {
  //     itensNotifier.value = [];
  //     errorNotifier.value = ("BdItemController::updateItem: $e \n$stackTrace");
  //   } finally {
  //     loadingNotifier.value = false;
  //   }    
  // }

}
