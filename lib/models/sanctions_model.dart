class SanctionsModel {
  final int? sanId;
  final int? sanHldId;
  final String sanName;

  SanctionsModel({
    this.sanId,
    this.sanHldId,
    required this.sanName,
  });

  /// Converte um JSON / Map do Banco de Dados para a Model
  factory SanctionsModel.fromJson(Map<String, dynamic> json) {
    return SanctionsModel(
      sanId: json['san_id'] != null 
          ? int.tryParse(json['san_id'].toString()) 
          : (json['san_ID'] != null ? int.tryParse(json['san_ID'].toString()) : null),
      sanHldId: json['san_hld_id'] != null 
          ? int.tryParse(json['san_hld_id'].toString()) 
          : null,
      sanName: json['san_name']?.toString() ?? '',
    );
  }

  /// Converte a Model para JSON / Map (para enviar em INSERT/UPDATE)
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'san_hld_id': sanHldId,
      'san_name': sanName,
    };

    // Apenas envia o ID se ele já existir (para evitar conflito com IDENTITY no INSERT)
    if (sanId != null) {
      data['san_id'] = sanId;
    }

    return data;
  }

  /// Permite clonar o objeto alterando apenas alguns campos
  SanctionsModel copyWith({
    int? sanId,
    int? sanHldId,
    String? sanName,
  }) {
    return SanctionsModel(
      sanId: sanId ?? this.sanId,
      sanHldId: sanHldId ?? this.sanHldId,
      sanName: sanName ?? this.sanName,
    );
  }

  @override
  String toString() {
    return 'SanctionsModel(sanId: $sanId, sanHldId: $sanHldId, sanName: $sanName)';
  }
}