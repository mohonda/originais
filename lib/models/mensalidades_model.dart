// class MensalidadesModel {
//   String mes_mes_referencia;
//   String mes_ano_referencia;
//   String mes_pfl_id;
//   String mes_hld_id;

//   String pfl_full_name;

//   String mes_vpg_id;
//   String mes_vpg_hld_id;

//   String vpg_valor_normal;
//   String vpg_dia_valor_normal;
//   String vpg_valor_desconto;
//   String vpg_dia_valor_desconto;
//   String vpg_desc;

//   String mes_valor;
//   String mes_data_pagamento;
//   String mes_comprovante_pag;

//   String mes_fpg_id;
//   String mes_fpg_hld_id;
//   String fpg_descricao;

//   String mes_data_confirmacao;

//   String mes_pfl_id_confirmacao;
//   String mes_hld_id_confirmacao;
//   String mes_full_name_confirmacao;

//   String mes_monthly_percent;

//   // ==========================================
//   MensalidadesModel ( {
//     required this.mes_mes_referencia,
//     required this.mes_ano_referencia,
//     required this.mes_pfl_id,
//     required this.mes_hld_id,
//     required this.pfl_full_name,

//     required this.mes_vpg_id,
//     required this.mes_vpg_hld_id,
//     required this.vpg_valor_normal,
//     required this.vpg_dia_valor_normal,
//     required this.vpg_valor_desconto,
//     required this.vpg_dia_valor_desconto,
//     required this.vpg_desc,

//     required this.mes_valor,
//     required this.mes_data_pagamento,
//     required this.mes_comprovante_pag,

//     required this.mes_fpg_id,
//     required this.mes_fpg_hld_id,
//     required this.fpg_descricao,

//     required this.mes_data_confirmacao,

//     required this.mes_pfl_id_confirmacao,
//     required this.mes_hld_id_confirmacao,
//     required this.mes_full_name_confirmacao,
    
//     required this.mes_monthly_percent
//   } );

//    // ==========================================
//   factory MensalidadesModel
//   .fromJson(Map<String, dynamic> json)
//   {
//       return MensalidadesModel(
//         mes_mes_referencia: json['mes_mes_referencia']?.toString() ?? "",
//         mes_ano_referencia: json['mes_ano_referencia']?.toString() ?? "",
//         mes_pfl_id: json['mes_pfl_id']?.toString() ?? "",
//         mes_hld_id: json['mes_hld_id']?.toString() ?? "",

//         pfl_full_name: json['pfl_full_name']?.toString() ?? "",


//         mes_vpg_id: json['mes_vpg_id']?.toString() ?? "",
//         mes_vpg_hld_id: json['mes_vpg_hld_id']?.toString() ?? "",

//         vpg_valor_normal: json['vpg_valor_normal']?.toString() ?? "",
//         vpg_dia_valor_normal: json['vpg_dia_valor_normal']?.toString() ?? "",
//         vpg_valor_desconto: json['vpg_valor_desconto']?.toString() ?? "",
//         vpg_dia_valor_desconto: json['vpg_dia_valor_desconto']?.toString() ?? "",
//         vpg_desc: json['vpg_desc']?.toString() ?? "",

//         mes_valor: json['mes_valor']?.toString() ?? "",
//         mes_data_pagamento: json['mes_data_pagamento']?.toString() ?? "",
//         mes_comprovante_pag: json['mes_comprovante_pag']?.toString() ?? "",

//         mes_fpg_id: json['mes_fpg_id']?.toString() ?? "",
//         mes_fpg_hld_id: json['mes_fpg_hld_id']?.toString() ?? "",
//         fpg_descricao: json['fpg_descricao']?.toString() ?? "",

//         mes_data_confirmacao: json['mes_data_confirmacao']?.toString() ?? "",
        
//         mes_pfl_id_confirmacao: json['mes_pfl_id_confirmacao']?.toString() ?? "",
//         mes_hld_id_confirmacao: json['mes_hld_id_confirmacao']?.toString() ?? "",
//         mes_full_name_confirmacao: json['mes_full_name_confirmacao']?.toString() ?? "",

//         mes_monthly_percent: json['mes_monthly_percent']?.toString() ?? "",
//     );
//   }

// }
class MensalidadesModel {
  String year;
  String month;

  String tkt_id;
  String tkt_hld_id;
  String hld_name;

  String tkt_bar_id;
  String tkt_bar_open_date;

