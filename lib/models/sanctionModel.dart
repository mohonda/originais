import 'dart:convert';

class SanctionModel {
  final int? sanId;
  final int? sanHldId;
  final String sanName;

  SanctionModel({
    this.sanId,
    this.sanHldId,
    required this.sanName,
  });

  // ---------------------------------------------------------------------------
  // 💡 GETTERS DE COMPATIBILIDADE (snake_case)
  // Permite acesso via st.san_id, st.san_hld_id ou st.san_name
  // ---------------------------------------------------------------------------
  int? get san_id => sanId;
  int? get san_hld_id => sanHldId;
  String get san_name => sanName;

  // ---------------------------------------------------------------------------
  // FACTORY FROM MAP (Supabase -> Dart)
  // ---------------------------------------------------------------------------
  factory SanctionModel.fromMap(Map<String, dynamic> map) {
    return SanctionModel(
      // san_ID / san_id / SAN_ID
      sanId: map['san_ID'] != null
          ? int.tryParse(map['san_ID'].toString())
          : (map['san_id'] != null
              ? int.tryParse(map['san_id'].toString())
              : (map['SAN_ID'] != null
                  ? int.tryParse(map['SAN_ID'].toString())
                  : null)),

      // san_hld_id / SAN_HLD_ID
      sanHldId: map['san_hld_id'] != null
          ? int.tryParse(map['san_hld_id'].toString())
          : (map['san_hld_ID'] != null
              ? int.tryParse(map['san_hld_ID'].toString())
              : (map['SAN_HLD_ID'] != null
                  ? int.tryParse(map['SAN_HLD_ID'].toString())
                  : null)),

      // san_name / SAN_NAME
      sanName: map['san_name']?.toString() ??
          map['SAN_NAME']?.toString() ??
          map['san_Name']?.toString() ??
          '',
    );
  }

  // ---------------------------------------------------------------------------
  // TO MAP (Dart -> Supabase Insert/Update)
  // ---------------------------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      if (sanId != null) 'san_ID': sanId,
      'san_hld_id': sanHldId,
      'san_name': sanName,
    };
  }

  // Conversores para JSON String (opcional)
  String toJson() => json.encode(toMap());

  factory SanctionModel.fromJson(String source) =>
      SanctionModel.fromMap(json.decode(source) as Map<String, dynamic>);

  // Method copyWith para imutabilidade e updates pontuais
  SanctionModel copyWith({
    int? sanId,
    int? sanHldId,
    String? sanName,
  }) {
    return SanctionModel(
      sanId: sanId ?? this.sanId,
      sanHldId: sanHldId ?? this.sanHldId,
      sanName: sanName ?? this.sanName,
    );
  }
}