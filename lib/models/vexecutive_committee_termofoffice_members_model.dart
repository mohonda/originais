class VExecutiveCommitteeTermOfOfficeMembersModel {
  String ectm_id;
  
  String ectm_ect_id;
  String ect_name;
  String ect_date_start;
  String ect_date_end;
  
  String ectm_ecm_id;
  String ecm_name;

  String ectm_pfl_id;
  String ectm_hld_id;
  String pfl_full_name;
  
  String ectm_date_start;
  String ectm_date_end;
  String ectm_motivo_saida;

  // ==========================================
  VExecutiveCommitteeTermOfOfficeMembersModel ( {
    required this.ectm_id,

    required this.ectm_ect_id,
    required this.ect_name,
    required this.ect_date_start,
    required this.ect_date_end,

    required this.ectm_ecm_id,
    required this.ecm_name,

    required this.ectm_pfl_id,
    required this.ectm_hld_id,
    required this.pfl_full_name,
    
    required this.ectm_date_start,
    required this.ectm_date_end,
    required this.ectm_motivo_saida,
  } );

  // ==========================================
  factory VExecutiveCommitteeTermOfOfficeMembersModel
    .fromJson(Map<String, dynamic> json)
  {
    return VExecutiveCommitteeTermOfOfficeMembersModel(
      ectm_id: json['ectm_id']?.toString() ?? '',

      ectm_ect_id: json['ectm_ect_id']?.toString() ?? '',
      ect_name: json['ect_name']?.toString() ?? '',
      ect_date_start: json['ect_date_start']?.toString() ?? '',
      ect_date_end: json['ect_date_end']?.toString() ?? '',

      ectm_ecm_id: json['ectm_ecm_id']?.toString() ?? '',
      ecm_name: json['ecm_name']?.toString() ?? '',

      ectm_pfl_id: json['ectm_pfl_id'] as String,
      ectm_hld_id: json['ectm_hld_id']?.toString() ?? '',
      pfl_full_name: json['pfl_full_name']?.toString() ?? '',

      ectm_date_start: json['ectm_date_start']?.toString() ?? '',
      ectm_date_end: json['ectm_date_end']?.toString() ?? '',
      ectm_motivo_saida: json['ectm_motivo_saida']?.toString() ?? '',
    );
  }

  // ==========================================
  Map<String, dynamic> toJson() {
    return {
      'ectm_id': ectm_id,
      
      'ectm_ect_id': ectm_ect_id,
      'ect_name': ect_name,
      'ect_date_start': ect_date_start,
      'ect_date_end': ect_date_end,

      'ectm_ecm_id': ectm_ecm_id,
      'ecm_name': ecm_name,

      'ectm_pfl_id': ectm_pfl_id,
      'ectm_hld_id': ectm_hld_id,
      'pfl_full_name': pfl_full_name,

      'ectm_date_start': ectm_date_start,
      'ectm_date_end': ectm_date_end,
      'ectm_motivo_saida': ectm_motivo_saida,
    };
  }

}
