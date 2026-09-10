import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:originais/controllers/sanctions_controller.dart';
import 'package:originais/controllers/profiles_sanctions_controller.dart';
import 'package:originais/models/sanctions_model.dart';
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
  late final SanctionsController sanctionsController;
  final GeneralService generalService = GeneralService();

  @override
  void initState() {
    super.initState();
    controller = getItBdVProfilesSanctionsController
        .get<BdVProfilesSanctionsController>();

    // Controller responsável por buscar a lista de sanções da Holding
    sanctionsController = SanctionsController();
  }

  @override
  void dispose() {
    sanctionsController.dispose();
    super.dispose();
  }

  // ==========================================
  // DIÁLOGO DE ADIÇÃO (CADASTRO DE SANÇÃO)
  // ==========================================
  void _showAddSanctionDialog() async {
    // 🟢 Busca as sanções cadastradas via Controller da Tabela de Sanções
    await sanctionsController.loadSanctions(
      widget.itemAtual.hld_id.toString(),
    );

    final listOpcoesSancoes = sanctionsController.sanctionsNotifier.value;

    if (!mounted) return;

    if (listOpcoesSancoes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum tipo de sanção cadastrado para esta Holding.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    SanctionsModel? sancaoSelecionada = listOpcoesSancoes.first;
    DateTime dataInicio = DateTime.now();
    DateTime? dataFim;

    final TextEditingController startDateController = TextEditingController(
      text: generalService.formatarDataBr(dataInicio.toIso8601String()),
    );
    final TextEditingController endDateController = TextEditingController();
    final TextEditingController valueController = TextEditingController();
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
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 📋 COMBOBOX DE TIPO DE SANÇÃO
                      DropdownButtonFormField<SanctionsModel>(
                        value: sancaoSelecionada,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Sanção *',
                          prefixIcon: Icon(Icons.gavel_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: listOpcoesSancoes.map((SanctionsModel itemSan) {
                          return DropdownMenuItem<SanctionsModel>(
                            value: itemSan,
                            child: Text(
                              itemSan.sanName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        validator: (value) {
                          if (value == null) return 'Selecione o tipo de sanção';
                          return null;
                        },
                        onChanged: (SanctionsModel? novaSancao) {
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
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe a data de início';
                          }
                          return null;
                        },
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

                      // 📅 Data de Término
                      TextFormField(
                        controller: endDateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Término Previsto *',
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
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe a data de término';
                          }
                          if (dataFim != null && !dataFim!.isAfter(dataInicio)) {
                            return 'A data de término deve ser posterior à data de início';
                          }
                          return null;
                        },
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: (dataFim != null && dataFim!.isAfter(dataInicio))
                                ? dataFim!
                                : dataInicio.add(const Duration(days: 1)),
                            firstDate: dataInicio.add(const Duration(days: 1)),
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

                      // 💵 Valor
                      TextFormField(
                        controller: valueController,
                        maxLines: 1,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Valor *',
                          prefixIcon: Icon(Icons.attach_money),
                          prefixText: 'R\$ ',
                          border: OutlineInputBorder(),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+[\,\.]?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe o valor';
                          }
                          final parsedValue =
                              double.tryParse(value.replaceAll(',', '.'));
                          if (parsedValue == null) {
                            return 'Digite um valor válido';
                          }
                          if (parsedValue <= 0) {
                            return 'O valor deve ser maior que zero';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // 📝 Observações / Motivo
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
                    // 🟢 SUBMISSÃO COM VALIDAÇÃO
                    if (!formKey.currentState!.validate()) return;
                    if (sancaoSelecionada == null) return;

                    await controller.insertProfileSanction(
                      widget.itemAtual.pfl_id.toString(),
                      widget.itemAtual.hld_id.toString(),
                      sancaoSelecionada!.sanId.toString(),
                      valueController.text,
                      dataInicio.toIso8601String(),
                      dataFim?.toIso8601String() ?? '',
                      obsController.text,
                    );

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
  void _showEditSanctionDialog(VProfilesSanctionsModel item) async {
    await sanctionsController.loadSanctions(
      widget.itemAtual.hld_id.toString(),
    );
    final listOpcoesSancoes = sanctionsController.sanctionsNotifier.value;

    if (!mounted) return;

    final formKey = GlobalKey<FormState>();

    SanctionsModel? sancaoSelecionada;
    try {
      sancaoSelecionada = listOpcoesSancoes.firstWhere(
        (element) => element.sanId.toString() == item.psan_san_id.toString(),
      );
    } catch (_) {
      sancaoSelecionada =
          listOpcoesSancoes.isNotEmpty ? listOpcoesSancoes.first : null;
    }

    DateTime dataInicio =
        DateTime.tryParse(item.psan_date_start ?? '') ?? DateTime.now();
    DateTime? dataFim = DateTime.tryParse(item.psan_date_end ?? '');

    final TextEditingController startDateController = TextEditingController(
      text: generalService.formatarDataBr(dataInicio.toIso8601String()),
    );
    final TextEditingController endDateController = TextEditingController(
      text: dataFim != null
          ? generalService.formatarDataBr(dataFim.toIso8601String())
          : '',
    );
    final TextEditingController valueController = TextEditingController(
      text: item.psan_valor?.toString() ?? '',
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
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 📋 COMBOBOX DE SANÇÃO
                      DropdownButtonFormField<SanctionsModel>(
                        value: sancaoSelecionada,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Sanção Disciplinar *',
                          prefixIcon: Icon(Icons.gavel),
                          border: OutlineInputBorder(),
                        ),
                        items: listOpcoesSancoes.map((SanctionsModel itemSan) {
                          return DropdownMenuItem<SanctionsModel>(
                            value: itemSan,
                            child: Text(
                              itemSan.sanName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        validator: (value) {
                          if (value == null) return 'Selecione o tipo de sanção';
                          return null;
                        },
                        onChanged: (SanctionsModel? novaSancao) {
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
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe a data de início';
                          }
                          return null;
                        },
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

                      // 📅 Data de Término
                      TextFormField(
                        controller: endDateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Término Previsto *',
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
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe a data de término';
                          }
                          if (dataFim != null && !dataFim!.isAfter(dataInicio)) {
                            return 'A data de término deve ser posterior à data de início';
                          }
                          return null;
                        },
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: (dataFim != null && dataFim!.isAfter(dataInicio))
                                ? dataFim!
                                : dataInicio.add(const Duration(days: 1)),
                            firstDate: dataInicio.add(const Duration(days: 1)),
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

                      // 💵 Valor
                      TextFormField(
                        controller: valueController,
                        maxLines: 1,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Valor *',
                          prefixIcon: Icon(Icons.attach_money),
                          prefixText: 'R\$ ',
                          border: OutlineInputBorder(),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+[\,\.]?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe o valor';
                          }
                          final parsedValue =
                              double.tryParse(value.replaceAll(',', '.'));
                          if (parsedValue == null) {
                            return 'Digite um valor válido';
                          }
                          if (parsedValue <= 0) {
                            return 'O valor deve ser maior que zero';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // 📝 Observações / Motivo
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
                      await controller.deleteProfileSanction(
                        item.psan_id,
                        item.psan_pfl_id,
                        item.psan_hld_id
                      );

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
                      child:
                          const Text('Cancelar', style: TextStyle(color: Colors.grey)),
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
                        // 🟢 SUBMISSÃO COM VALIDAÇÃO
                        if (!formKey.currentState!.validate()) return;
                        if (sancaoSelecionada == null) return;

                        await controller.updateProfileSanction(
                          item.psan_id,
                          item.psan_pfl_id,
                          item.psan_hld_id,
                          sancaoSelecionada!.sanId.toString(),
                          valueController.text,
                          dataInicio.toIso8601String(),
                          dataFim?.toIso8601String() ?? '',
                          obsController.text,
                        );

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