class PaymentValueModel {
  String vpg_id;
  String vpg_desc;
  
  String vpg_valor_normal;
  String vpg_dia_valor_normal;
  String vpg_valor_desconto;
  String vpg_dia_valor_desconto;

  // ==========================================
  PaymentValueModel ( {
    required this.vpg_id,
    required this.vpg_desc,
    required this.vpg_valor_normal,
    required this.vpg_dia_valor_normal,
    required this.vpg_valor_desconto,
    required this.vpg_dia_valor_desconto
  } );

  // ==========================================
  factory PaymentValueModel
    .fromJson(Map<String, dynamic> json)
  {
    return PaymentValueModel(
      vpg_id: json['vpg_id']?.toString() ?? '',
      vpg_desc: json['vpg_desc']?.toString() ?? '',
      vpg_valor_normal: json['vpg_valor_normal']?.toString() ?? '',
      vpg_dia_valor_normal: json['vpg_dia_valor_normal']?.toString() ?? '',
      vpg_valor_desconto: json['vpg_valor_desconto']?.toString() ?? '',
      vpg_dia_valor_desconto: json['vpg_dia_valor_desconto']?.toString() ?? '',
    );
  }

  // ==========================================
  Map<String, dynamic> toJson() {
    return {
      'vpg_id': vpg_id,
      'vpg_desc': vpg_desc,
      'vpg_valor_normal': vpg_valor_normal,
      'vpg_dia_valor_normal': vpg_dia_valor_normal,
      'vpg_valor_desconto': vpg_valor_desconto,
      'vpg_dia_valor_desconto': vpg_dia_valor_desconto,
    };
  }

}
