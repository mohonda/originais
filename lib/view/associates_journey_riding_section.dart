import 'package:flutter/material.dart';
import 'package:originais/controllers/journey_riding_controller.dart';
import 'package:originais/models/journeyriding_model.dart';
import 'package:originais/models/vprofile_model.dart';
import 'package:originais/services/general_service.dart';
import 'package:originais/view/profile_journey_riding.dart';

class AssociatesJourneyRidingSection extends StatefulWidget {
  final VProfileModel itemAtual;

  const AssociatesJourneyRidingSection({
    super.key,
    required this.itemAtual,
  });

  @override
  State<AssociatesJourneyRidingSection> createState() =>
      _AssociatesJourneyRidingSectionState();
}

class _AssociatesJourneyRidingSectionState
    extends State<AssociatesJourneyRidingSection> {
  final bdJourneyRidingController =
      getItBdJourneyRidingController<BdJourneyRidingController>();
  final generalService = getItGeneralService<GeneralService>();

  /// Extrai o valor numérico do nível com segurança
  int _parseLevel(dynamic lvl) {
    if (lvl == null) return 0;
    return int.tryParse(lvl.toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  /// Verifica se a etapa é inicial (sem precursor)
  bool _isInitialStage(JourneyRidingModel stage) {
    final precursory = stage.jr_id_precursory?.toString().trim();
    return precursory == null || precursory.isEmpty || precursory == '0';
  }

  /// Busca a lista de opções válidas para o próximo registro
  List<JourneyRidingModel> _obterOpcoesProximoNivel() {
     bdJourneyRidingController.loadJourneyRidingDetais(
                        widget.itemAtual.pfl_id.toString(),
                        widget.itemAtual.hld_id.toString(),
                      );
    bdJourneyRidingController.loadJourneyRidingOrderByLevel(
      widget.itemAtual.hld_id.toString()
    );

    final history =
        bdJourneyRidingController.vProfileJourneyridingDetaisNotifier.value ?? [];
    final catalog =
        bdJourneyRidingController.journeyRidingOrderByLevelNotifier.value ?? [];

    if (catalog.isEmpty) return [];

    // 1. Caso SEM Histórico: Busca todas as etapas de início (sem precursor)
    if (history.isEmpty) {
      final iniciais = catalog.where(_isInitialStage).toList();
      return iniciais.isNotEmpty ? iniciais : catalog;
    }

    // 2. Caso COM Histórico: Descobre o maior nível atual
    int currentLevel = 0;
    for (var item in history) {
      int lvl = _parseLevel(item.jr_level);
      if (lvl > currentLevel) currentLevel = lvl;
    }

    // final catalogOrdenado = List<JourneyRidingModel>.from(catalog)
    //   ..sort((a, b) => _parseLevel(a.jr_level).compareTo(_parseLevel(b.jr_level)));

    int? proximoLevelNum;
    for (var stage in catalog) {
      int lvl = _parseLevel(stage.jr_level);
      if (lvl > currentLevel) {
        proximoLevelNum = lvl;
        break;
      }
    }

    if (proximoLevelNum == null) return [];

    return catalog
        .where((stage) => _parseLevel(stage.jr_level) == proximoLevelNum)
        .toList();
  }

  bool _temProximoNivel() {
    return _obterOpcoesProximoNivel().isNotEmpty;
  }

  // ==========================================
  // DIÁLOGO DE ADIÇÃO (CADASTRO)
  // ==========================================
  void _showAddJourneyDialog() {
    final opcoesNivel = _obterOpcoesProximoNivel();

    if (opcoesNivel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este associado já atingiu o nível máximo da jornada!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    JourneyRidingModel? nivelSelecionado = opcoesNivel.first;
    DateTime dataSelecionada = DateTime.now();
    final TextEditingController dateController = TextEditingController(
      text: generalService.formatarDataBr(dataSelecionada.toIso8601String()),
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
                  Text('Adicionar Jornada', style: TextStyle(fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<JourneyRidingModel>(
                      value: nivelSelecionado,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Selecione a Jornada',
                        prefixIcon: Icon(Icons.stars),
                        border: OutlineInputBorder(),
                      ),
                      items: opcoesNivel.map((stage) {
                        final String nome = stage.jr_nome ?? 'Sem Nome';
                        final String lvl = stage.jr_level?.toString() ?? '-';
                        return DropdownMenuItem<JourneyRidingModel>(
                          value: stage,
                          child: Text('$nome (Nível $lvl)'),
                        );
                      }).toList(),
                      onChanged: opcoesNivel.length > 1
                          ? (novoValor) {
                              setStateDialog(() {
                                nivelSelecionado = novoValor;
                              });
                            }
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: dateController,
                      readOnly: true,
                      enableInteractiveSelection: false,
                      decoration: const InputDecoration(
                        labelText: 'Data da Promoção',
                        prefixIcon: Icon(Icons.calendar_month),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                        border: OutlineInputBorder(),
                      ),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: dataSelecionada,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setStateDialog(() {
                            dataSelecionada = picked;
                            dateController.text = generalService.formatarDataBr(
                              picked.toIso8601String(),
                            );
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
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Confirmar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (nivelSelecionado == null) return;

                    await bdJourneyRidingController.insertProfileJourneyRiding(
                      widget.itemAtual.pfl_id,
                      widget.itemAtual.hld_id,
                      nivelSelecionado!.jr_id.toString(),
                      dataSelecionada.toIso8601String(),
                    );
                    if (mounted) {
                      Navigator.of(dialogContext).pop();
                      bdJourneyRidingController.loadJourneyRidingDetais(
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
  void _showEditJourneyDialog(JourneyRidingModel item) {
    // Tenta parsear a data existente do registro ou usa a data atual
    DateTime dataSelecionada = DateTime.tryParse(item.uj_promotion_date ?? '') ??
        DateTime.tryParse(item.uj_promotion_date ?? '') ??
        DateTime.now();

    final TextEditingController dateController = TextEditingController(
      text: generalService.formatarDataBr(dataSelecionada.toIso8601String()),
    );

    final String nomeNivel = item.jr_nome ?? 'Nível Cadastrado';
    final String lvlNum = item.jr_level?.toString() ?? '-';

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
                  Text('Editar Jornada', style: TextStyle(fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Campo Nível (Desabilitado / Apenas Leitura)
                    TextFormField(
                      initialValue: '$nomeNivel (Nível $lvlNum)',
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Nível da Jornada',
                        prefixIcon: Icon(Icons.stars),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Campo Data (Editável via DatePicker)
                    TextFormField(
                      controller: dateController,
                      readOnly: true,
                      enableInteractiveSelection: false,
                      decoration: const InputDecoration(
                        labelText: 'Data da Promoção',
                        prefixIcon: Icon(Icons.calendar_month),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                        border: OutlineInputBorder(),
                      ),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: dataSelecionada,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setStateDialog(() {
                            dataSelecionada = picked;
                            dateController.text = generalService.formatarDataBr(
                              picked.toIso8601String(),
                            );
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actions: [
                // Botão Excluir (Lado Esquerdo)
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  label: const Text('Excluir', style: TextStyle(color: Colors.red)),
                  onPressed: () async {
                    final bool? confirmar = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Confirmar Exclusão'),
                        content: Text(
                          'Deseja remover o nível "$nomeNivel" deste associado?',
                        ),
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
                      final String pjrId = item.uj_id?.toString() ?? item.uj_id.toString();
                      await bdJourneyRidingController.deleteProfileJourneyRiding(pjrId, item.pfl_id, item.hld_id );

                      if (mounted) {
                        Navigator.of(dialogContext).pop();
                        bdJourneyRidingController.loadJourneyRidingDetais(
                          widget.itemAtual.pfl_id.toString(),
                          widget.itemAtual.hld_id.toString(),
                        );
                      }
                    }
                  },
                ),

                // Botões Cancelar e Salvar (Lado Direito)
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
                        final String pjrId = item.uj_id?.toString() ?? item.uj_id.toString();
                        await bdJourneyRidingController.updateProfileJourneyRiding(
                          pjrId,
                          item.pfl_id,
                          item.hld_id,
                          item.jr_id,
                          dataSelecionada.toIso8601String(),
                        );

                        if (mounted) {
                          Navigator.of(dialogContext).pop();
                          bdJourneyRidingController.loadJourneyRidingDetais(
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
          // Passamos o callback de edição para o componente interno
          ProfileJourneyRiding(
            pflId: widget.itemAtual.pfl_id.toString(),
            hldId: widget.itemAtual.hld_id.toString(),
            onEdit: _showEditJourneyDialog, // Callback acionado ao clicar em Editar
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<List<JourneyRidingModel>>(
            valueListenable:
                bdJourneyRidingController.vProfileJourneyridingDetaisNotifier,
            builder: (context, history, child) {
              return ValueListenableBuilder<List<JourneyRidingModel>>(
                valueListenable:
                    bdJourneyRidingController.journeyRidingOrderByLevelNotifier,
                builder: (context, catalog, child) {
                  if (!_temProximoNivel()) {
                    return const SizedBox.shrink();
                  }

                  return Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _showAddJourneyDialog,
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
                  );
                },
              );
            },
          ),
        ],
    );
  }
}