import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:gorouter_exemplo/models/profile_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gorouter_exemplo/services/my_supabase_client_service.dart';

final getItBdProfileController = GetIt.instance;

void setupGetItProfileBdItemController() {
  getItBdProfileController.registerLazySingleton<BdProfileController>(
    () => BdProfileController(),
  );
}

class BdProfileController extends ChangeNotifier {
  final mySupabaseClient = getItMySupabaseClient<MySupabaseClient>();
  late SupabaseClient supabaseClient;


  final ValueNotifier<List<ProfileModel>> profilesNotifier =
      ValueNotifier<List<ProfileModel>>([]);

  final ValueNotifier<ProfileModel?> pessoaSelecionadaNotifier =
      ValueNotifier<ProfileModel?>(null);

  final ValueNotifier<bool> loadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<bool> isChangedNotifier = ValueNotifier<bool>(false);
  
  // ==========================================
  BdProfileController() {
    supabaseClient = mySupabaseClient.getSupabaseClient();
  }

  // ==========================================
  void changedNotifier(bool value) {
    isChangedNotifier.value = value;
  }

  // ==========================================
  Future<void> loadProfiles() async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final resposta = await supabaseClient
        .from('profiles')
        .select()
        .eq('hld_id', '1')
        .order('pfl_full_name', ascending: true);

      profilesNotifier.value = resposta.map((item) =>
        ProfileModel.fromJson(item)).toList();
    
    } catch ( e, stackTrace ) {
      profilesNotifier.value = [];
      errorNotifier.value = "BdProfileController::loadProfiles: $e \n$stackTrace";
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> fetchProfilesById( String id ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final data = await supabaseClient
        .from( 'profiles' )
        .select()
        .eq( 'pfl_id', id )
        .eq('hld_id', '1')
        .maybeSingle();

      if ( data != null ) {
        pessoaSelecionadaNotifier.value = ProfileModel.fromJson(data);
      } else {
        pessoaSelecionadaNotifier.value = null;
        errorNotifier.value = 'BdProfileController::fetchProfilesById: Registro não encontrado.';
      }

    } catch ( e, stackTrace ) {
      pessoaSelecionadaNotifier.value = null;
      errorNotifier.value = "BdProfileController::fetchProfilesById: $e \n$stackTrace";
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> checkUserProfileExist( String id ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final data = await supabaseClient
        .from( 'profiles' )
        .select()
        .eq( 'pfl_id', id )
        .eq('hld_id', '1')
        .maybeSingle();

      if ( data != null ) {
        pessoaSelecionadaNotifier.value = ProfileModel.fromJson( data );
      } else {
        final profileData = ProfileModel(
          pfl_id: id,
          hld_id: '1',
          pfl_updated_at: DateTime.now().toIso8601String(),
          pfl_full_name: "Name",
          pfl_nick_name: "",
          pfl_avatar_url: "",
          pfl_bio: "",
        );

        await supabaseClient
          .from( 'profiles' )
          .upsert( profileData.toJson() );

        await fetchProfilesById( id );
      }
    } catch ( e, stackTrace ) {
      pessoaSelecionadaNotifier.value = null;
      errorNotifier.value = "BdProfileController::checkUserProfileExist: $e \n$stackTrace";
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
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
        pfl_id: id,
        hld_id: '1',
        pfl_updated_at: DateTime.now().toIso8601String(),
        pfl_full_name: fullname,
        pfl_nick_name: nickname,
        pfl_avatar_url: avatarurl,
        pfl_bio: bio,
      );

      await supabaseClient
        .from( 'profiles' )
        .upsert( profileData.toJson() );
      
      await fetchProfilesById( id );

    } catch ( e, stackTrace ) {
      pessoaSelecionadaNotifier.value = null;
      errorNotifier.value = "BdProfileController::updateProfile: $e \n$stackTrace";
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future selecionarEEnviarFoto() async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final picker = ImagePicker();
      String? imageUrl = "";

      final userId = mySupabaseClient.getUserId();

      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 60,
      );

      if ( image == null ){
        return null;
      } 

      final bytes = await image.readAsBytes();
      final fileExt = image.name.split('.').last;
      final dateTime = DateTime.now().toIso8601String();
      final filePath = '$userId/profile_picture_$dateTime.$fileExt';

      try {
        await supabaseClient.storage
          .from( 'avatars' )
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      } on StorageException catch (e) {
        errorNotifier.value = 'Erro de Storage no Supabase: ${e.message} (Status: ${e.statusCode})';
        rethrow; // Ou trate com uma mensagem para a UI / SnackBar
      } catch (e, stackTrace) {
        errorNotifier.value = 'Erro inesperado durante o upload: $e\n$stackTrace';
        rethrow;
      }

      try {
        imageUrl = supabaseClient.storage
          .from( 'avatars' )
          .getPublicUrl( filePath );
          
        await updateAvatar( userId, imageUrl );

      } on StorageException catch (e) {
        errorNotifier.value = 'Erro de Storage no Supabase: ${e.message} (Status: ${e.statusCode})';
        rethrow; // Ou trate com uma mensagem para a UI / SnackBar
      } catch (e, stackTrace) {
        errorNotifier.value = 'Erro inesperado durante getPublicUrl: $e\n$stackTrace';
        rethrow;
      }
    } catch ( e, stackTrace ) {
      pessoaSelecionadaNotifier.value = null;
      errorNotifier.value = "BdProfileController::updateProfile: $e \n$stackTrace";
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> updateAvatar( String id, String avatarUrl ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      await supabaseClient
        .from( 'profiles' )
        .update({
          'pfl_updated_at': DateTime.now().toIso8601String(),
          'pfl_avatar_url': avatarUrl })
        .eq('pfl_id', id)
        .eq('hld_id', '1');

      await fetchProfilesById( id );

    } catch ( e, stackTrace ) {
      pessoaSelecionadaNotifier.value = null;
      errorNotifier.value = "BdProfileController::updateAvatar: $e \n$stackTrace";
    } finally {
      loadingNotifier.value = false;
    }
  }
}
