import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gorouter_exemplo/models/vprofile_model.dart';
import 'package:gorouter_exemplo/models/journeyriding_model.dart';
import 'package:gorouter_exemplo/services/general_service.dart';
import 'package:gorouter_exemplo/controllers/bd_journeyriding_controller.dart';
import 'package:gorouter_exemplo/models/custom_app_bar.dart';
import 'package:gorouter_exemplo/controllers/bd_vprofile_associatestatus_controller.dart';
import 'package:gorouter_exemplo/controllers/bd_vprofiles_sanctions_controller.dart';
import 'package:gorouter_exemplo/models/vprofile_associatestatus_model.dart';
import 'package:gorouter_exemplo/models/vprofiles_sanctions_model.dart';
import 'package:gorouter_exemplo/models/vexecutive_committee_termofoffice_members_model.dart';
import 'package:gorouter_exemplo/controllers/bd_vexecutive_committee_termofoffice_members_controller.dart';
import 'package:gorouter_exemplo/view/associates_profile_journeyriding.dart';

class AssociatesDetails extends StatefulWidget {
  final VProfileModel itemAtual;

  const AssociatesDetails({super.key, required this.itemAtual});

  // ==========================================
  @override
  State<AssociatesDetails> createState() => AssociatesDetailsState();
}

class AssociatesDetailsState extends State<AssociatesDetails> {
  final bdJourneyRidingController =
      getItBdJourneyRidingController<BdJourneyRidingController>();

  final bdVProfileAssociateStatusController =
      getItBdVProfileAssociateStatusController<
        BdVProfileAssociateStatusController
      >();

  final bdVProfilesSanctionsController =
      getItBdVProfilesSanctionsController<BdVProfilesSanctionsController>();

  final bdVExecutiveCommitteeTermOfOfficeMembersController =
      getItBdVExecutiveCommitteeTermOfOfficeMembersController<
        BdVExecutiveCommitteeTermOfOfficeMembersController
      >();

  final generalService = getItGeneralService<GeneralService>();

  final idController = TextEditingController();
  final hldController = TextEditingController();
  final fullNameController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  final ValueNotifier<bool> isObscurePassword1 = ValueNotifier<bool>(true);
  final ValueNotifier<bool> isObscurePassword2 = ValueNotifier<bool>(true);

  final ScrollController _journeyScrollController = ScrollController();
  final ScrollController _associateStatusScrollController = ScrollController();
  final ScrollController _sanctionScrollController = ScrollController();
  final ScrollController _executiveCommiteeScrollController =
      ScrollController();

  // ==========================================
  @override
  void initState() {
    idController.text = widget.itemAtual.pfl_id.toString();
    fullNameController.text = widget.itemAtual.pfl_full_name.toString();
    hldController.text = widget.itemAtual.hld_name.toString();

    super.initState();
  }

  // ==========================================
  @override
  void dispose() {
    _journeyScrollController.dispose(); // Lembre-se de liberar o controller
    _associateStatusScrollController
        .dispose(); // Lembre-se de liberar o controller
    _sanctionScrollController.dispose(); // Lembre-se de liberar o controller
    _executiveCommiteeScrollController
        .dispose(); // Lembre-se de liberar o controller

    super.dispose();
  }

