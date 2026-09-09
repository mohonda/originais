import 'package:flutter/material.dart';
import 'package:originais/controllers/profile_associate_status_controller.dart';
import 'package:originais/models/vprofile_model.dart';
import 'package:originais/models/profile_associate_status_model.dart';
import 'package:originais/services/general_service.dart';
import 'package:originais/view/profile_associate_status.dart';

class AssociatesAssociateStatusSection extends StatefulWidget {
  final VProfileModel itemAtual;

  const AssociatesAssociateStatusSection({
    super.key,
    required this.itemAtual,
  });

  @override
  State<AssociatesAssociateStatusSection> createState() =>
      _AssociatesAssociateStatusSectionState();
}

class _AssociatesAssociateStatusSectionState
    extends State<AssociatesAssociateStatusSection> {
  late final BdVProfileAssociateStatusController controller;
  final GeneralService generalService = GeneralService();

  @override
  void initState() {
    super.initState();
    controller = getItBdVProfileAssociateStatusController
        .get<BdVProfileAssociateStatusController>();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarDados();
    });
  }

  @override
  void didUpdateWidget(covariant AssociatesAssociateStatusSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 🟢 Se o item mudar, recarrega os dados com segurança fora do ciclo de build
    if (oldWidget.itemAtual.pfl_id != widget.itemAtual.pfl_id ||
        oldWidget.itemAtual.hld_id != widget.itemAtual.hld_id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _carregarDados();
      });
    }
  }

  void _carregarDados() {
    final pflId = widget.itemAtual.pfl_id?.toString() ?? '';
    final hldId = widget.itemAtual.hld_id?.toString() ?? '';

    if (pflId.isNotEmpty && hldId.isNotEmpty) {
      controller.loadProfileAssociateStatus(pflId, hldId);
    }
  }

  // ==========================================
  // DIÁLOGO DE ADIÇÃO (CADASTRO)
  // ==========================================
  void _showAddStatusDialog() async {
    // Busca a lista de status disponíveis (Ex: Ativo, Licenciado, Desligado)
    final listOpcoesStatus = await controller.loadAvailableAssociateStatus(
      widget.itemAtual.hld_id.toString(),
    );

    if (!mounted) return;

    if (listOpcoesStatus.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum tipo de status disponível para cadastro.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    dynamic statusSelecionado = listOpcoesStatus.first;
    DateTime dataRegistro = DateTime.now();

    final TextEditingController dateController = TextEditingController(
      text: generalService.formatarDataBr(dataRegistro.toIso8601String()),
    );

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
                  Text('Adicionar Status do Associado', style: TextStyle(fontSize: 17)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 📋 Selection Combobox
                    DropdownButtonFormField<dynamic>(
                      initialValue: statusSelecionado,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Novo Status',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: listOpcoesStatus.map((st) {
                        return DropdownMenuItem<dynamic>(
                          value: st,
                          child: Text(
                            st.as_desc ?? 'Sem Descrição',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (novoStatus) {
                        setStateDialog(() {
                          statusSelecionado = novoStatus;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // 📅 Data de Registro
                    TextFormField(
                      controller: dateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Data do Status *',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dataRegistro,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setStateDialog(() {
                            dataRegistro = picked;
                            dateController.text =
                                generalService.formatarDataBr(picked.toIso8601String());
                          });
                        }
                      },
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
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (statusSelecionado == null) return;

                    // await controller.insertProfileAssociateStatus(
                    //   pflId: widget.itemAtual.pfl_id.toString(),
                    //   hldId: widget.itemAtual.hld_id.toString(),
                    //   asId: statusSelecionado.as_id.toString(),
                    //   date: dataRegistro.toIso8601String(),
                    // );

                    if (mounted) {
                      Navigator.of(dialogContext).pop();
                      controller.loadProfileAssociateStatus(
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
  // DIÁLOGO DE EDIÇÃO / EXCLUSÃO
  // ==========================================
  void _showEditStatusDialog(VProfileAssociateStatusModel item) {
    DateTime dataRegistro =
        DateTime.tryParse(item.pas_date ?? '') ?? DateTime.now();

    final TextEditingController dateController = TextEditingController(
      text: generalService.formatarDataBr(dataRegistro.toIso8601String()),
    );

    final String statusNome = item.as_desc ?? 'Status do Associado';

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
                  Text('Editar Status do Associado', style: TextStyle(fontSize: 17)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      initialValue: statusNome,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Status Registrado',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: dateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Data do Status',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dataRegistro,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setStateDialog(() {
                            dataRegistro = picked;
                            dateController.text =
                                generalService.formatarDataBr(picked.toIso8601String());
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actions: [
                // Botão Excluir
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  label: const Text('Excluir', style: TextStyle(color: Colors.red)),
                  onPressed: () async {
                    final bool? confirmar = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Confirmar Exclusão'),
                        content: Text('Deseja remover o status "$statusNome"?'),
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
                      // await controller.deleteProfileAssociateStatus(item.pas_id);

                      // if (mounted) {
                      //   Navigator.of(dialogContext).pop();
                      //   controller.loadProfileAssociateStatus(
                      //     widget.itemAtual.pfl_id.toString(),
                      //     widget.itemAtual.hld_id.toString(),
                      //   );
                      // }
                    }
                  },
                ),

                // Botões Cancelar e Salvar
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
                        // await controller.updateProfileAssociateStatus(
                        //   pasId: item.pas_id,
                        //   date: dataRegistro.toIso8601String(),
                        // );

                        if (mounted) {
                          Navigator.of(dialogContext).pop();
                          controller.loadProfileAssociateStatus(
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
          ProfileAssociateStatus(
            controller: controller,
            pflId: widget.itemAtual.pfl_id.toString(),
            hldId: widget.itemAtual.hld_id.toString(),
            onEdit: _showEditStatusDialog,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _showAddStatusDialog,
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text('Add Associate Status...'),
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
  }
}