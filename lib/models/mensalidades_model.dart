class MensalidadesModel {
  String mesreferencia;
  String anoreferencia;
  String id;
  String fullname;
  String valorreferencia;
  String valor_normal;
  String dia_valor_normal;
  String valor_desconto;
  String dia_valor_desconto;
  String valor;
  String datapagamento;
  String comprovantepag;
  String formapagamento;
  String descricao;
  String dataconfirmacao;
  String idconfirmacao;

  MensalidadesModel ( {
    required this.mesreferencia,
    required this.anoreferencia,
    required this.id,
    required this.fullname,
    required this.valorreferencia,
    required this.valor_normal,
    required this.dia_valor_normal,
    required this.valor_desconto,
    required this.dia_valor_desconto,
    required this.valor,
    required this.datapagamento,
    required this.comprovantepag,
    required this.formapagamento,
    required this.descricao,
    required this.dataconfirmacao,
    required this.idconfirmacao
  } );

  factory MensalidadesModel.fromJson(Map<String, dynamic> json) {
      return MensalidadesModel(
        mesreferencia: json['mes_referencia']?.toString() ?? "",
        anoreferencia: json['ano_referencia']?.toString() ?? "",
        id: json['id']?.toString() ?? "",
        fullname: json['full_name']?.toString() ?? "",
        valorreferencia: json['valor_referencia']?.toString() ?? "",
        valor_normal: json['valor_normal']?.toString() ?? "",
        dia_valor_normal: json['dia_valor_normal']?.toString() ?? "",
        valor_desconto: json['valor_desconto']?.toString() ?? "",
        dia_valor_desconto: json['dia_valor_desconto']?.toString() ?? "",
        valor: json['valor']?.toString() ?? "",
        datapagamento: json['data_pagamento']?.toString() ?? "",
        comprovantepag: json['comprovante_pag']?.toString() ?? "",
        formapagamento: json['forma_pagamento']?.toString() ?? "",
        descricao: json['descricao']?.toString() ?? "",
        dataconfirmacao: json['data_confirmacao']?.toString() ?? "",
        idconfirmacao: json['id_confirmacao']?.toString() ?? "",
    );
  }
}
