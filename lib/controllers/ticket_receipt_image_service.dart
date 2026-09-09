import 'package:originais/services/base_image_upload_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:originais/services/my_supabase_client_service.dart';
import 'package:originais/controllers/ticket_controller.dart';

class TicketReceiptImageService extends BaseImageUploadService {
  final SupabaseClient supabaseClient = 
      getItMySupabaseClient<MySupabaseClient>().getSupabaseClient();

  final ticketController = getItTicketController<TicketController>();
  
  TicketReceiptImageService({
    required super.loadingNotifier,
    required super.errorNotifier,
  });

  // ==========================================
  @override
  Future<String> fazerUploadStorage(
    ProcessedImageData imageData, 
    Map<String, dynamic>? payload,
  ) async {
    final String tkt_id = payload?['tkt_id'];
    final String pfl_id = payload?['pfl_id'];
    final String tkt_tst_id = payload?['tkt_tst_id'];
    final String openDate = payload?['openDate'];
    final String hld_id = payload?['hld_id'];

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${pfl_id}/${tkt_id}_tickets_$timestamp.${imageData.extension}';

    await supabaseClient.storage
        .from('tickets')
        .uploadBinary(
          filePath,
          imageData.bytes,
          fileOptions: FileOptions(upsert: true, contentType: imageData.mimeType),
        );

    return supabaseClient.storage.from('tickets').getPublicUrl(filePath);
  }

  // ==========================================
  @override
  Future<void> atualizarBancoDados(
    String imageUrl, 
    Map<String, dynamic>? payload,
  ) async {
    final String tkt_id = payload?['tkt_id'];
    final String pfl_id = payload?['pfl_id'];
    final String tkt_tst_id = payload?['tkt_tst_id'];
    final String openDate = payload?['openDate'];
    final String hld_id = payload?['hld_id'];

    await supabaseClient
        .from('tickets')
        .update({
          'tkt_paiment_path': imageUrl,
          'tkt_tst_id': tkt_tst_id,
        })
        .eq('tkt_id', tkt_id);
    
    await ticketController.loadTickets( openDate, hld_id );
  }

}