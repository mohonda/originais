class VProfileAssociateStatusModel {
  String pas_pfl_id;
  String pas_hld_id;
  String pas_date;
  String pas_monthly_percent;

  String as_id;
  String as_desc;
  bool as_ismonthlypayment;
  String as_max_indays;
  String as_renovacao;

  // ==========================================
  VProfileAssociateStatusModel({
    required this.pas_pfl_id,
    required this.pas_hld_id,
    required this.pas_date,
    required this.pas_monthly_percent,

    required this.as_id,
    required this.as_desc,
    required this.as_ismonthlypayment,
    required this.as_max_indays,
    required this.as_renovacao,
  });

  // ==========================================
  factory VProfileAssociateStatusModel.fromJson(Map<String, dynamic> json) {
    return VProfileAssociateStatusModel(
      pas_pfl_id: json['pas_pfl_id']?.toString() ?? '',
      pas_hld_id: json['pas_hld_id']?.toString() ?? '',
      pas_date: json['pas_date']?.toString() ?? '',
      pas_monthly_percent: json['pas_monthly_percent']?.toString() ?? '',

      as_id: json['as_id']?.toString() ?? '',
      as_desc: json['as_desc']?.toString() ?? '',
      as_ismonthlypayment: json['as_ismonthlypayment'] as bool,
      as_max_indays: json['as_max_indays']?.toString() ?? '',
      as_renovacao: json['as_renovacao']?.toString() ?? '',
    );
  }

  // ==========================================
  Map<String, dynamic> toJson() {
    return {
      'pas_pfl_id': pas_pfl_id,
      'pas_hld_id': pas_hld_id,
      'pas_date': pas_date,
      'pas_monthly_percent': pas_monthly_percent,

      'as_id': as_id,
      'as_desc': as_desc,
      'as_isMonthlyPayment': as_ismonthlypayment,
      'AS_MAX_indays': as_max_indays,
      'AS_Renovacao': as_renovacao,
    };
  }

}
