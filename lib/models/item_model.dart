class ItemModel {
  String id;
  String nome;

  ItemModel({
    required this.id,
    required this.nome
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id']?.toString() ?? "",
      nome: json['nome']?.toString() ?? "",
    );
  }

}
