import 'package:flutter/material.dart';
import 'package:originais/services/BaseImageUploadService.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:originais/services/my_supabase_client_service.dart';
import 'package:originais/controllers/bd_monthlypayments_controller.dart';

class MonthlyPaymentsImageService extends BaseImageUploadService {
  final SupabaseClient supabaseClient = 
      getItMySupabaseClient<MySupabaseClient>().getSupabaseClient();

  final bdMonthlyPaymentsController = getItbdMonthlyPaymentsController<BdMonthlyPaymentsController>();
  
 MonthlyPaymentsImageService({
    ValueNotifier<bool>? loadingNotifier,
    ValueNotifier<String?>? errorNotifier,
  }) : super(
          loadingNotifier: loadingNotifier ?? ValueNotifier<bool>(false),
          errorNotifier: errorNotifier ?? ValueNotifier<String?>(null),
        );
  
  // ==========================================
  @override
  Future<String> fazerUploadStorage(
    ProcessedImageData imageData, 
    Map<String, dynamic>? payload,
  ) async {
    final String pfl_id = payload?['pfl_id'];
    final String hld_id = payload?['hld_id'];
    final String ano = payload?['ano'];
    final String mes = payload?['mes'];

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${pfl_id}/${ano}_${mes}_monthypayments_$timestamp.${imageData.extension}';

    await supabaseClient.storage
        .from('monthypayments')
        .uploadBinary(
          filePath,
          imageData.bytes,
          fileOptions: FileOptions(upsert: true, contentType: imageData.mimeType),
        );

    return supabaseClient.storage.from('monthypayments').getPublicUrl(filePath);
  }

  // ==========================================
  @override
  Future<void> atualizarBancoDados(
    String imageUrl, 
    Map<String, dynamic>? payload,
  ) async {
    final String pfl_id = payload?['pfl_id'];
    final String hld_id = payload?['hld_id'];
    final String ano = payload?['ano'];
    final String mes = payload?['mes'];
    
    await bdMonthlyPaymentsController.updateCheckingCopy(pfl_id, hld_id, mes, ano, imageUrl);
  }

}