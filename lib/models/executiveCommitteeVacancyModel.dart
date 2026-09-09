class ExecutiveCommitteeVacancyModel {
  final String ecmId;
  final String? ecmHldId;
  final String ecmName;
  final String ect_id;
  final String? ectmDateEnd;

  ExecutiveCommitteeVacancyModel({
    required this.ecmId,
    this.ecmHldId,
    required this.ecmName,
    required this.ect_id,
    this.ectmDateEnd,
  });

  factory ExecutiveCommitteeVacancyModel.fromMap(Map<String, dynamic> map) {
    return ExecutiveCommitteeVacancyModel(
      // .toString() previne erro se o banco retornar int/bigint
      ecmId: map['ecm_id']?.toString() ?? '',
      ecmHldId: map['ecm_hld_id']?.toString(),
      ecmName: map['ecm_name']?.toString() ?? '',
      ect_id: map['ect_id']?.toString() ?? '',
      ectmDateEnd:
          map['ectm_date_end']?.toString() ?? map['ect_date_end']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ecm_id': ecmId,
      'ecm_hld_id': ecmHldId,
      'ecm_name': ecmName,
      'ect_id': ect_id,
      'ectm_date_end': ectmDateEnd,
    };
  }
}