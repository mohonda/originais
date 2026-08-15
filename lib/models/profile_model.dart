class ProfileModel {
  String id;
  String updated_at;
  String full_name;
  String nickname;
  String avatar_url;
  String bio;

  ProfileModel ( {
    required this.id,
    required this.updated_at,
    required this.full_name,
    required this.nickname,
    required this.avatar_url,
    required this.bio,
  } );

  // Converte o JSON vindo do Supabase em um objeto PessoaModel
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      updated_at: json['updated_at'] as String? ?? '',
      full_name: json['full_name'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      avatar_url: json['avatar_url'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
    );
  }

  // Converte o objeto PessoaModel para formato JSON aceito pelo Supabase
  Map<String, dynamic> toJson() {
    return {
      if ( id.isNotEmpty ) 
      'id': id,
      'updated_at': updated_at,
      'full_name': full_name,
      'nickname': nickname,
      'avatar_url': avatar_url,
      'bio': bio,
    };
  }

}