  String tkt_table_number;
  String tkt_client_name;
  String tkt_has_discount;
  String tkt_paiment_path;

  String tkt_pfl_id;
  String pfl_full_name;


  String tkt_tst_id;
  String tst_name;

  String bar_tss_id;
  String tss_desc;

  String tkt_vpg_id;
  String vpg_valor_normal;
  String vpg_dia_valor_normal;
  String vpg_valor_desconto;
  String vpg_dia_valor_desconto;
  String vpg_desc;

  String tkt_pas_id;
  String pas_monthly_percent;
  
  String tit_id;
  String tit_tkt_id;
  String tit_pdt_id;
  String pdt_name;
  String tit_quantities;
  String tit_unit_value;
  String tit_value;


  // ==========================================
  MensalidadesModel ( {
    required this.year,
    required this.month,
    required this.tkt_id,
    required this.tkt_hld_id,
    required this.hld_name,

    required this.tkt_bar_id,
    required this.tkt_bar_open_date,

    required this.tkt_table_number,
    required this.tkt_client_name,
    required this.tkt_has_discount,
    required this.tkt_paiment_path,

    required this.tkt_pfl_id,
    required this.pfl_full_name,

    required this.tkt_tst_id,
    required this.tst_name,

    required this.bar_tss_id,
    required this.tss_desc,

    required this.tkt_vpg_id,
    required this.vpg_valor_normal,
    required this.vpg_dia_valor_normal,
    required this.vpg_valor_desconto,
    required this.vpg_dia_valor_desconto,
    required this.vpg_desc,

    required this.tkt_pas_id,
    required this.pas_monthly_percent,

    required this.tit_id,
    required this.tit_tkt_id,
    required this.tit_pdt_id,
    required this.pdt_name,
    required this.tit_quantities,
    required this.tit_unit_value,
    required this.tit_value,
  } );

   // ==========================================
  factory MensalidadesModel
  .fromJson(Map<String, dynamic> json)
  {
      return MensalidadesModel(
        year: json['year']?.toString() ?? "",
        month: json['month']?.toString() ?? "",
        tkt_id: json['tkt_id']?.toString() ?? "",
        tkt_hld_id: json['tkt_hld_id']?.toString() ?? "",
        hld_name: json['hld_name']?.toString() ?? "",

        tkt_bar_id: json['tkt_bar_id']?.toString() ?? "",
        tkt_bar_open_date: json['tkt_bar_open_date']?.toString() ?? "",

        tkt_table_number: json['tkt_table_number']?.toString() ?? "",
        tkt_client_name: json['tkt_client_name']?.toString() ?? "",
        tkt_has_discount: json['tkt_has_discount']?.toString() ?? "",
        tkt_paiment_path: json['tkt_paiment_path']?.toString() ?? "",

        tkt_pfl_id: json['tkt_pfl_id']?.toString() ?? "",
        pfl_full_name: json['pfl_full_name']?.toString() ?? "",

        tkt_tst_id: json['tkt_tst_id']?.toString() ?? "",
        tst_name: json['tst_name']?.toString() ?? "",

        bar_tss_id: json['bar_tss_id']?.toString() ?? "",
        tss_desc: json['tss_desc']?.toString() ?? "",

        tkt_vpg_id: json['tkt_vpg_id']?.toString() ?? "",
        vpg_valor_normal: json['vpg_valor_normal']?.toString() ?? "",
        vpg_dia_valor_normal: json['vpg_dia_valor_normal']?.toString() ?? "",
        vpg_valor_desconto: json['vpg_valor_desconto']?.toString() ?? "",
        vpg_dia_valor_desconto: json['vpg_dia_valor_desconto']?.toString() ?? "",
        vpg_desc: json['vpg_desc']?.toString() ?? "",

        tkt_pas_id: json['tkt_pas_id']?.toString() ?? "",
        pas_monthly_percent: json['pas_monthly_percent']?.toString() ?? "",

        tit_id: json['tit_id']?.toString() ?? "",
        tit_tkt_id: json['tit_tkt_id']?.toString() ?? "",
        tit_pdt_id: json['tit_pdt_id']?.toString() ?? "",
        pdt_name: json['pdt_name']?.toString() ?? "",
        tit_quantities: json['tit_quantities']?.toString() ?? "",
        tit_unit_value: json['tit_unit_value']?.toString() ?? "",
        tit_value: json['tit_value']?.toString() ?? "",
        
    );
  }

}
