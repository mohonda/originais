
// ==========================================
class TicketStatusModel {
  final String tst_id;
  final String tst_hld_id;
  final String tst_name;

  TicketStatusModel({
    required this.tst_id,
    required this.tst_hld_id,
    required this.tst_name,
  });
  
  factory TicketStatusModel
    .fromJson(Map<String, dynamic> json)
  {
    return TicketStatusModel(
      tst_id: json['tst_id']?.toString() ?? '',
      tst_hld_id: json['tst_hld_id']?.toString() ?? '',
      tst_name: json['tst_name']?.toString() ?? '',
    );
  }
}

// ==========================================
// MODELO DE ITENS DO TICKET
// ==========================================
class TicketsItemsModel {
  String? tit_id;
  String tit_hld_id;
  String? hld_name;

  String tit_tkt_id;
  String tit_pdt_id;
  String? pdt_name;

  int tit_quantities;
  double tit_unit_value;
  double? tit_value;

  TicketsItemsModel({
    this.tit_id,
    required this.tit_hld_id,
    this.hld_name,
    required this.tit_tkt_id,
    required this.tit_pdt_id,
    this.pdt_name,
    required this.tit_quantities,
    required this.tit_unit_value,
    this.tit_value,
  });

  factory TicketsItemsModel.fromJson(Map<String, dynamic> json) {
    return TicketsItemsModel(
      tit_id: json['tit_id']?.toString() ?? '',
      tit_hld_id: json['tit_hld_id']?.toString() ?? '',
      hld_name: json['hld_name']?.toString() ?? '',
      tit_tkt_id: json['tit_tkt_id']?.toString() ?? '',
      tit_pdt_id: json['tit_pdt_id']?.toString() ?? '',
      pdt_name: json['pdt_name']?.toString() ?? '',
      // 🟢 Proteção contra null e conversão segura para int/double
      tit_quantities: (json['tit_quantities'] as num?)?.toInt() ?? 1,
      tit_unit_value: (json['tit_unit_value'] as num?)?.toDouble() ?? 0.0,
      tit_value: (json['tit_value'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // 🟢 Método necessário para enviar dados ao Supabase (INSERT / UPDATE)
  Map<String, dynamic> toJson() {
    return {
      // if (tit_id.isNotEmpty) 'tit_id': tit_id,
      'tit_hld_id': tit_hld_id,
      'tit_tkt_id': tit_tkt_id,
      'tit_pdt_id': tit_pdt_id,
      'tit_quantities': tit_quantities,
      'tit_unit_value': tit_unit_value,
    };
  }
}

// ==========================================
// MODELO PRINCIPAL DE TICKETS
// ==========================================
class TicketsModel {
  String? tkt_id;
  String tkt_hld_id;
  String? hld_name;
  String tkt_bar_open_date;
  String tkt_table_number;
  String? tkt_client_name;
  String? tkt_pfl_id;
  String? pfl_full_name;

  bool tkt_has_discount;
  String tkt_tst_id;
  String? tst_name;
  String? tkt_paiment_path;
  String? created_at;

  List<TicketsItemsModel> ticketsItems;

  TicketsModel({
    this.tkt_id,
    required this.tkt_hld_id,
    this.hld_name,
    required this.tkt_bar_open_date,
    required this.tkt_table_number,
    this.tkt_client_name,
    this.tkt_pfl_id,
    this.pfl_full_name,
    required this.tkt_has_discount,
    required this.tkt_tst_id,
    this.tst_name,
    this.tkt_paiment_path,
    this.created_at,
    List<TicketsItemsModel>? ticketsItems,
  }) : ticketsItems = ticketsItems ?? [];

  double get totalConsumo =>
      ticketsItems.fold(0.0, (sum, item) => sum + item.tit_value! );

  factory TicketsModel.fromJson(Map<String, dynamic> json) {
    // 🟢 Fallback duplo para a chave de relacionamento de itens
    final rawItens = (json['vtickets_items'] ?? json['tit_tkt_id'])
            as List<dynamic>? ??
        [];

    final itens = rawItens
        .map((i) => TicketsItemsModel.fromJson(i as Map<String, dynamic>))
        .toList();

    return TicketsModel(
      tkt_id: json['tkt_id']?.toString() ?? '',
      tkt_hld_id: json['tkt_hld_id']?.toString() ?? '',
      hld_name: json['hld_name']?.toString() ?? '',
      tkt_bar_open_date: json['tkt_bar_open_date']?.toString() ?? '',
      tkt_table_number: json['tkt_table_number']?.toString() ?? '',
      tkt_client_name: json['tkt_client_name']?.toString() ?? '',
      tkt_pfl_id: json['tkt_pfl_id']?.toString() ?? '',
      pfl_full_name: json['pfl_full_name']?.toString() ?? '',
      // 🟢 Cast seguro para booleano
      tkt_has_discount: (json['tkt_has_discount'] as bool?) ?? false,
      tkt_tst_id: json['tkt_tst_id']?.toString() ?? '',
      tst_name: json['tst_name']?.toString() ?? '',
      tkt_paiment_path: json['tkt_paiment_path']?.toString() ?? '',
      created_at: json['created_at']?.toString() ?? '',
      ticketsItems: itens,
    );
  }

  // 🟢 Método para persistência/atualização no Supabase
  Map<String, dynamic> toJson() {
    return {
      'tkt_hld_id': tkt_hld_id,
      'tkt_bar_open_date': tkt_bar_open_date,
      'tkt_table_number': tkt_table_number,
      'tkt_client_name': tkt_client_name,
      'tkt_pfl_id': tkt_pfl_id,
      'tkt_has_discount': tkt_has_discount,
      'tkt_tst_id': tkt_tst_id,
    };
  }
}