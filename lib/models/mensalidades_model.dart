class MensalidadesModel {
  String mes_mes_referencia;
  String mes_ano_referencia;
  String mes_pfl_id;
  String mes_hld_id;

  String pfl_full_name;

  String mes_vpg_id;
  String mes_vpg_hld_id;

  String vpg_valor_normal;
  String vpg_dia_valor_normal;
  String vpg_valor_desconto;
  String vpg_dia_valor_desconto;

  String mes_valor;
  String mes_data_pagamento;
  String mes_comprovante_pag;

  String mes_fpg_id;
  String mes_fpg_hld_id;
  String fpg_descricao;

  String mes_data_confirmacao;

  String mes_pfl_id_confirmacao;
  String mes_hld_id_confirmacao;
  String mes_full_name_confirmacao;

  // ==========================================
  MensalidadesModel ( {
    required this.mes_mes_referencia,
    required this.mes_ano_referencia,
    required this.mes_pfl_id,
    required this.mes_hld_id,
    required this.pfl_full_name,

    required this.mes_vpg_id,
    required this.mes_vpg_hld_id,
    required this.vpg_valor_normal,
    required this.vpg_dia_valor_normal,
    required this.vpg_valor_desconto,
    required this.vpg_dia_valor_desconto,

    required this.mes_valor,
    required this.mes_data_pagamento,
    required this.mes_comprovante_pag,

    required this.mes_fpg_id,
    required this.mes_fpg_hld_id,
    required this.fpg_descricao,

    required this.mes_data_confirmacao,

    required this.mes_pfl_id_confirmacao,
    required this.mes_hld_id_confirmacao,
    required this.mes_full_name_confirmacao
  } );

   // ==========================================
  factory MensalidadesModel
  .fromJson(Map<String, dynamic> json)
  {
      return MensalidadesModel(
        mes_mes_referencia: json['mes_mes_referencia']?.toString() ?? "",
        mes_ano_referencia: json['mes_ano_referencia']?.toString() ?? "",
        mes_pfl_id: json['mes_pfl_id']?.toString() ?? "",
        mes_hld_id: json['mes_hld_id']?.toString() ?? "",

        pfl_full_name: json['pfl_full_name']?.toString() ?? "",


        mes_vpg_id: json['mes_vpg_id']?.toString() ?? "",
        mes_vpg_hld_id: json['mes_vpg_hld_id']?.toString() ?? "",

        vpg_valor_normal: json['vpg_valor_normal']?.toString() ?? "",
        vpg_dia_valor_normal: json['vpg_dia_valor_normal']?.toString() ?? "",
        vpg_valor_desconto: json['vpg_valor_desconto']?.toString() ?? "",
        vpg_dia_valor_desconto: json['vpg_dia_valor_desconto']?.toString() ?? "",


        mes_valor: json['mes_valor']?.toString() ?? "",
        mes_data_pagamento: json['mes_data_pagamento']?.toString() ?? "",
        mes_comprovante_pag: json['mes_comprovante_pag']?.toString() ?? "",

        mes_fpg_id: json['mes_fpg_id']?.toString() ?? "",
        mes_fpg_hld_id: json['mes_fpg_hld_id']?.toString() ?? "",
        fpg_descricao: json['fpg_descricao']?.toString() ?? "",

        mes_data_confirmacao: json['mes_data_confirmacao']?.toString() ?? "",
        
        mes_pfl_id_confirmacao: json['mes_pfl_id_confirmacao']?.toString() ?? "",
        mes_hld_id_confirmacao: json['mes_hld_id_confirmacao']?.toString() ?? "",
        mes_full_name_confirmacao: json['mes_full_name_confirmacao']?.toString() ?? "",
    );
  }

}
