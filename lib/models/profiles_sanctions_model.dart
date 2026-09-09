class VProfilesSanctionsModel {
  String psan_id;
  
  String psan_pfl_id;
  String psan_hld_id;
  String pfl_full_name;
  
  String psan_san_id;
  String san_name;

  String psan_valor;
  String psan_date_start;
  String psan_date_end;
  String psan_desc;

  // ==========================================
  VProfilesSanctionsModel ( {
    required this.psan_id,

    required this.psan_pfl_id,
    required this.psan_hld_id,
    required this.pfl_full_name,

    required this.psan_san_id,
    required this.san_name,

    required this.psan_valor,
    required this.psan_date_start,
    required this.psan_date_end,
    required this.psan_desc
  } );

  // ==========================================
  factory VProfilesSanctionsModel
    .fromJson(Map<String, dynamic> json)
  {
    return VProfilesSanctionsModel(
      psan_id: json['psan_id']?.toString() ?? '',

      psan_pfl_id: json['psan_pfl_id'] as String,
      psan_hld_id: json['psan_hld_id']?.toString() ?? '',
      pfl_full_name: json['pfl_full_name']?.toString() ?? '',

      psan_san_id: json['psan_san_id']?.toString() ?? '',
      san_name: json['san_name']?.toString() ?? '',

      psan_valor: json['psan_valor']?.toString() ?? '',
      psan_date_start: json['psan_date_start']?.toString() ?? '',
      psan_date_end: json['psan_date_end']?.toString() ?? '',
      psan_desc: json['psan_desc']?.toString() ?? '',
    );
  }

  // ==========================================
  Map<String, dynamic> toJson() {
    return {
      if ( psan_id.isNotEmpty ) 
      'psan_id': psan_id,
      
      'psan_pfl_id': psan_pfl_id,
      'psan_hld_id': psan_hld_id,
      'pfl_full_name': pfl_full_name,

      'psan_san_id': psan_san_id,
      'san_name': san_name,

      'psan_valor': psan_valor,
      'psan_date_start': psan_date_start,
      'psan_date_end': psan_date_end,
      'psan_desc': psan_desc,
    };
  }

}
