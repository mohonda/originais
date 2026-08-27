class VMensalidadeDistinctModel {
  String mes_mes_referencia;
  String mes_ano_referencia;

  String mes_hld_id;
  String hld_name;
  
  String mes_vpg_id;
  String vpg_valor_normal;
  String vpg_dia_valor_normal;
  String vpg_valor_desconto;
  String vpg_dia_valor_desconto;

  // ==========================================
  VMensalidadeDistinctModel ( {
    required this.mes_mes_referencia,
    required this.mes_ano_referencia,

    required this.mes_hld_id,
    required this.hld_name,

    required this.mes_vpg_id,
    required this.vpg_valor_normal,
    required this.vpg_dia_valor_normal,
    required this.vpg_valor_desconto,
    required this.vpg_dia_valor_desconto
  } );

  // ==========================================
  factory VMensalidadeDistinctModel
    .fromJson(Map<String, dynamic> json)
  {
    return VMensalidadeDistinctModel(
      mes_mes_referencia: json['mes_mes_referencia']?.toString() ?? '',
      mes_ano_referencia: json['mes_ano_referencia']?.toString() ?? '',

      mes_hld_id: json['mes_hld_id']?.toString() ?? '',
      hld_name: json['hld_name']?.toString() ?? '',

      mes_vpg_id: json['mes_vpg_id']?.toString() ?? '',
      vpg_valor_normal: json['vpg_valor_normal']?.toString() ?? '',
      vpg_dia_valor_normal: json['vpg_dia_valor_normal']?.toString() ?? '',
      vpg_valor_desconto: json['vpg_valor_desconto']?.toString() ?? '',
      vpg_dia_valor_desconto: json['vpg_dia_valor_desconto']?.toString() ?? '',
    );
  }

  // ==========================================
  Map<String, dynamic> toJson() {
    return {
      'mes_mes_referencia': mes_mes_referencia,
      'mes_ano_referencia': mes_ano_referencia,
      
      'mes_hld_id': mes_hld_id,
      'hld_name': hld_name,

      'mes_vpg_id': mes_vpg_id,
      'vpg_valor_normal': vpg_valor_normal,
      'vpg_dia_valor_normal': vpg_dia_valor_normal,
      'vpg_valor_desconto': vpg_valor_desconto,
      'vpg_dia_valor_desconto': vpg_dia_valor_desconto,
    };
  }

}
