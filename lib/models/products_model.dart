// 🟢 MODELO DE PRODUTO DO CATÁLOGO
class ProductsModel {
  final String pdt_id;
  final String pdt_hld_id;

  final String pdt_cpdt_id;
  final String cpdt_desc;

  final String pdt_tpdt_id;
  final String tpdt_desc;
  
  final String pdt_name;
  final String pdt_value_member;
  final String pdt_value_visitant;

  ProductsModel({
    required this.pdt_id,
    required this.pdt_hld_id,

    required this.pdt_cpdt_id,
    required this.cpdt_desc,

    required this.pdt_tpdt_id,
    required this.tpdt_desc,

    required this.pdt_name,
    required this.pdt_value_member,
    required this.pdt_value_visitant,
  });
  
  // ==========================================
  factory ProductsModel
    .fromJson(Map<String, dynamic> json)
  {
    return ProductsModel(
      pdt_id: json['pdt_id']?.toString() ?? '',
      pdt_hld_id: json['pdt_hld_id']?.toString() ?? '',

      pdt_cpdt_id: json['pdt_cpdt_id']?.toString() ?? '',
      cpdt_desc: json['cpdt_desc']?.toString() ?? '',
      
      pdt_tpdt_id: json['pdt_tpdt_id']?.toString() ?? '',
      tpdt_desc: json['tpdt_desc']?.toString() ?? '',
      
      pdt_name: json['pdt_name']?.toString() ?? '',
      pdt_value_member: json['pdt_value_member']?.toString() ?? '',
      pdt_value_visitant: json['pdt_value_visitant']?.toString() ?? '',
    );
  }

}
