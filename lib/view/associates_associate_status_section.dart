import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:originais/controllers/profile_associate_status_controller.dart';
import 'package:originais/models/vprofile_model.dart';
import 'package:originais/models/profile_associate_status_model.dart';
import 'package:originais/services/general_service.dart';
import 'package:originais/view/profile_associate_status.dart';
import 'package:originais/controllers/associate_status_controller.dart';

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
  late final AssociateStatusController statusController;

  @override
  void initState() {
    super.initState();
    controller = getItBdVProfileAssociateStatusController
        .get<BdVProfileAssociateStatusController>();
    
    statusController = AssociateStatusController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarDados();
    });
  }

  @override
  void didUpdateWidget(covariant AssociatesAssociateStatusSection oldWidget) {
    super.didUpdateWidget(oldWidget);

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
      statusController.loadAssociateStatus(hldId);
    }
  }

  // ==========================================
  // DIÁLOGO DE ADIÇÃO (CADASTRO)
  // ==========================================
  void _showAddStatusDialog() async {
    final listOpcoesStatus = statusController.statusNotifier.value;
    
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

    final formKey = GlobalKey<FormState>();
    dynamic statusSelecionado = listOpcoesStatus.first;
    DateTime dataRegistro = DateTime.now();

    final TextEditingController dateController = TextEditingController(
      text: generalService.formatarDataBr(dataRegistro.toIso8601String()),
    );
    final TextEditingController percentController = TextEditingController();
    percentController.text = '100';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // Extração segura das propriedades informativas do status selecionado
            final bool isMonthly = statusSelecionado != null
                ? (statusSelecionado.asIsMonthlyPayment ?? statusSelecionado.as_ismonthlypayment ?? false)
                : false;

            final int? maxInDays = statusSelecionado != null
                ? (statusSelecionado.asMaxIndays ?? statusSelecionado.as_max_indays)
                : null;

            final int renovacao = statusSelecionado != null
                ? (statusSelecionado.asRenovacao ?? statusSelecionado.as_renovacao ?? 0)
                : 0;

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
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 📋 Selection Combobox
                      DropdownButtonFormField<dynamic>(
                        initialValue: statusSelecionado,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Novo Status *',
                          prefixIcon: Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: listOpcoesStatus.map((st) {
                          return DropdownMenuItem<dynamic>(
                            value: st,
                            child: Text(
                              st.asDesc ?? st.as_desc ?? 'Sem Descrição',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        validator: (value) {
                          if (value == null) return 'Selecione o status';
                          return null;
                        },
                        onChanged: (novoStatus) {
                          setStateDialog(() {
                            statusSelecionado = novoStatus;
                            final bool newIsMonthly = novoStatus != null
                                ? (novoStatus.asIsMonthlyPayment ?? novoStatus.as_ismonthlypayment ?? false)
                                : false;
                            
                            // Limpa a porcentagem se o novo status não for mensalidade
                            if (!newIsMonthly) {
                              percentController.clear();
                            } else {
                              percentController.text = '100';
                            }
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // 🔒 1. CAMPO NÃO EDITÁVEL: Pagamento Mensal
                      TextFormField(
                        key: ValueKey('isMonthly_${statusSelecionado.hashCode}'),
                        initialValue: isMonthly ? 'Sim' : 'Não',
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'Gera Mensalidade',
                          prefixIcon: Icon(Icons.payments_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 🔒 2. CAMPO NÃO EDITÁVEL: Máximo em Dias
                      TextFormField(
                        key: ValueKey('maxIndays_${statusSelecionado.hashCode}'),
                        initialValue: maxInDays != null ? '$maxInDays dias' : 'Não informado',
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'Prazo Máximo (Dias)',
                          prefixIcon: Icon(Icons.timer_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 🔒 3. CAMPO NÃO EDITÁVEL: Renovação
                      TextFormField(
                        key: ValueKey('renovacao_${statusSelecionado.hashCode}'),
                        initialValue: '$renovacao renovação',
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'Renovação',
                          prefixIcon: Icon(Icons.autorenew),
                          border: OutlineInputBorder(),
                        ),
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
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe a data do status';
                          }
                          return null;
                        },
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: dataRegistro,
                            firstDate: DateTime(2026-08-01),
                            lastDate: DateTime(2049-12-31),
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

                      const SizedBox(height: 16),

                      // 🟢 Campo Porcentagem Mensal (Apenas editável quando isMonthly = true)
                      TextFormField(
                        controller: percentController,
                        enabled: isMonthly,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: isMonthly
                              ? 'Porcentagem da Mensalidade (%) *'
                              : 'Porcentagem da Mensalidade (N/A)',
                          prefixIcon: const Icon(Icons.percent),
                          suffixText: '%',
                          border: const OutlineInputBorder(),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+[\,\.]?\d{0,2}')),
                        ],
                        validator: (value) {
                          // Só valida se for pagamento mensal
                          if (!isMonthly) return null;

                          if (value == null || value.trim().isEmpty) {
                            return 'Informe a porcentagem';
                          }

                          final parsed = double.tryParse(value.replaceAll(',', '.'));
                          if (parsed == null) {
                            return 'Digite uma porcentagem válida';
                          }

                          if (parsed < 0 || parsed > 100) {
                            return 'A porcentagem deve estar entre 0 e 100';
                          }

                          return null;
                        },
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
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    if (statusSelecionado == null) return;

                    await controller.insertProfileAssociateStatus(
                      widget.itemAtual.pfl_id.toString(),
                      widget.itemAtual.hld_id.toString(),
                      statusSelecionado.asId.toString(),
                      dataRegistro.toIso8601String(),
                      isMonthly ? percentController.text.toString() : null,
                    );

                    if (mounted) {
                      Navigator.of(dialogContext).pop();
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
    final formKey = GlobalKey<FormState>();
    DateTime dataRegistro =
        DateTime.tryParse(item.pas_date ?? '') ?? DateTime.now();

    final TextEditingController dateController = TextEditingController(
      text: generalService.formatarDataBr(dataRegistro.toIso8601String()),
    );

    // Identifica se o status atual permite pagamento mensal
    final bool isMonthly = item.as_ismonthlypayment ?? false;

    final TextEditingController percentController = TextEditingController(
      text: item.pas_monthly_percent?.toString() ?? '',
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
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
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
                          labelText: 'Data do Status *',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe a data do status';
                          }
                          return null;
                        },
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
                      const SizedBox(height: 16),

                      // 🟢 Porcentagem da Mensalidade na Edição
                      TextFormField(
                        controller: percentController,
                        enabled: isMonthly,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: isMonthly
                              ? 'Porcentagem da Mensalidade (%) *'
                              : 'Porcentagem da Mensalidade (N/A)',
                          prefixIcon: const Icon(Icons.percent),
                          suffixText: '%',
                          border: const OutlineInputBorder(),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+[\,\.]?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (!isMonthly) return null;

                          if (value == null || value.trim().isEmpty) {
                            return 'Informe a porcentagem';
                          }

                          final parsed = double.tryParse(value.replaceAll(',', '.'));
                          if (parsed == null) {
                            return 'Digite uma porcentagem válida';
                          }

                          if (parsed < 0 || parsed > 100) {
                            return 'A porcentagem deve estar entre 0 e 100';
                          }

                          return null;
                        },
                      ),
                    ],
                  ),
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
                      await controller.deleteProfileAssociateStatus(
                        item.pas_id,
                        item.pas_pfl_id,
                        item.pas_hld_id
                      );

                      if (mounted) {
                        Navigator.of(dialogContext).pop();
                      }
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
                        if (!formKey.currentState!.validate()) return;

                        await controller.updateProfileAssociateStatus(
                          item.pas_id,
                          item.pas_pfl_id,
                          item.pas_hld_id,
                          dataRegistro.toIso8601String(),
                          isMonthly ? percentController.text.toString() : null,
                        );

                        if (mounted) {
                          Navigator.of(dialogContext).pop();
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