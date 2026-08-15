import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gorouter_exemplo/models/profile_model.dart';

class BdProfileService {
  final supabaseProfiles = Supabase.instance.client;
  
  Future<Map<String, dynamic>?> checkProfileExist( String id ) async {
    return await supabaseProfiles
        .from( 'profiles' )
        .select()
        .eq( 'id', id )
        .maybeSingle();
  }

    // 1. READ
  Future<List<ProfileModel>> readProfiles() async {
    final resposta = await supabaseProfiles
        .from('profiles')
        .select()
        .order('full_name', ascending: true);

    // Converte a lista de mapas (JSON) que vem do Supabase para a nossa lista de ItemModel
    // return resposta.map((item) {ProfileModel.fromJson( item );}).toList();
    return resposta.map((item) => ProfileModel.fromJson(item)).toList();

    // return resposta.map((json) {
    //   return ProfileModel(
    //     id: json['id'] as String,
    //     updated_at: json['updated_at'] as String,
    //     full_name: json['full_name'] as String,
    //     nickname: json['nickname'] as String,
    //     avatar_url: json['avatar_url'] as String,
    //     bio: json['bio'] as String
    //   );
    // }).toList();
  }

  Future<void> inupsertProfile( ProfileModel profileData ) async {
    await supabaseProfiles.from( 'profiles' )
    .upsert( profileData.toJson() );
  }

  Future<void> updateAvatar( String id, String avatarUrl ) async {
    await supabaseProfiles.from( 'profiles' )
    .update({
      'updated_at': DateTime.now().toIso8601String(),
      'avatar_url': avatarUrl })
    .eq('id', id);
  }

}
