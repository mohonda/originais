class ProfileModel {
  String pfl_id;
  String hld_id;
  String pfl_updated_at;
  String pfl_full_name;
  String pfl_nick_name;
  String pfl_avatar_url;
  String pfl_bio;

  // ==========================================
  ProfileModel ( {
    required this.pfl_id,
    required this.hld_id,
    required this.pfl_updated_at,
    required this.pfl_full_name,
    required this.pfl_nick_name,
    required this.pfl_avatar_url,
    required this.pfl_bio
  } );

  // ==========================================
  factory ProfileModel
    .fromJson(Map<String, dynamic> json)
  {
    return ProfileModel(
      pfl_id: json['pfl_id'] as String,
      hld_id: json['hld_id']?.toString() ?? '',
      pfl_updated_at: json['pfl_updated_at'] as String? ?? '',
      pfl_full_name: json['pfl_full_name'] as String? ?? '',
      pfl_nick_name: json['pfl_nick_name'] as String? ?? '',
      pfl_avatar_url: json['pfl_avatar_url'] as String? ?? '',
      pfl_bio: json['pfl_bio'] as String? ?? '',
    );
  }

  // ==========================================
  Map<String, dynamic> toJson() {
    return {
      if ( pfl_id.isNotEmpty ) 
      'pfl_id': pfl_id,
      'hld_id': hld_id,
      'pfl_updated_at': pfl_updated_at,
      'pfl_full_name': pfl_full_name,
      'pfl_nick_name': pfl_nick_name,
      'pfl_avatar_url': pfl_avatar_url,
      'pfl_bio': pfl_bio,
    };
  }

}
