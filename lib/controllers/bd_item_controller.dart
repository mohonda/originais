import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../models/item_model.dart';
import '../services/bd_item_service.dart';

final getItBdItemController = GetIt.instance;

void setupGetItBdItemController() {
  getItBdItemController.registerLazySingleton<BdItemController>(
    () => BdItemController(),
  );
}

class BdItemController extends ChangeNotifier {
  final BdItemService dbItemService = BdItemService();

  final ValueNotifier<List<ItemModel>> itensNotifier =
    ValueNotifier<List<ItemModel>>([]);
  final ValueNotifier<bool> loadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<bool> isChangedNotifier = ValueNotifier<bool>(false);

  Future<void> loadItems() async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      itensNotifier.value = await dbItemService.loadItems();
    } catch (e) {
      itensNotifier.value = ([]);
      errorNotifier.value = 'Erro BdItemController::loadItems: $e';
    } finally {
      loadingNotifier.value = false;
    }
  }

  Future<void> saveItem(String name) async {
    if (name.trim().isEmpty) {
      return;
    }

    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final newItem = ItemModel(id: DateTime.now().toString(), nome: name);
      await dbItemService.saveItem(newItem);
      itensNotifier.value.add(newItem);

    } catch (e) {
      itensNotifier.value = ([]);
      errorNotifier.value = 'Erro BdItemController::saveItem: $e';
    } finally {
      loadingNotifier.value = false;
    }
  }

  Future<void> updateItem(String id, String name) async {
    if (name.trim().isEmpty) {
      return;
    }
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final index = itensNotifier.value.indexWhere((item) => item.id == id);

      if (index != -1) {
        final itemAtualizado = ItemModel(id: id, nome: name);
        await dbItemService.updateItem(itemAtualizado);

        itensNotifier.value[index].nome = name;
      }
    } catch (e) {
      itensNotifier.value = ([]);
      errorNotifier.value = 'Erro BdItemController::updateItem: $e';
    } finally {
      loadingNotifier.value = false;
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      await dbItemService.deleteItem(id);
      itensNotifier.value.removeWhere((item) => item.id == id);

    } catch (e) {
      itensNotifier.value = ([]);
      errorNotifier.value = 'Erro BdItemController::deleteItem: $e';
    } finally {
      loadingNotifier.value = false;
    }    
  }

}
