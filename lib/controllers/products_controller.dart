import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gorouter_exemplo/services/my_supabase_client_service.dart';
import 'package:gorouter_exemplo/models/products_model.dart';

final getItProductsController = GetIt.instance;

void setupGetItProductsController() {
  getItProductsController
    .registerLazySingleton<ProductsController>(
      () => ProductsController(),
  );
}

class ProductsController extends ChangeNotifier {
  final mySupabaseClient = getItMySupabaseClient<MySupabaseClient>();
  late SupabaseClient supabaseClient;
 
  final ValueNotifier<List<ProductsModel>> productsNotifier =
    ValueNotifier<List<ProductsModel>>([]);

  final ValueNotifier<bool> loadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);
  
  // ==========================================
  ProductsController() {
    supabaseClient = mySupabaseClient.getSupabaseClient();
  }

  // ==========================================
  Future<void> loadProdutos( String hld_id ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final resposta = await mySupabaseClient.safePostgrestCall(()=>
        supabaseClient
        .from('vprodutos')
        .select()
        .eq('pdt_hld_id', hld_id)
      );
    
      productsNotifier.value = resposta.map(
        ( item ) => ProductsModel.fromJson( item )).toList();
      
    } catch (e, stackTrace) {
      productsNotifier.value = [];
      errorNotifier.value = ("ProductsController::loadProdutos: $e \n$stackTrace");
    } finally {
      loadingNotifier.value = false;
    }
  }

}