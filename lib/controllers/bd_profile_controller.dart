import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:originais/models/profile_model.dart';
import 'package:originais/models/vprofile_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:originais/services/my_supabase_client_service.dart';

final getItBdProfileController = GetIt.instance;

void setupGetItProfileBdItemController() {
  getItBdProfileController.registerLazySingleton<BdProfileController>(
    () => BdProfileController(),
  );
}

class BdProfileController extends ChangeNotifier {
  final mySupabaseClient = getItMySupabaseClient<MySupabaseClient>();
  late SupabaseClient supabaseClient;


  final ValueNotifier<List<VProfileModel>> profilesNotifier =
      ValueNotifier<List<VProfileModel>>([]);

  final ValueNotifier<VProfileModel?> pessoaSelecionadaNotifier =
      ValueNotifier<VProfileModel?>(null);

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
  Future<void> loadProfiles( String hld_id ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      // final resposta = await supabaseClient
      final resposta = await mySupabaseClient.safePostgrestCall(()=>
        supabaseClient
        .from('vprofile')
        .select()
        .eq('hld_id', hld_id )
        .order('as_id', ascending: true)
        .order('pfl_full_name', ascending: true)
      );

      profilesNotifier.value = resposta.map((item) =>
        VProfileModel.fromJson(item)).toList();
    
    } catch ( e, stackTrace ) {
      profilesNotifier.value = [];
      errorNotifier.value = "BdProfileController::loadProfiles: $e \n$stackTrace";
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> fetchProfilesById( String id, String hld_id ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final resposta = await mySupabaseClient.safePostgrestCall(()=>
        supabaseClient
        .from( 'vprofile' )
        .select()
        .eq( 'pfl_id', id )
        .eq('hld_id', hld_id )
        .maybeSingle()
      );

      if ( resposta != null ) {
        pessoaSelecionadaNotifier.value = VProfileModel.fromJson(resposta);
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

      final resposta = await mySupabaseClient.safePostgrestCall(()=>
        supabaseClient
        .from( 'vprofile' )
        .select()
        .eq( 'pfl_id', id )
        .maybeSingle()
      );

      if ( resposta != null ) {
        pessoaSelecionadaNotifier.value = VProfileModel.fromJson( resposta );
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

        await fetchProfilesById( id, '1' );
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
    String hld_id,
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
        hld_id: hld_id,
        pfl_updated_at: DateTime.now().toIso8601String(),
        pfl_full_name: fullname,
        pfl_nick_name: nickname,
        pfl_avatar_url: avatarurl,
        pfl_bio: bio,
      );

      await supabaseClient
        .from( 'profiles' )
        .upsert( profileData.toJson() );
      
      await fetchProfilesById( id, hld_id );

    } catch ( e, stackTrace ) {
      pessoaSelecionadaNotifier.value = null;
      errorNotifier.value = "BdProfileController::updateProfile: $e \n$stackTrace";
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> updateAvatar( String pfl_id, String hld_id, String avatarUrl ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      await supabaseClient
        .from( 'profiles' )
        .update({
          'pfl_updated_at': DateTime.now().toIso8601String(),
          'pfl_avatar_url': avatarUrl })
        .eq('pfl_id', pfl_id)
        .eq('hld_id', hld_id);

      await fetchProfilesById( pfl_id, hld_id );

    } catch ( e, stackTrace ) {
      pessoaSelecionadaNotifier.value = null;
      errorNotifier.value = "BdProfileController::updateAvatar: $e \n$stackTrace";
    } finally {
      loadingNotifier.value = false;
    }
  }
}
