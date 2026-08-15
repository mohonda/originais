import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:gorouter_exemplo/models/profile_model.dart';
import 'package:gorouter_exemplo/services/bd_profile_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final getItBdProfileController = GetIt.instance;

void setupGetItProfileBdItemController() {
  getItBdProfileController.registerLazySingleton<BdProfileController>(
    () => BdProfileController(),
  );
}

class BdProfileController extends ChangeNotifier {
  final BdProfileService bdProfileService = BdProfileService();

  final ValueNotifier<List<ProfileModel>> profilesNotifier =
      ValueNotifier<List<ProfileModel>>([]);
  final ValueNotifier<ProfileModel?> pessoaSelecionadaNotifier =
      ValueNotifier<ProfileModel?>(null);
  final ValueNotifier<bool> loadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<bool> isChangedNotifier = ValueNotifier<bool>(false);

  void changedNotifier(bool value) {
    isChangedNotifier.value = value;
  }

  Future<void> loadProfiles() async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      profilesNotifier.value = await bdProfileService.readProfiles();
    } catch (e) {
      profilesNotifier.value = ([]);
      errorNotifier.value = 'BdProfileController::loadProfiles: $e';
    } finally {
      loadingNotifier.value = false;
    }
  }

  Future<void> fetchProfilesById(String id) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final data = await bdProfileService.checkProfileExist(id);

      if (data != null) {
        pessoaSelecionadaNotifier.value = ProfileModel.fromJson(data);
      } else {
        pessoaSelecionadaNotifier.value = null;
        errorNotifier.value = 'Registro não encontrado.';
      }
    } catch (e) {
      pessoaSelecionadaNotifier.value = null;
      errorNotifier.value = 'BdProfileController::fetchProfilesById: $e';
    } finally {
      loadingNotifier.value = false;
    }
  }

  Future<void> checkUserProfileExist(String id) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final data = await bdProfileService.checkProfileExist(id);

      if (data != null) {
        pessoaSelecionadaNotifier.value = ProfileModel.fromJson(data);
      } else {
        final profileData = ProfileModel(
          id: id,
          updated_at: DateTime.now().toIso8601String(),
          full_name: "Name",
          nickname: "",
          avatar_url: "",
          bio: "",
        );

        await bdProfileService.inupsertProfile(profileData);
        await fetchProfilesById(id);
      }
    } catch (e) {
      pessoaSelecionadaNotifier.value = null;
      errorNotifier.value = 'BdProfileController::checkUserProfileExist: $e';
    } finally {
      loadingNotifier.value = false;
    }
  }

  Future<void> updateProfile(
    String id,
    String fullname,
    String nickname,
    String avatarurl,
    String bio,
  ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final profileData = ProfileModel(
        id: id,
        updated_at: DateTime.now().toIso8601String(),
        full_name: fullname,
        nickname: nickname,
        avatar_url: avatarurl,
        bio: bio,
      );

      await bdProfileService.inupsertProfile(profileData);
      await fetchProfilesById(id);
    } catch (e) {
      pessoaSelecionadaNotifier.value = null;
      errorNotifier.value = 'BdProfileController::updateProfile: $e';
    } finally {
      loadingNotifier.value = false;
    }
  }

  Future selecionarEEnviarFoto() async {
    final supabase = Supabase.instance.client;
    final picker = ImagePicker();

    // Abre a galeria
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // Reduz o tamanho do arquivo para melhorar performance
    );

    if (image == null) return null; // Usuário cancelou a seleção

    final bytes = await image.readAsBytes();
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) return null;

    final fileExt = image.name.split('.').last;
    final dateTime = DateTime.now().toIso8601String();
    final filePath = '$userId/profile_picture_$dateTime.$fileExt';

    // Upload para o Supabase Storage (upsert: true substitui a foto antiga se existir)
    await supabase.storage
        .from('avatars')
        .uploadBinary(
          filePath,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    // Pega a URL pública gerada
    final imageUrl = supabase.storage.from('avatars').getPublicUrl(filePath);

    // Salva a URL no perfil do banco de dados
    updateAvatar( userId, imageUrl );
    
    return imageUrl;
  }

   Future<void> updateAvatar( String id, String avatarUrl ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      await bdProfileService.updateAvatar( id, avatarUrl );
      await fetchProfilesById(id);
    } catch (e) {
      pessoaSelecionadaNotifier.value = null;
      errorNotifier.value = 'BdProfileController::updateAvatar: $e';
    } finally {
      loadingNotifier.value = false;
    }
  }
}
