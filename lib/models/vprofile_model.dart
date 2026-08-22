class VProfileModel {
  String pfl_id;
  String hld_id;
  String hld_name;

  String pfl_full_name;
  String pfl_nick_name;
  String pfl_avatar_url;
  String pfl_bio;
  String pfl_updated_at;

  String as_id;
  String as_desc;
  String ismonthlypayment;
    
  String monthly_percent;
  String data_status;

  String jr_level;
  String jr_nome;
  String data_promocao;

  // ==========================================
  VProfileModel ( {
    required this.pfl_id,
    required this.hld_id,
    required this.hld_name,

    required this.pfl_full_name,
    required this.pfl_nick_name,
    required this.pfl_avatar_url,
    required this.pfl_bio,
    required this.pfl_updated_at,

    required this.as_id,
    required this.as_desc,
    required this.ismonthlypayment,
    
    required this.monthly_percent,
    required this.data_status,

    required this.jr_level,
    required this.jr_nome,
    required this.data_promocao
  } );

  // ==========================================
  factory VProfileModel
    .fromJson(Map<String, dynamic> json)
  {
    return VProfileModel(
      pfl_id: json['pfl_id'] as String,
      hld_id: json['hld_id']?.toString() ?? '',
      hld_name: json['hld_name']?.toString() ?? '',

      pfl_full_name: json['pfl_full_name'] as String? ?? '',
      pfl_nick_name: json['pfl_nick_name'] as String? ?? '',
      pfl_avatar_url: json['pfl_avatar_url'] as String? ?? '',
      pfl_bio: json['pfl_bio'] as String? ?? '',
      pfl_updated_at: json['pfl_updated_at'] as String? ?? '',

      as_id: json['as_id']?.toString() ?? '',
      as_desc: json['as_desc'] as String? ?? '',
      ismonthlypayment: json['ismonthlypayment']?.toString() ?? '',

      monthly_percent: json['monthly_percent']?.toString() ?? '',
      data_status: json['data_status'] as String? ?? '',

      jr_level: json['jr_level']?.toString() ?? '',
      jr_nome: json['jr_nome']?.toString() ?? '',
      data_promocao: json['data_promocao']?.toString() ?? '',
    );
  }

  // ==========================================
  Map<String, dynamic> toJson() {
    return {
      if ( pfl_id.isNotEmpty ) 
      'pfl_id': pfl_id,
      'hld_id': hld_id,
      'hld_name': hld_name,

      'pfl_full_name': pfl_full_name,
      'pfl_nick_name': pfl_nick_name,
      'pfl_avatar_url': pfl_avatar_url,
      'pfl_bio': pfl_bio,
      'pfl_updated_at': pfl_updated_at,

      'as_id': as_id,
      'as_desc': as_desc,
      'ismonthlypayment': ismonthlypayment,

      'monthly_percent': monthly_percent,
      'date_update_status': data_status,

      'jr_level': jr_level,
      'jr_nome': jr_nome,
      'data_promocao': data_promocao,
    };
  }

}
