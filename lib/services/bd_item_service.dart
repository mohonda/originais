import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gorouter_exemplo/models/item_model.dart';

class BdItemService {
  final _db = Supabase.instance.client;

  Future<List<ItemModel>> loadItems() async {
    final resposta = await _db
        .from('itens')
        .select()
        .order('nome', ascending: true);

    return resposta.map((json) {
      return ItemModel(
        id: json['id'] as String,
        nome: json['nome'] as String
      );
    }).toList();
  }

  Future<void> saveItem(ItemModel item) async {
    await _db.from('itens').insert({'id': item.id, 'nome': item.nome});
  }

  Future<void> updateItem(ItemModel item) async {
    await _db
        .from('itens')
        .update({'nome': item.nome})
        .eq('id', item.id); 
  }

  Future<void> deleteItem(String id) async {
    await _db.from('itens').delete().eq('id', id);
  }

}
