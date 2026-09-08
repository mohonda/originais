import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:originais/models/vprofile_model.dart';
import 'package:originais/services/general_service.dart';
import 'package:originais/models/custom_app_bar.dart';
import 'package:originais/controllers/bd_vprofile_associatestatus_controller.dart';
import 'package:originais/controllers/bd_vprofiles_sanctions_controller.dart';
import 'package:originais/controllers/bd_vexecutive_committee_termofoffice_members_controller.dart';
import 'package:originais/models/vprofile_associatestatus_model.dart';
import 'package:originais/models/vprofiles_sanctions_model.dart';
import 'package:originais/models/vexecutive_committee_termofoffice_members_model.dart';

// Importe o novo componente criado
import 'package:originais/view/associatesJourneyRidingSection.dart';

class AssociatesDetails extends StatefulWidget {
  final VProfileModel itemAtual;

  const AssociatesDetails({super.key, required this.itemAtual});

  @override
  State<AssociatesDetails> createState() => AssociatesDetailsState();
}

class AssociatesDetailsState extends State<AssociatesDetails> {
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

  final ScrollController _associateStatusScrollController = ScrollController();
  final ScrollController _sanctionScrollController = ScrollController();
  final ScrollController _executiveCommiteeScrollController =
      ScrollController();

  @override
  void initState() {
    idController.text = widget.itemAtual.pfl_id.toString();
    fullNameController.text = widget.itemAtual.pfl_full_name.toString();
    hldController.text = widget.itemAtual.hld_name.toString();

    super.initState();
  }

  @override
  void dispose() {
    _associateStatusScrollController.dispose();
    _sanctionScrollController.dispose();
    _executiveCommiteeScrollController.dispose();

    super.dispose();
  }

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
                          // Substituto isolado da tabela de jornada
                          AssociatesJourneyRidingSection(
                            itemAtual: widget.itemAtual,
                          ),
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
  Widget associateStatusTable() {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Associate Status',
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
                    controller: _associateStatusScrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _associateStatusScrollController,
                      scrollDirection: Axis.vertical,
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: historyList.map((item) {
                          final String status = item.as_desc.toString();
                          final String percent =
                              item.pas_monthly_percent.toString();
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
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.orange,
                                    ),
                                    tooltip: 'Editar',
                                    onPressed: () {},
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

              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {},
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
                    controller: _sanctionScrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _sanctionScrollController,
                      scrollDirection: Axis.vertical,
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: historyList.map((item) {
                          final String sanName = item.san_name.toString();
                          final String psanDesc = item.psan_desc.toString();

                          final String psanValue = generalService
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
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sanName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: sanColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Início: $dateStart - Final: $dateEnd - Valor: $psanValue \nDescrição: $psanDesc',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: sanColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.orange,
                                    ),
                                    tooltip: 'Editar',
                                    onPressed: () {},
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

              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {},
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
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.all(12),
      ),
      child: ValueListenableBuilder<
          List<VExecutiveCommitteeTermOfOfficeMembersModel>?>(
        valueListenable: bdVExecutiveCommitteeTermOfOfficeMembersController
            .vExecutiveCommitteeTermOfOfficeMembersNotifier,
        builder: (context, historyList, child) {
          final bool temItens = historyList != null && historyList.isNotEmpty;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
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
                    controller: _executiveCommiteeScrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _executiveCommiteeScrollController,
                      scrollDirection: Axis.vertical,
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: historyList.map((item) {
                          final String diretoria = item.ect_name.toString();
                          final String cargo = item.ecm_name.toString();
                          final String motivo = item.ectm_motivo_saida.toString();
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
                                          motivo.isNotEmpty
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
                                ],
                              ),
                            ),
                          );
                        }).toList(),
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
}