class HeadquartersBarModel {
  String bar_id;
  String bar_hld_id;
  String bar_open_date;

  String bar_open_pfl_id;
  String open_profile_name;

  String bar_close_date;
  String bar_close_pfl_id;
  String close_profile_name;
  
  String bar_desc;
 
  // ==========================================
  HeadquartersBarModel ( {
    required this.bar_id,
    required this.bar_hld_id,
    required this.bar_open_date,

    required this.bar_open_pfl_id,
    required this.open_profile_name,
    
    required this.bar_close_date,
    required this.bar_close_pfl_id,
    required this.close_profile_name,
    
    required this.bar_desc,
  } );

  // ==========================================
  factory HeadquartersBarModel
    .fromJson(Map<String,dynamic> json) {
      return HeadquartersBarModel(
        bar_id: json['bar_id']?.toString() ?? '',
        bar_hld_id: json['bar_hld_id']?.toString() ?? '',
        bar_open_date: json['bar_open_date']?.toString() ?? '',

        bar_open_pfl_id: json['bar_open_pfl_id']?.toString() ?? '',
        open_profile_name: json['open_profile_name']?.toString() ?? '',

        bar_close_date: json['bar_close_date']?.toString() ?? '',
        bar_close_pfl_id: json['bar_close_pfl_id']?.toString() ?? '',
        close_profile_name: json['close_profile_name']?.toString() ?? '',

        bar_desc: json['bar_desc']?.toString() ?? '',
    );
  }
}

