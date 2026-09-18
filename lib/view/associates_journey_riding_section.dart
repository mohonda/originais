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

  int _refreshKey = 0;

  // ==========================================
  @override
  void initState() {
    super.initState();

    bdJourneyRidingController.errorNotifier.addListener(_handleError);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarDados();
    });
  }

  // ==========================================
  void _handleError() {
    final errorMessage = bdJourneyRidingController.errorNotifier.value;
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

  // ==========================================
  @override
  void didUpdateWidget(covariant AssociatesJourneyRidingSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.itemAtual.pfl_id != widget.itemAtual.pfl_id ||
        oldWidget.itemAtual.hld_id != widget.itemAtual.hld_id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _carregarDados();
      });
    }
  }

  // ==========================================
  @override
  void dispose() {
    bdJourneyRidingController.errorNotifier.removeListener(_handleError);
    super.dispose();
  }

  // ==========================================
  Future<void> _carregarDados() async {
    final pflId = widget.itemAtual.pfl_id.toString();
    final hldId = widget.itemAtual.hld_id.toString();

    if (pflId.isNotEmpty && hldId.isNotEmpty) {
      await bdJourneyRidingController.loadJourneyRidingDetais(pflId, hldId);
      await bdJourneyRidingController.loadJourneyRidingOrderByLevel(hldId);
      if (mounted) {
        setState(() {
          _refreshKey++;
        });
      }
    }
  }

  // ==========================================
  int _parseLevel(dynamic lvl) {
    if (lvl == null) return 0;
    return int.tryParse(lvl.toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  // ==========================================
  bool _isInitialStage(JourneyRidingModel stage) {
    final precursory = stage.jr_id_precursory.toString().trim();
    return precursory.isEmpty || precursory == '0';
  }

  // ==========================================
  List<JourneyRidingModel> _obterOpcoesProximoNivel() {
    final history =
        bdJourneyRidingController.vProfileJourneyridingDetaisNotifier.value;
    final catalog =
        bdJourneyRidingController.journeyRidingOrderByLevelNotifier.value;

    if (catalog.isEmpty) return [];

    if (history.isEmpty) {
      final iniciais = catalog.where(_isInitialStage).toList();
      return iniciais.isNotEmpty ? iniciais : catalog;
    }

    int currentLevel = 0;
    for (var item in history) {
      int lvl = _parseLevel(item.jr_level);
      if (lvl > currentLevel) currentLevel = lvl;
    }

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
                        final String nome = stage.jr_nome;
                        final String lvl = stage.jr_level.toString();
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
                      await _carregarDados();
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
  void _showEditJourneyDialog(JourneyRidingModel item) {
    DateTime dataSelecionada =
        DateTime.tryParse(item.uj_promotion_date) ?? DateTime.now();

    final TextEditingController dateController = TextEditingController(
      text: generalService.formatarDataBr(dataSelecionada.toIso8601String()),
    );

    final String nomeNivel = item.jr_nome;
    final String lvlNum = item.jr_level.toString();

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
                      final String pjrId =
                          item.uj_id.toString();
                      await bdJourneyRidingController.deleteProfileJourneyRiding(
                        pjrId,
                        item.pfl_id,
                        item.hld_id,
                      );

                      if (mounted) {
                        Navigator.of(dialogContext).pop();
                        await _carregarDados();
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
                        final String pjrId =
                            item.uj_id.toString();
                        await bdJourneyRidingController.updateProfileJourneyRiding(
                          pjrId,
                          item.pfl_id,
                          item.hld_id,
                          item.jr_id,
                          dataSelecionada.toIso8601String(),
                        );

                        if (mounted) {
                          Navigator.of(dialogContext).pop();
                          await _carregarDados();
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

  // ==========================================
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: bdJourneyRidingController.loadingNotifier,
      builder: (context, _) {
        final bool isLoading = bdJourneyRidingController.loadingNotifier.value;

        return Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                ProfileJourneyRiding(
                  key: ValueKey(_refreshKey),
                  pflId: widget.itemAtual.pfl_id.toString(),
                  hldId: widget.itemAtual.hld_id.toString(),
                  onEdit: _showEditJourneyDialog,
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<List<JourneyRidingModel>>(
                  valueListenable: bdJourneyRidingController
                      .vProfileJourneyridingDetaisNotifier,
                  builder: (context, history, child) {
                    return ValueListenableBuilder<List<JourneyRidingModel>>(
                      valueListenable: bdJourneyRidingController
                          .journeyRidingOrderByLevelNotifier,
                      builder: (context, catalog, child) {
                        if (!_temProximoNivel()) {
                          return const SizedBox.shrink();
                        }

                        return Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: isLoading ? null : _showAddJourneyDialog,
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