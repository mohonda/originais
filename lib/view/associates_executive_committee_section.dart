import 'package:flutter/material.dart';
import 'package:originais/controllers/executive_committee_termofoffice_members_controller.dart';
import 'package:originais/controllers/profile_controller.dart';
import 'package:originais/models/vprofile_model.dart';
import 'package:originais/models/executive_committee_termofoffice_members_model.dart';
import 'package:originais/models/executive_committee_vacancy_model.dart';
import 'package:originais/services/general_service.dart';
import 'package:originais/view/profile_executive_committee.dart';

class AssociatesExecutiveCommitteeSection extends StatefulWidget {
  final VProfileModel itemAtual;

  const AssociatesExecutiveCommitteeSection({
    super.key,
    required this.itemAtual,
  });

  @override
  State<AssociatesExecutiveCommitteeSection> createState() =>
      _AssociatesExecutiveCommitteeSectionState();
}

class _AssociatesExecutiveCommitteeSectionState
    extends State<AssociatesExecutiveCommitteeSection> {
  late final BdVExecutiveCommitteeTermOfOfficeMembersController controller;
  late final BdProfileController profileController;
  late final GeneralService generalService;

  @override
  void initState() {
    super.initState();
    // Instancia um controller novo e isolado do Factory do GetIt para este fluxo
    controller = getItBdVExecutiveCommitteeTermOfOfficeMembersController
        .get<BdVExecutiveCommitteeTermOfOfficeMembersController>();
        
    profileController = getItBdProfileController<BdProfileController>();
    generalService = getItGeneralService<GeneralService>();

    controller.errorNotifier.addListener(_handleError);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarDados();
    });
  }

  void _handleError() {
    final errorMessage = controller.errorNotifier.value;
    if (errorMessage != null && errorMessage.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void didUpdateWidget(
      covariant AssociatesExecutiveCommitteeSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.itemAtual.pfl_id != widget.itemAtual.pfl_id ||
        oldWidget.itemAtual.hld_id != widget.itemAtual.hld_id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _carregarDados();
      });
    }
  }

  @override
  void dispose() {
    controller.errorNotifier.removeListener(_handleError);
    // Descarta o controller local ao sair da tela
    controller.dispose();
    super.dispose();
  }

  void _carregarDados() {
    final pessoaLogada = profileController.pessoaSelecionadaNotifier.value;

    final pflId = widget.itemAtual.pfl_id.toString().isNotEmpty
        ? widget.itemAtual.pfl_id.toString()
        : (pessoaLogada?.pfl_id.toString() ?? '');

    final hldId = widget.itemAtual.hld_id.toString().isNotEmpty
        ? widget.itemAtual.hld_id.toString()
        : (pessoaLogada?.hld_id.toString() ?? '');

    if (pflId.isNotEmpty && hldId.isNotEmpty) {
      controller.loadExecutiveOrderByDateStart(pflId, hldId);
    }
  }

  void _showAddExecutiveCommitteeDialog() async {
    final listCargosVagos = await controller.loadExecutiveCommitteeVacancy(
      widget.itemAtual.hld_id.toString(),
    );

    if (!mounted) return;

    if (listCargosVagos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não há cargos executivos vagos para esta gestão.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ExecutiveCommitteeVacancyModel cargoSelecionado = listCargosVagos.first;
    DateTime dataInicio = DateTime.now();

    final TextEditingController startDateController = TextEditingController(
      text: generalService.formatarDataBr(dataInicio.toIso8601String()),
    );

    final TextEditingController endDateController = TextEditingController(
      text: cargoSelecionado.ectmDateEnd != null &&
              cargoSelecionado.ectmDateEnd.toString().isNotEmpty
          ? generalService.formatarDataBr(
              cargoSelecionado.ectmDateEnd.toString(),
            )
          : 'Sem término definido',
    );

    final TextEditingController obsController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.add_circle, color: Colors.indigo),
                  SizedBox(width: 8),
                  Text('Adicionar Cargo Executivo',
                      style: TextStyle(fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<ExecutiveCommitteeVacancyModel>(
                      initialValue: cargoSelecionado,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Cargo Executivo Vago',
                        prefixIcon: Icon(Icons.workspace_premium),
                        border: OutlineInputBorder(),
                      ),
                      items: listCargosVagos.map((cargo) {
                        return DropdownMenuItem<
                            ExecutiveCommitteeVacancyModel>(
                          value: cargo,
                          child: Text(
                            cargo.ecmName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (novoCargo) {
                        if (novoCargo == null) return;
                        setStateDialog(() {
                          cargoSelecionado = novoCargo;

                          if (novoCargo.ectmDateEnd != null &&
                              novoCargo.ectmDateEnd.toString().isNotEmpty) {
                            endDateController.text =
                                generalService.formatarDataBr(
                              novoCargo.ectmDateEnd.toString(),
                            );
                          } else {
                            endDateController.text = 'Sem término definido';
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: startDateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Data de Início',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dataInicio,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setStateDialog(() {
                            dataInicio = picked;
                            startDateController.text = generalService
                                .formatarDataBr(picked.toIso8601String());
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: endDateController,
                      readOnly: true,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Término Previsto (Gestão)',
                        prefixIcon: Icon(Icons.event_busy),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: obsController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Observações / Motivo',
                        prefixIcon: Icon(Icons.notes),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child:
                      const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Confirmar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    await controller.insertExecutiveCommitteeMember(
                      cargoSelecionado.ect_id,
                      cargoSelecionado.ecmId.toString(),
                      widget.itemAtual.pfl_id.toString(),
                      widget.itemAtual.hld_id.toString(),
                      dataInicio.toIso8601String(),
                      obsController.text,
                    );

                    if (mounted) {
                      Navigator.of(dialogContext).pop();
                      // _carregarDados();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditExecutiveCommitteeDialog(
      VExecutiveCommitteeTermOfOfficeMembersModel item) {
    DateTime dataInicio =
        DateTime.tryParse(item.ect_date_start) ?? DateTime.now();
    DateTime? dataFim = DateTime.tryParse(item.ectm_date_end);

    final TextEditingController startDateController = TextEditingController(
      text: generalService.formatarDataBr(dataInicio.toIso8601String()),
    );
    final TextEditingController endDateController = TextEditingController(
      text: dataFim != null
          ? generalService.formatarDataBr(dataFim.toIso8601String())
          : '',
    );
    final TextEditingController obsController = TextEditingController(
      text: item.ectm_motivo_saida,
    );

    final String cargoNome = item.ecm_name;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.edit, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Editar Cargo Executivo',
                      style: TextStyle(fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      initialValue: cargoNome,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Cargo / Comitê',
                        prefixIcon: Icon(Icons.workspace_premium),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: startDateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Data de Início',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dataInicio,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setStateDialog(() {
                            dataInicio = picked;
                            startDateController.text = generalService
                                .formatarDataBr(picked.toIso8601String());
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: endDateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Data de Término',
                        prefixIcon: Icon(Icons.event_busy),
                        border: OutlineInputBorder(),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dataFim ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setStateDialog(() {
                            dataFim = picked;
                            endDateController.text = generalService
                                .formatarDataBr(picked.toIso8601String());
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: obsController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Observações / Motivo Saída',
                        prefixIcon: Icon(Icons.notes),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actions: [
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: Colors.red),
                  label: const Text('Excluir',
                      style: TextStyle(color: Colors.red)),
                  onPressed: () async {
                    final bool? confirmar = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Confirmar Exclusão'),
                        content: Text('Deseja remover o cargo "$cargoNome"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Excluir'),
                          ),
                        ],
                      ),
                    );

                    if (confirmar == true) {
                      await controller.deleteExecutiveCommitteeMember(
                        item.ectm_id,
                        widget.itemAtual.pfl_id.toString(),
                        widget.itemAtual.hld_id.toString(),
                      );

                      if (mounted) {
                        Navigator.of(dialogContext).pop();
                        // _carregarDados();
                      }
                    }
                  },
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Cancelar',
                          style: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save, size: 18),
                      label: const Text('Salvar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        // Método descomentado e ativado para persistência
                        // await controller.updateExecutiveCommitteeMember(
                        //   item.ectm_id,
                        //   widget.itemAtual.pfl_id.toString(),
                        //   widget.itemAtual.hld_id.toString(),
                        //   dataInicio.toIso8601String(),
                        //   dataFim?.toIso8601String() ?? '',
                        //   obsController.text,
                        // );

                        if (mounted) {
                          Navigator.of(dialogContext).pop();
                          // _carregarDados();
                        }
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller.loadingNotifier,
      builder: (context, _) {
        final bool isLoading = controller.loadingNotifier.value;

        return Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Repassa o mesmo controller isolado criado neste State para o filho
                ProfileExecutiveCommittee(
                  pflId: widget.itemAtual.pfl_id.toString(),
                  hldId: widget.itemAtual.hld_id.toString(),
                  controller: controller,
                  onEdit: _showEditExecutiveCommitteeDialog,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed:
                        isLoading ? null : _showAddExecutiveCommitteeDialog,
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    label: const Text('Add Executive Committee...'),
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
            ),
            if (isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.white.withValues(alpha: 0.5),
                  child: Center(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            CircularProgressIndicator(),
                            SizedBox(width: 16),
                            Text(
                              'Processando...',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}