  // ==========================================
  @override
  Widget build(BuildContext context) {
    const double distance = 16.0;

    return Scaffold(
      appBar: CustomFloatingAppBar(
        title: 'Associates - ${fullNameController.text}',
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. TOP FIXO (ID e Holding)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: idController,
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: 'ID:',
                            prefixIcon: Icon(Icons.key),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: distance),
                      Expanded(
                        child: TextFormField(
                          controller: hldController,
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: 'Holding:',
                            prefixIcon: Icon(Icons.verified_user),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: distance),

                  // 2. MEIO ROLÁVEL (Apenas as tabelas rolam)
                  Expanded(
                    child: SingleChildScrollView(
                      primary: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: distance),
                          journeyRidingTable(),
                          const SizedBox(height: distance),
                          associateStatusTable(),
                          const SizedBox(height: distance),
                          sanctionTable(),
                          const SizedBox(height: distance),
                          executiveCommitteeTable(),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: distance),

                  // 3. RODAPÉ FIXO (Botão Cancelar)
                  OutlinedButton.icon(
                    onPressed: context.pop,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Cancelar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  Widget journeyRidingTable() {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Journey of the Riding',
        // prefixIcon: Icon(Icons.stars),
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.all(12),
      ),
      child: ValueListenableBuilder<List<JourneyRidingModel>?>(
        valueListenable:
            bdJourneyRidingController.vProfileJourneyridingDetaisNotifier,
        builder: (context, historyList, child) {
          final bool temItens = historyList != null && historyList.isNotEmpty;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. ÁREA DOS CARDS / LISTA
              if (!temItens)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    'Nenhum registro encontrado.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: Scrollbar(
                    controller:
                        _journeyScrollController, // <--- PASSE O CONTROLLER AQUI
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller:
                          _journeyScrollController, // <--- PASSE O CONTROLLER AQUI
                      scrollDirection: Axis.vertical,
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: historyList.map((item) {
                          final String nome = item.jr_nome?.toString() ?? '-';
                          final String nivel = item.jr_level?.toString() ?? '-';
                          final String data = generalService.formatarDataBr(
                            item.uj_promotion_date.toString(),
                          );

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 8.0),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 8.0,
                              ),
                              child: Row(
                                children: [
                                  // Informações do Nível
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          nome,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Nível: $nivel - Data: $data',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // 2. BOTÃO DE EDITAR NO LADO DIREITO
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.orange,
                                    ),
                                    tooltip: 'Editar',
                                    // onPressed: () {
                                    //   _associatesProfileJourneyRiding(
                                    //     item,
                                    //     bdJourneyRidingController
                                    //         .vProfileJourneyridingDetaisNotifier
                                    //         .value
                                    //         .last
                                    //         .jr_level
                                    //         .toString(),
                                    //     context,
                                    //     false,
                                    //   );
                                    // },
                                    onPressed: () {
                                      // 1. Obtém a lista atual
                                      final listDetails = bdJourneyRidingController
                                          .vProfileJourneyridingDetaisNotifier
                                          .value;

                                      // 2. Verifica se está vazia: se sim, usa '0'; se não, pega o jr_level do último item
                                      final String level = listDetails.isEmpty
                                          ? '0'
                                          : (listDetails.last.jr_level?.toString() ?? '0');

                                      // 3. Executa a função passando o nível calculado
                                      _associatesProfileJourneyRiding(
                                        item,
                                        level,
                                        context,
                                        false,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 4),

              // 3. BOTÃO DE ADICIONAR NO CANTO INFERIOR DIREITO
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    // 1. Obtém a lista atual
                    final listDetails = bdJourneyRidingController
                        .vProfileJourneyridingDetaisNotifier
                        .value;

                    // 2. Verifica se está vazia: se sim, usa '0'; se não, pega o jr_level do último item
                    final String level = listDetails.isEmpty
                        ? '0'
                        : (listDetails.last.jr_level?.toString() ?? '0');

                    // 3. Executa a função passando o nível calculado
                    _associatesProfileJourneyRiding(
                      newJourneyRidingModel(),
                      level,
                      context,
                      true,
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: const Text('Add Journey...'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  JourneyRidingModel newJourneyRidingModel() {
    final JourneyRidingModel localJourneyRidingModel = JourneyRidingModel(
      pfl_id: widget.itemAtual.pfl_id,
      pfl_full_name: widget.itemAtual.pfl_full_name,
      hld_id: widget.itemAtual.hld_id,
      hld_name: widget.itemAtual.hld_name,
      jr_id: '',
      jr_desc: '',
      jr_id_precursory: '',
      jr_level: '',
      jr_minimum_time_indays: '',
      jr_nome: '',
      uj_id: '',
      uj_promotion_date: '',
    );
    return localJourneyRidingModel;
  }

  // ==========================================
  Future<void> _associatesProfileJourneyRiding(
    JourneyRidingModel journeyRidingModel,
    String lastLevel,
    BuildContext context,
    bool isNew,
  ) async {
    try {
      await bdJourneyRidingController.loadJourneyRiding();
      
      if ( !isNew ){
        int tmp = int.parse(lastLevel.toString());
        if (tmp>0) tmp--;
        lastLevel = tmp.toString();
      }

      // Abre a tela somente após carregar os dados com sucesso
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AssociatesProfileJourneyRiding(
              itemAtual: journeyRidingModel,
              lastLevel: lastLevel,
              isNew: isNew,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('monthlyPaymentsIndividual error: $e');
    }
  }

  // ==========================================
  Widget associateStatusTable() {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Associate Status',
        // prefixIcon: Icon(Icons.stars),
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.all(12),
      ),
      child: ValueListenableBuilder<List<VProfileAssociateStatusModel>?>(
        valueListenable:
            bdVProfileAssociateStatusController.vProfileAssociateStatusNotifier,
        builder: (context, historyList, child) {
          final bool temItens = historyList != null && historyList.isNotEmpty;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. ÁREA DOS CARDS / LISTA
              if (!temItens)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    'Nenhum registro encontrado.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: Scrollbar(
                    controller:
                        _associateStatusScrollController, // <--- PASSE O CONTROLLER AQUI
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller:
                          _associateStatusScrollController, // <--- PASSE O CONTROLLER AQUI
                      scrollDirection: Axis.vertical,
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: historyList.map((item) {
                          final String status = item.as_desc?.toString() ?? '-';
                          final String percent =
                              item.pas_monthly_percent?.toString() ?? '-';
                          final String data = generalService.formatarDataBr(
                            item.pas_date.toString(),
                          );
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 8.0),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 8.0,
                              ),
                              child: Row(
                                children: [
                                  // Informações do Nível
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          status,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: item.as_ismonthlypayment
                                                ? Colors.white
                                                : Colors.red,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.as_ismonthlypayment
                                              ? 'Payment: $percent% - Data: $data'
                                              : 'Data: $data',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: item.as_ismonthlypayment
                                                ? Colors.white70
                                                : Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // 2. BOTÃO DE EDITAR NO LADO DIREITO
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.orange,
                                    ),
                                    tooltip: 'Editar',
                                    onPressed: () {
                                      // Adicione a ação de editar este 'item'
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 4),

              // 3. BOTÃO DE ADICIONAR NO CANTO INFERIOR DIREITO
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    // Adicione a ação de criar um novo nível
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: const Text('Adicionar Nível'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  Widget sanctionTable() {
    Color sanColor;
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Sanctions',
        // prefixIcon: Icon(Icons.stars),
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.all(12),
      ),
      child: ValueListenableBuilder<List<VProfilesSanctionsModel>?>(
        valueListenable:
            bdVProfilesSanctionsController.vProfilesSanctionsNotifier,
        builder: (context, historyList, child) {
          final bool temItens = historyList != null && historyList.isNotEmpty;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. ÁREA DOS CARDS / LISTA
              if (!temItens)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    'Nenhum registro encontrado.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: Scrollbar(
                    controller:
                        _sanctionScrollController, // <--- PASSE O CONTROLLER AQUI
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller:
                          _sanctionScrollController, // <--- PASSE O CONTROLLER AQUI
                      scrollDirection: Axis.vertical,
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: historyList.map((item) {
                          final String san_name =
                              item.san_name?.toString() ?? '-';
                          final String psan_desc =
                              item.psan_desc.toString() ?? '-';

                          final String psan_value = generalService
                              .currencyMoneyBr(item.psan_valor);

                          final String dateStart = generalService
                              .formatarDataBr(item.psan_date_start.toString());

                          final String dateEnd = generalService.formatarDataBr(
                            item.psan_date_end.toString(),
                          );
                          switch (item.psan_san_id) {
                            case '1':
                              sanColor = Colors.orange;
                            case '2':
                              sanColor = Colors.purpleAccent;
                            case '3':
                              sanColor = Colors.red;
                            default:
                              sanColor = Colors.white70;
                          }

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 8.0),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 8.0,
                              ),
                              child: Row(
                                children: [
                                  // Informações do Nível
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          san_name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: sanColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Início: $dateStart - Final: $dateEnd - Valor: $psan_value \nDescrição: $psan_desc',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: sanColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // 2. BOTÃO DE EDITAR NO LADO DIREITO
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.orange,
                                    ),
                                    tooltip: 'Editar',
                                    onPressed: () {
                                      // Adicione a ação de editar este 'item'
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 4),

              // 3. BOTÃO DE ADICIONAR NO CANTO INFERIOR DIREITO
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    // Adicione a ação de criar um novo nível
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: const Text('Adicionar Nível'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  Widget executiveCommitteeTable() {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Executive Committee',
        // prefixIcon: Icon(Icons.stars),
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.all(12),
      ),
      child: ValueListenableBuilder<List<VExecutiveCommitteeTermOfOfficeMembersModel>?>(
        valueListenable: bdVExecutiveCommitteeTermOfOfficeMembersController
            .vExecutiveCommitteeTermOfOfficeMembersNotifier,
        builder: (context, historyList, child) {
          final bool temItens = historyList != null && historyList.isNotEmpty;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. ÁREA DOS CARDS / LISTA
              if (!temItens)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    'Nenhum registro encontrado.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: Scrollbar(
                    controller:
                        _executiveCommiteeScrollController, // <--- PASSE O CONTROLLER AQUI
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller:
                          _executiveCommiteeScrollController, // <--- PASSE O CONTROLLER AQUI
                      scrollDirection: Axis.vertical,
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: historyList.map((item) {
                          final String diretoria =
                              item.ect_name?.toString() ?? '-';
                          final String cargo = item.ecm_name?.toString() ?? '-';
                          final String? motivo = item.ectm_motivo_saida
                              .toString();
                          final String dataStart = generalService
                              .formatarDataBr(item.ectm_date_start.toString());
                          final String dataEnd = generalService.formatarDataBr(
                            item.ectm_date_end.toString(),
                          );

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 8.0),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 8.0,
                              ),
                              child: Row(
                                children: [
                                  // Informações do Nível
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cargo,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.deepOrangeAccent,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          motivo.toString().isNotEmpty
                                              ? 'Diretoria: $diretoria - Data: $dataStart até $dataEnd \nDescrição: $motivo'
                                              : 'Diretoria: $diretoria - Data: $dataStart até $dataEnd',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: dataEnd.isEmpty
                                                ? Colors.tealAccent
                                                : Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // 2. BOTÃO DE EDITAR NO LADO DIREITO
                                  // IconButton(
                                  //   icon: const Icon(
                                  //     Icons.edit,
                                  //     color: Colors.orange,
                                  //   ),
                                  //   tooltip: 'Editar',
                                  //   onPressed: () {
                                  //     // Adicione a ação de editar este 'item'
                                  //   },
                                  // ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),

              // const SizedBox(height: 4),

              // // 3. BOTÃO DE ADICIONAR NO CANTO INFERIOR DIREITO
              // Align(
              //   alignment: Alignment.centerRight,
              //   child: TextButton.icon(
              //     onPressed: () {
              //       // Adicione a ação de criar um novo nível
              //     },
              //     icon: const Icon(Icons.add_circle_outline, size: 20),
              //     label: const Text('Adicionar Nível'),
              //     style: TextButton.styleFrom(
              //       foregroundColor: Colors.indigo,
              //       padding: const EdgeInsets.symmetric(
              //         horizontal: 12,
              //         vertical: 8,
              //       ),
              //     ),
              //   ),
              // ),
            ],
          );
        },
      ),
    );
  }
}
