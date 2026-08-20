
class JourneyRidingModel {
  String jr_id;
  String jr_hld_id;
  String hld_name;

  String jr_level;
  String jr_nome;
  String jr_desc;
  String jr_minimum_time_indays;


  String jr_id_precursory;
  String jr_nome_precursory;
  

  // ==========================================
  JourneyRidingModel({
    required this.jr_id,
    required this.jr_hld_id,
    required this.hld_name,

    required this.jr_level,
    required this.jr_nome,
    required this.jr_desc,
    required this.jr_minimum_time_indays,

    required this.jr_id_precursory,
    required this.jr_nome_precursory
  });

  // ==========================================
  factory JourneyRidingModel
    .fromJson(
      Map<String,dynamic> json
  ) {
    return JourneyRidingModel(
      jr_id: json['jr_id']?.toString() ?? "",
      jr_hld_id: json['jr_hld_id']?.toString() ?? "",
      hld_name: json['hld_name']?.toString() ?? "",

      jr_level: json['jr_level']?.toString() ?? "",
      jr_nome: json['jr_nome']?.toString() ?? "",
      jr_desc: json['jr_desc']?.toString() ?? "",
      jr_minimum_time_indays: json['jr_minimum_time_indays']?.toString() ?? "",

      jr_id_precursory: json['jr_id_precursory']?.toString() ?? "",
      jr_nome_precursory: json['jr_nome_precursory']?.toString() ?? "",
    );
  }

}
