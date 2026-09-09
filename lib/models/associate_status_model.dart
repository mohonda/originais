import 'dart:convert';

class AssociateStatusModel {
  final int? asId;
  final int? asHldId;
  final String asDesc;
  final bool asIsMonthlyPayment;
  final int? asMaxIndays;
  final int asRenovacao;

  AssociateStatusModel({
    this.asId,
    this.asHldId,
    required this.asDesc,
    required this.asIsMonthlyPayment,
    this.asMaxIndays,
    required this.asRenovacao,
  });

  // ---------------------------------------------------------------------------
  // 💡 GETTERS DE COMPATIBILIDADE (snake_case)
  // Garante funcionamento se telas anteriores chamarem st.as_desc ou st.as_id
  // ---------------------------------------------------------------------------
  int? get as_id => asId;
  int? get as_hld_id => asHldId;
  String get as_desc => asDesc;
  bool get as_is_monthly_payment => asIsMonthlyPayment;
  int? get as_max_indays => asMaxIndays;
  int get as_renovacao => asRenovacao;

  // ---------------------------------------------------------------------------
  // FACTORY FROM MAP (Supabase -> Dart)
  // ---------------------------------------------------------------------------
  factory AssociateStatusModel.fromMap(Map<String, dynamic> map) {
    return AssociateStatusModel(
      // AS_ID
      asId: map['AS_ID'] != null
          ? int.tryParse(map['AS_ID'].toString())
          : (map['as_id'] != null ? int.tryParse(map['as_id'].toString()) : null),

      // AS_hld_id
      asHldId: map['AS_hld_id'] != null
          ? int.tryParse(map['AS_hld_id'].toString())
          : (map['as_hld_id'] != null ? int.tryParse(map['as_hld_id'].toString()) : null),

      // AS_DESC
      asDesc: map['AS_DESC']?.toString() ?? map['as_desc']?.toString() ?? '',

      // AS_isMonthlyPayment
      asIsMonthlyPayment: map['AS_isMonthlyPayment'] as bool? ??
          map['as_ismonthlypayment'] as bool? ??
          map['as_is_monthly_payment'] as bool? ??
          false,

      // AS_MAX_indays
      asMaxIndays: map['AS_MAX_indays'] != null
          ? int.tryParse(map['AS_MAX_indays'].toString())
          : (map['as_max_indays'] != null
              ? int.tryParse(map['as_max_indays'].toString())
              : null),

      // AS_Renovacao
      asRenovacao: map['AS_Renovacao'] != null
          ? int.tryParse(map['AS_Renovacao'].toString()) ?? 0
          : (map['as_renovacao'] != null
              ? int.tryParse(map['as_renovacao'].toString()) ?? 0
              : 0),
    );
  }

  // ---------------------------------------------------------------------------
  // TO MAP (Dart -> Supabase Insert/Update)
  // ---------------------------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      if (asId != null) 'AS_ID': asId,
      'AS_hld_id': asHldId,
      'AS_DESC': asDesc,
      'AS_isMonthlyPayment': asIsMonthlyPayment,
      'AS_MAX_indays': asMaxIndays,
      'AS_Renovacao': asRenovacao,
    };
  }

  // Conversores para JSON String (opcional)
  String toJson() => json.encode(toMap());

  factory AssociateStatusModel.fromJson(String source) =>
      AssociateStatusModel.fromMap(json.decode(source) as Map<String, dynamic>);

  // Method copyWith para imutabilidade e updates pontuais
  AssociateStatusModel copyWith({
    int? asId,
    int? asHldId,
    String? asDesc,
    bool? asIsMonthlyPayment,
    int? asMaxIndays,
    int? asRenovacao,
  }) {
    return AssociateStatusModel(
      asId: asId ?? this.asId,
      asHldId: asHldId ?? this.asHldId,
      asDesc: asDesc ?? this.asDesc,
      asIsMonthlyPayment: asIsMonthlyPayment ?? this.asIsMonthlyPayment,
      asMaxIndays: asMaxIndays ?? this.asMaxIndays,
      asRenovacao: asRenovacao ?? this.asRenovacao,
    );
  }
}