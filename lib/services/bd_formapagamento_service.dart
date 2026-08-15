import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gorouter_exemplo/models/formapagamento_model.dart';

class BdFormaPagamentoService {
  final _db = Supabase.instance.client;

  Future<List<FormaPagamentoModel>> loadFormaPagamento() async {
    final resposta = await _db
        .from('forma_pagamento')
        .select();

    return resposta
        .map((item) => FormaPagamentoModel.fromJson(item))
        .toList();
  }
  
}
