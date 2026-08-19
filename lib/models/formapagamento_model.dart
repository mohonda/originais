class FormaPagamentoModel {
  String fpg_id;
  String hld_id;
  String fpg_descricao;
 
  // ==========================================
  FormaPagamentoModel ( {
    required this.fpg_id,
    required this.hld_id,
    required this.fpg_descricao,
  } );

  // ==========================================
  factory FormaPagamentoModel
    .fromJson(
      Map<String,dynamic> json
  ) {
      return FormaPagamentoModel(
        fpg_id: json['fpg_id']?.toString() ?? "",
        hld_id: json['hld_id']?.toString() ?? "",
        fpg_descricao: json['fpg_descricao']?.toString() ?? "",
    );
  }
}
