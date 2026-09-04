import 'package:flutter/material.dart';
import 'package:originais/services/BaseImageUploadService.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:originais/services/my_supabase_client_service.dart';
import 'package:originais/controllers/bd_profile_controller.dart';

class ProfileImageService extends BaseImageUploadService {
  final SupabaseClient supabaseClient =
      getItMySupabaseClient<MySupabaseClient>().getSupabaseClient();

  final bdProfileController = getItBdProfileController<BdProfileController>();

  ProfileImageService({
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

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${pfl_id}/avatars_$timestamp.${imageData.extension}';

    await supabaseClient.storage
        .from('avatars')
        .uploadBinary(
          filePath,
          imageData.bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: imageData.mimeType,
          ),
        );

    return supabaseClient.storage.from('avatars').getPublicUrl(filePath);
  }

  // ==========================================
  @override
  Future<void> atualizarBancoDados(
    String imageUrl,
    Map<String, dynamic>? payload,
  ) async {
    final String pfl_id = payload?['pfl_id'];
    final String hld_id = payload?['hld_id'];

    await bdProfileController.updateAvatar(pfl_id, hld_id, imageUrl);
  }
}
