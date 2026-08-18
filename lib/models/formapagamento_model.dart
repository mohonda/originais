class FormaPagamentoModel {
  String id;
  String descricao;
 
  // ==========================================
  FormaPagamentoModel ( {
    required this.id,
    required this.descricao,
  } );

  // ==========================================
  factory FormaPagamentoModel
    .fromJson(
      Map<String,dynamic> json
  ) {
      return FormaPagamentoModel(
        id: json['id']?.toString() ?? "",
        descricao: json['descricao']?.toString() ?? "",
    );
  }
}
