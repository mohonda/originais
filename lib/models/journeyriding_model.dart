
class JourneyRidingModel {
  String pfl_id;
  String pfl_full_name;
  
  String hld_id;
  String hld_name;

  String jr_id;
  String jr_nome;
  String jr_desc;
  String jr_level;
  String jr_id_precursory;
  String jr_minimum_time_indays;

  String uj_id;
  String uj_promotion_date;
  

  // ==========================================
  JourneyRidingModel({
    required this.pfl_id,
    required this.pfl_full_name,

    required this.hld_id,
    required this.hld_name,

    required this.jr_id,
    required this.jr_nome,
    required this.jr_desc,
    required this.jr_level,
    required this.jr_id_precursory,
    required this.jr_minimum_time_indays,

    required this.uj_id,
    required this.uj_promotion_date,
  });

  // ==========================================
  factory JourneyRidingModel
    .fromJson(
      Map<String,dynamic> json
  ) {
    return JourneyRidingModel(
      pfl_id: json['pfl_id']?.toString() ?? "",
      pfl_full_name: json['pfl_full_name']?.toString() ?? "",

      hld_id: json['hld_id']?.toString() ?? "",
      hld_name: json['hld_name']?.toString() ?? "",

      jr_id: json['jr_id']?.toString() ?? "",
      jr_nome: json['jr_nome']?.toString() ?? "",
      jr_desc: json['jr_desc']?.toString() ?? "",
      jr_level: json['jr_level']?.toString() ?? "",
      jr_id_precursory: json['jr_id_precursory']?.toString() ?? "",
      jr_minimum_time_indays: json['jr_minimum_time_indays']?.toString() ?? "",

      uj_id: json['uj_id']?.toString() ?? "",
      uj_promotion_date: json['uj_promotion_date']?.toString() ?? "",
    );
  }

}
