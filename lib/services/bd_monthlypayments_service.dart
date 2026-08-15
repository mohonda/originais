import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gorouter_exemplo/models/mensalidades_model.dart';

class BdMonthlyPaymentsService {
  final _db = Supabase.instance.client;

  Future<List<MensalidadesModel>> loadCurrentMonthlyPayment(
    String month,
    String year,
  ) async {
    final resposta = await _db
        .from('vmensalidades')
        .select()
        .eq('mes_referencia', month)
        .eq('ano_referencia', year);

    return resposta.map((item) => MensalidadesModel.fromJson(item)).toList();
  }

  Future<MensalidadesModel> loadMonthlyPaymentsIndividual(
    String id,
    String month,
    String year,
  ) async {
    try {
      final resposta = await _db
          .from('vmensalidades')
          .select()
          .eq('id', id)
          .eq('mes_referencia', month)
          .eq('ano_referencia', year)
          .single();

      return MensalidadesModel.fromJson(resposta);
    } catch (e) {
      debugPrint("loadMonthlyPaymentsIndividual::loadMonthlyPaymentsIndividual: $e");
      throw Exception(
        'loadMonthlyPaymentsIndividual::loadMonthlyPaymentsIndividual.',
      );
    }
  }

  Future updateComprovante(
    String id,
    String mes_referencia,
    String ano_referencia,
    String comprovante_pag,
  ) async {
    await _db
        .from('mensalidades')
        .update({'comprovante_pag': comprovante_pag})
        .eq('mes_referencia', mes_referencia)
        .eq('ano_referencia', ano_referencia)
        .eq('id', id);
  }

  Future updatePaymentsProfile(
    String id,
    String mes,
    String ano,
    String valor,
    String datapagamento,
    String formapagamento,
  ) async {
    try {
      await _db
          .from('mensalidades')
          .update({
            'valor': valor,
            'data_pagamento': datapagamento,
            'forma_pagamento': formapagamento,
          })
          .eq('mes_referencia', mes)
          .eq('ano_referencia', ano)
          .eq('id', id );
      // .select().single();
    } catch (e) {
      debugPrint("BdMonthlyPaymentsService::updatePaymentsProfile: $e");
      throw Exception(
        'BdMonthlyPaymentsService::updatePaymentsProfile:',
      );
    }
  }
}
