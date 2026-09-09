import 'package:flutter/material.dart';
import 'package:originais/controllers/profiles_sanctions_controller.dart';
import 'package:originais/models/vprofile_model.dart';
import 'package:originais/models/profiles_sanctions_model.dart';
import 'package:originais/services/general_service.dart';
import 'package:originais/view/profile_sanctions.dart';

class AssociatesSanctionsSection extends StatefulWidget {
  final VProfileModel itemAtual;

  const AssociatesSanctionsSection({
    super.key,
    required this.itemAtual,
  });

  @override
  State<AssociatesSanctionsSection> createState() =>
      _AssociatesSanctionsSectionState();
}

class _AssociatesSanctionsSectionState
    extends State<AssociatesSanctionsSection> {
  late final BdVProfilesSanctionsController controller;
  final GeneralService generalService = GeneralService();

  @override
  void initState() {
    super.initState();
    controller = getItBdVProfilesSanctionsController
        .get<BdVProfilesSanctionsController>();
  }

  // ==========================================
  // DIÁLOGO DE ADIÇÃO (CADASTRO DE SANÇÃO)
  // ==========================================
  void _showAddSanctionDialog() async {
    final listOpcoesSancoes = await controller.loadAvailableSanctions(
      widget.itemAtual.hld_id.toString(),
    );

    if (!mounted) return;

    if (listOpcoesSancoes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum tipo de sanção disponível no sistema.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    dynamic sancaoSelecionada = listOpcoesSancoes.first;
    DateTime dataInicio = DateTime.now();
    DateTime? dataFim;

    final TextEditingController startDateController = TextEditingController(
      text: generalService.formatarDataBr(dataInicio.toIso8601String()),
    );
    final TextEditingController endDateController = TextEditingController();
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
                  Icon(Icons.gavel, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text('Aplicar Sanção Disciplinar', style: TextStyle(fontSize: 17)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 📋 Seleção do Tipo de Sanção
                    DropdownButtonFormField<dynamic>(
                      initialValue: sancaoSelecionada,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Sanção',
                        prefixIcon: Icon(Icons.gavel_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: listOpcoesSancoes.map((sn) {
                        return DropdownMenuItem<dynamic>(
                          value: sn,
                          child: Text(
                            sn.san_name ?? 'Sem Nome',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (novaSancao) {
                        setStateDialog(() {
                          sancaoSelecionada = novaSancao;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // 📅 Data de Início
                    TextFormField(
                      controller: startDateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Data de Início *',
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
                            startDateController.text =
                                generalService.formatarDataBr(picked.toIso8601String());
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    // 📅 Data de Término (Opcional)
                    TextFormField(
                      controller: endDateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Término Previsto (Opcional)',
                        prefixIcon: const Icon(Icons.event_busy),
                        border: const OutlineInputBorder(),
                        suffixIcon: endDateController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  setStateDialog(() {
                                    dataFim = null;
                                    endDateController.clear();
                                  });
                                },
                              )
                            : null,
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
                            endDateController.text =
                                generalService.formatarDataBr(picked.toIso8601String());
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    // 📝 Observações / Detalhes
                    TextFormField(
                      controller: obsController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Observações / Motivos',
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
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Confirmar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (sancaoSelecionada == null) return;

                    // await controller.insertProfileSanction(
                    //   pflId: widget.itemAtual.pfl_id.toString(),
                    //   hldId: widget.itemAtual.hld_id.toString(),
                    //   sanId: sancaoSelecionada.san_id.toString(),
                    //   dateStart: dataInicio.toIso8601String(),
                    //   dateEnd: dataFim?.toIso8601String(),
                    //   desc: obsController.text,
                    // );

                    if (mounted) {
                      Navigator.of(dialogContext).pop();
                      controller.loadProfileSanctionsStatus(
                        widget.itemAtual.pfl_id.toString(),
                        widget.itemAtual.hld_id.toString(),
                      );
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

  // ==========================================
  // DIÁLOGO DE EDIÇÃO / EXCLUSÃO DE SANÇÃO
  // ==========================================
  void _showEditSanctionDialog(VProfilesSanctionsModel item) {
    DateTime dataInicio =
        DateTime.tryParse(item.psan_date_start ?? '') ?? DateTime.now();
    DateTime? dataFim = DateTime.tryParse(item.psan_date_end ?? '');

    final TextEditingController startDateController = TextEditingController(
      text: generalService.formatarDataBr(dataInicio.toIso8601String()),
    );
    final TextEditingController endDateController = TextEditingController(
      text: dataFim != null ? generalService.formatarDataBr(dataFim.toIso8601String()) : '',
    );
    final TextEditingController obsController = TextEditingController(
      text: item.psan_desc ?? '',
    );

    final String sancaoNome = item.san_name ?? 'Sanção Disciplinar';

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
                  Text('Editar Sanção Disciplinar', style: TextStyle(fontSize: 17)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      initialValue: sancaoNome,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Sanção',
                        prefixIcon: Icon(Icons.gavel),
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
                            startDateController.text =
                                generalService.formatarDataBr(picked.toIso8601String());
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: endDateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Término Previsto / Conclusão',
                        prefixIcon: const Icon(Icons.event_busy),
                        border: const OutlineInputBorder(),
                        suffixIcon: endDateController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  setStateDialog(() {
                                    dataFim = null;
                                    endDateController.clear();
                                  });
                                },
                              )
                            : null,
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
                            endDateController.text =
                                generalService.formatarDataBr(picked.toIso8601String());
                          });
                        }
                      },
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
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actions: [
                // Botão de Exclusão
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  label: const Text('Excluir', style: TextStyle(color: Colors.red)),
                  onPressed: () async {
                    final bool? confirmar = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Confirmar Exclusão'),
                        content: Text('Deseja remover a sanção "$sancaoNome"?'),
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
                      // await controller.deleteProfileSanction(item.psan_id);

                      if (mounted) {
                        Navigator.of(dialogContext).pop();
                        controller.loadProfileSanctionsStatus(
                          widget.itemAtual.pfl_id.toString(),
                          widget.itemAtual.hld_id.toString(),
                        );
                      }
                    }
                  },
                ),

                // Salvar e Cancelar
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
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
                        // await controller.updateProfileSanction(
                        //   psanId: item.psan_id,
                        //   dateStart: dataInicio.toIso8601String(),
                        //   dateEnd: dataFim?.toIso8601String(),
                        //   desc: obsController.text,
                        // );

                        if (mounted) {
                          Navigator.of(dialogContext).pop();
                          controller.loadProfileSanctionsStatus(
                            widget.itemAtual.pfl_id.toString(),
                            widget.itemAtual.hld_id.toString(),
                          );
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
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ProfileSanctions(
            controller: controller,
            pflId: widget.itemAtual.pfl_id.toString(),
            hldId: widget.itemAtual.hld_id.toString(),
            onEdit: _showEditSanctionDialog,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _showAddSanctionDialog,
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text('Add Sanction...'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ],
    );
  }
}