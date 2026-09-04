import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:printing/printing.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:originais/models/mensalidades_model.dart';
import 'package:originais/services/general_service.dart';
import 'package:originais/services/my_supabase_client_service.dart';
import 'package:originais/models/vprofile_model.dart';
import 'dart:io';

final getItbdMonthlyPaymentsController = GetIt.instance;

void setupGetItBdMonthlyPaymentsController() {
  getItbdMonthlyPaymentsController
      .registerLazySingleton<BdMonthlyPaymentsController>(
        () => BdMonthlyPaymentsController(),
      );
}

class BdMonthlyPaymentsController extends ChangeNotifier {
  final mySupabaseClient = getItMySupabaseClient<MySupabaseClient>();
  late SupabaseClient supabaseClient;

  final ValueNotifier<List<MensalidadesModel>> monthlyPaymentsNotifier =
      ValueNotifier<List<MensalidadesModel>>([]);

  final ValueNotifier<MensalidadesModel?> monthlyPaymentsIndividual =
      ValueNotifier<MensalidadesModel?>(null);

  final ValueNotifier<bool> loadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);

  final generalService = getItGeneralService<GeneralService>();

  String idConfirmacao = '';
  String nameConfirmacao = '';
  String hld_id = '1';

  // 🟢 Guardará o canal ativo do Supabase Realtime
  RealtimeChannel? _realtimeChannel;

  // ==========================================
  BdMonthlyPaymentsController() {
    supabaseClient = mySupabaseClient.getSupabaseClient();
    idConfirmacao = mySupabaseClient.getUserId();
    loadCashierName( idConfirmacao );
  }

  // 🟢 INICIA A ESCUTA EM TEMPO REAL
  void initRealtime(String hldId) {
    disposeRealtime();

    _realtimeChannel = supabaseClient
        .channel('public:mensalidades:$hldId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all, // INSERT, UPDATE ou DELETE
          schema: 'public',
          table: 'mensalidades',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'mes_hld_id',
            value: hldId,
          ),
          callback: (payload) {
            // Atualiza a lista em segundo plano sem exibir o indicador de carregamento
            loadCurrentMonthlyPayment(showLoading: false);
          },
        )
        .subscribe();
  }

  // 🟢 ENCERRA A ESCUTA DE EVENTOS
  void disposeRealtime() {
    if (_realtimeChannel != null) {
      supabaseClient.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
    }
  }

  // ==========================================
  // 🟢 Adicionado parâmetro 'showLoading' para atualizar via Realtime silenciosamente
  Future<void> loadCurrentMonthlyPayment({bool showLoading = true}) async {
    try {
      if (showLoading) loadingNotifier.value = true;
      errorNotifier.value = null;

      final resposta = await mySupabaseClient.safePostgrestCall(()=>
        supabaseClient
        .from('vmensalidades')
        .select()
        .eq('mes_hld_id', hld_id)
      );

      monthlyPaymentsNotifier.value = 
          resposta.map((item) =>
          MensalidadesModel.fromJson(item)).toList();

    } catch (e, stackTrace) {
      monthlyPaymentsNotifier.value = [];
      debugPrint("BdMonthlyPaymentsController::loadCurrentMonthlyPayment: $e\n$stackTrace");
    } finally {
      if (showLoading) loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> loadMonthlyPaymentsIndividual(
    String id,
    String month,
    String year,
  ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;
    
      final resposta = await mySupabaseClient.safePostgrestCall(()=>
        supabaseClient
          .from('vmensalidades')
          .select()
          .eq('mes_pfl_id', id)
          .eq('mes_hld_id', '1')
          .eq('mes_mes_referencia', month)
          .eq('mes_ano_referencia', year)
          .single()
        );

      monthlyPaymentsIndividual.value =
        MensalidadesModel.fromJson(resposta);

    } catch (e, stackTrace) {
      monthlyPaymentsIndividual.value = null;
      errorNotifier.value = 'BdMonthlyPaymentsController::loadMonthlyPaymentsIndividual:  $e\n$stackTrace';
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> updateCheckingCopy(
    String pfl_id,
    String hld_id,
    String mesReferencia,
    String anoReferencia,
    String comprovantePag,
  ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final resposta = await supabaseClient
        .from('mensalidades')
        .update({'mes_comprovante_pag': comprovantePag})
        .eq('mes_mes_referencia', mesReferencia)
        .eq('mes_ano_referencia', anoReferencia)
        .eq('mes_pfl_id', pfl_id)
        .eq('mes_hld_id', hld_id)
        .select()
        .single();
        
        monthlyPaymentsIndividual.value = MensalidadesModel.fromJson( resposta );
    } catch (e, stackTrace) {
      monthlyPaymentsIndividual.value = null;
      errorNotifier.value = 'BdMonthlyPaymentsController::updateCheckingCopy:  $e\n$stackTrace';
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> updatePaymentsProfile(
    String id,
    String mes,
    String ano,
    String valor,
    String datapagamento,
    String formapagamento,
  ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      String dataSupabase = generalService.date2Supabase( datapagamento.toString() );
      String valorSupabase = generalService.value2Supabase( valor.toString() );

      final resposta = await supabaseClient
        .from('mensalidades')
        .update({
          'mes_valor': valorSupabase,
          'mes_data_pagamento': dataSupabase,
          'mes_fpg_id': formapagamento,
          'mes_fpg_hld_id': '1',

          'mes_pfl_id_confirmacao': null,
          'mes_hld_id_confirmacao': null,
          'mes_data_confirmacao': null,
        })
        .eq('mes_mes_referencia', mes)
        .eq('mes_ano_referencia', ano)
        .eq('mes_pfl_id', id )
        .eq('mes_hld_id', '1' )
        .select()
        .single();

      monthlyPaymentsIndividual.value = MensalidadesModel.fromJson( resposta );

    } catch (e, stackTrace) {
      monthlyPaymentsIndividual.value = null;
      errorNotifier.value = 'BdMonthlyPaymentsController::updatePaymentsProfile:  $e\n$stackTrace';
    } finally {
      loadCurrentMonthlyPayment();
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> updatePaymentsCashier(
    String id,
    String mes,
    String ano,
    String valor,
    String datapagamento,
    String formapagamento,
    String idCashier,
    String dateCashier,
  ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      String dataSupabase = generalService.date2Supabase( datapagamento.toString() );
      String valorSupabase = generalService.value2Supabase( valor.toString() );
      String dataCashierSupabase = generalService.date2Supabase( dateCashier.toString() );

      final resposta = await supabaseClient
        .from('mensalidades')
        .update({
          'mes_valor': valorSupabase,
          'mes_data_pagamento': dataSupabase,
          'mes_fpg_id': formapagamento,
          'mes_fpg_hld_id': '1',

          'mes_pfl_id_confirmacao': idCashier,
          'mes_hld_id_confirmacao': '1',
          'mes_data_confirmacao': dataCashierSupabase,
        })
        .eq('mes_mes_referencia', mes)
        .eq('mes_ano_referencia', ano)
        .eq('mes_pfl_id', id )
        .eq('mes_hld_id', '1' )
        .select()
        .single();

      monthlyPaymentsIndividual.value = MensalidadesModel.fromJson( resposta );

    } catch (e, stackTrace) {
      monthlyPaymentsIndividual.value = null;
      debugPrint('BdMonthlyPaymentsController::updatePaymentsCashier:  $e\n$stackTrace');
      errorNotifier.value = 'BdMonthlyPaymentsController::updatePaymentsCashier:  $e\n$stackTrace';
    } finally {
      loadCurrentMonthlyPayment();
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> cancelPaymentsCashier(
    String id,
    String mes,
    String ano,
    String idCashier,
    String dateCashier,
  ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      String dataCashierSupabase = generalService.date2Supabase( dateCashier.toString() );

      final resposta = await supabaseClient
        .from('mensalidades')
        .update({
          'mes_valor': null,
          'mes_data_pagamento': null,
          'mes_fpg_id': null,
          'mes_fpg_hld_id': null,
          
          'mes_comprovante_pag': null,
          'mes_pfl_id_confirmacao': idCashier,
          'mes_hld_id_confirmacao': '1',
          'mes_data_confirmacao': dataCashierSupabase,
        })
        .eq('mes_mes_referencia', mes)
        .eq('mes_ano_referencia', ano)
        .eq('mes_pfl_id', id )
        .eq('mes_hld_id', '1' )
        .select()
        .single();

      monthlyPaymentsIndividual.value = MensalidadesModel.fromJson( resposta );

    } catch (e, stackTrace) {
      monthlyPaymentsIndividual.value = null;
      debugPrint('BdMonthlyPaymentsController::cancelPaymentsCashier:  $e\n$stackTrace');
      errorNotifier.value = 'BdMonthlyPaymentsController::cancelPaymentsCashier:  $e\n$stackTrace';
    } finally {
      loadCurrentMonthlyPayment();
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> loadCashierName( String id ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final resposta = await mySupabaseClient.safePostgrestCall(()=>
        supabaseClient
        .from( 'profiles' )
        .select('pfl_full_name')
        .eq( 'pfl_id', id )
        .eq( 'hld_id', '1' )
        .maybeSingle()
      );

      if ( resposta != null ) {
        nameConfirmacao = resposta['pfl_full_name'] as String? ?? '';
      }

    } catch ( e, stackTrace ) {
      nameConfirmacao = '';
      errorNotifier.value = "BdMonthlyPaymentsController::loadCashierName: $e \n$stackTrace";
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> insertMonthlyGeneration(
    List<Map<String, dynamic>> filteredList
  ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      await supabaseClient
      .from('mensalidades')
      .insert(filteredList);

    } catch (e, stackTrace) {
      monthlyPaymentsIndividual.value = null;
      errorNotifier.value = 'BdMonthlyPaymentsController::insertMonthlyGeneration:  $e\n$stackTrace';
    } finally {
      loadingNotifier.value = false;
      loadCurrentMonthlyPayment();
    }
  }

}