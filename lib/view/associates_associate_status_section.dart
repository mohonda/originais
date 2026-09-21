import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:originais/controllers/profile_controller.dart';
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
  late final BdProfileController profileController;
  final GeneralService generalService = GeneralService();
  bool isRealTime = false;


  @override
  void initState() {
    super.initState();
    controller = getItBdVProfileAssociateStatusController
        .get<BdVProfileAssociateStatusController>();
    
    profileController = getItBdProfileController<BdProfileController>();

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
          duration: Duration(seconds: 2),
        ),
      );
    }
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

  @override
  void dispose() {
    controller.errorNotifier.removeListener(_handleError);
    
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
      controller.loadProfileAssociateStatus(pflId, hldId);
      controller.loadAssociateStatus(hldId);
      if ( isRealTime == false ){
        controller.subscribeToRealtime(pflId, hldId);
        isRealTime = true;
      }
    }
  }

  void _showAddStatusDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return ValueListenableBuilder<List<dynamic>>(
          valueListenable: controller.statusNotifier,
          builder: (context, listOpcoesStatus, _) {
            if (listOpcoesStatus.isEmpty) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Status indisponíveis', style: TextStyle(fontSize: 17)),
                  ],
                ),
                content: const Text(
                  'Nenhum tipo de status foi encontrado ou o carregamento ainda está em andamento.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Fechar'),
                  ),
                ],
              );
            }

            return _AddStatusDialogForm(
              listOpcoesStatus: listOpcoesStatus,
              generalService: generalService,
              onSave: (statusSelecionado, dataRegistro, percentualText) async {
                await controller.insertProfileAssociateStatus(
                  widget.itemAtual.pfl_id.toString(),
                  widget.itemAtual.hld_id.toString(),
                  statusSelecionado.asId.toString(),
                  dataRegistro.toIso8601String(),
                  percentualText,
                );

                if (mounted) {
                  Navigator.of(dialogContext).pop();
                  _carregarDados();
                }
              },
            );
          },
        );
      },
    );
  }

  void _showEditStatusDialog(VProfileAssociateStatusModel item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _EditStatusDialogForm(
          item: item,
          generalService: generalService,
          onSave: (dataRegistro, percentualText, isMonthly) async {
            await controller.updateProfileAssociateStatus(
              item.pas_id,
              item.pas_pfl_id,
              item.pas_hld_id,
              dataRegistro.toIso8601String(),
              isMonthly ? percentualText : null,
            );

            if (mounted) {
              Navigator.of(dialogContext).pop();
              _carregarDados();
            }
          },
          onDelete: () async {
            final bool? confirmar = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Confirmar Exclusão'),
                content: Text('Deseja remover o status "${item.as_desc}"?'),
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
                item.pas_hld_id,
              );

              if (mounted) {
                Navigator.of(dialogContext).pop();
                _carregarDados();
              }
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        controller.loadingNotifier,
        // statusController.loadingNotifier,
      ]),
      builder: (context, _) {
        final bool isLoading = controller.loadingNotifier.value;

        return Stack(
          children: [
            Column(
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
                    onPressed: isLoading ? null : _showAddStatusDialog,
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

class _AddStatusDialogForm extends StatefulWidget {
  final List<dynamic> listOpcoesStatus;
  final GeneralService generalService;
  final Function(dynamic statusSelecionado, DateTime dataRegistro, String? percentualText) onSave;

  const _AddStatusDialogForm({
    required this.listOpcoesStatus,
    required this.generalService,
    required this.onSave,
  });

  @override
  State<_AddStatusDialogForm> createState() => _AddStatusDialogFormState();
}

class _AddStatusDialogFormState extends State<_AddStatusDialogForm> {
  final _formKey = GlobalKey<FormState>();
  late dynamic _statusSelecionado;
  late DateTime _dataRegistro;
  late final TextEditingController _dateController;
  late final TextEditingController _percentController;

  @override
  void initState() {
    super.initState();
    _statusSelecionado = widget.listOpcoesStatus.first;
    _dataRegistro = DateTime.now();
    _dateController = TextEditingController(
      text: widget.generalService.formatarDataBr(_dataRegistro.toIso8601String()),
    );
    _percentController = TextEditingController(text: '100');
  }

  @override
  void dispose() {
    _dateController.dispose();
    _percentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMonthly = _statusSelecionado != null
        ? (_statusSelecionado.asIsMonthlyPayment ?? _statusSelecionado.as_ismonthlypayment ?? false)
        : false;

    final int? maxInDays = _statusSelecionado != null
        ? (_statusSelecionado.asMaxIndays ?? _statusSelecionado.as_max_indays)
        : null;

    final int renovacao = _statusSelecionado != null
        ? (_statusSelecionado.asRenovacao ?? _statusSelecionado.as_renovacao ?? 0)
        : 0;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.add_circle, color: Colors.indigo),
          SizedBox(width: 8),
          Text('Adicionar Status do Associado', style: TextStyle(fontSize: 17)),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<dynamic>(
                initialValue: _statusSelecionado,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Novo Status *',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
                items: widget.listOpcoesStatus.map((st) {
                  return DropdownMenuItem<dynamic>(
                    value: st,
                    child: Text(
                      st.asDesc ?? st.as_desc ?? 'Sem Descrição',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                validator: (value) => value == null ? 'Selecione o status' : null,
                onChanged: (novoStatus) {
                  setState(() {
                    _statusSelecionado = novoStatus;
                    final bool newIsMonthly = novoStatus != null
                        ? (novoStatus.asIsMonthlyPayment ?? novoStatus.as_ismonthlypayment ?? false)
                        : false;
                    
                    if (!newIsMonthly) {
                      _percentController.clear();
                    } else {
                      _percentController.text = '100';
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: ValueKey('isMonthly_${_statusSelecionado.hashCode}'),
                initialValue: isMonthly ? 'Sim' : 'Não',
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Gera Mensalidade',
                  prefixIcon: Icon(Icons.payments_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: ValueKey('maxIndays_${_statusSelecionado.hashCode}'),
                initialValue: maxInDays != null ? '$maxInDays dias' : 'Não informado',
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Prazo Máximo (Dias)',
                  prefixIcon: Icon(Icons.timer_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: ValueKey('renovacao_${_statusSelecionado.hashCode}'),
                initialValue: '$renovacao renovação',
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Renovação',
                  prefixIcon: Icon(Icons.autorenew),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Data do Status *',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Informe a data do status' : null,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dataRegistro,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2050),
                  );
                  if (picked != null) {
                    setState(() {
                      _dataRegistro = picked;
                      _dateController.text = widget.generalService.formatarDataBr(picked.toIso8601String());
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _percentController,
                enabled: isMonthly,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: isMonthly ? 'Porcentagem da Mensalidade (%) *' : 'Porcentagem da Mensalidade (N/A)',
                  prefixIcon: const Icon(Icons.percent),
                  suffixText: '%',
                  border: const OutlineInputBorder(),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+[\,\.]?\d{0,2}')),
                ],
                validator: (value) {
                  if (!isMonthly) return null;
                  if (value == null || value.trim().isEmpty) return 'Informe a porcentagem';
                  final parsed = double.tryParse(value.replaceAll(',', '.'));
                  if (parsed == null) return 'Digite uma porcentagem válida';
                  if (parsed < 0 || parsed > 100) return 'A porcentagem deve estar entre 0 e 100';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Confirmar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            widget.onSave(
              _statusSelecionado,
              _dataRegistro,
              isMonthly ? _percentController.text.trim() : null,
            );
          },
        ),
      ],
    );
  }
}

class _EditStatusDialogForm extends StatefulWidget {
  final VProfileAssociateStatusModel item;
  final GeneralService generalService;
  final Function(DateTime dataRegistro, String percentualText, bool isMonthly) onSave;
  final VoidCallback onDelete;

  const _EditStatusDialogForm({
    required this.item,
    required this.generalService,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<_EditStatusDialogForm> createState() => _EditStatusDialogFormState();
}

class _EditStatusDialogFormState extends State<_EditStatusDialogForm> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _dataRegistro;
  late final TextEditingController _dateController;
  late final TextEditingController _percentController;

  @override
  void initState() {
    super.initState();
    _dataRegistro = DateTime.tryParse(widget.item.pas_date) ?? DateTime.now();
    _dateController = TextEditingController(
      text: widget.generalService.formatarDataBr(_dataRegistro.toIso8601String()),
    );
    _percentController = TextEditingController(
      text: widget.item.pas_monthly_percent.toString(),
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _percentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMonthly = widget.item.as_ismonthlypayment;
    final String statusNome = widget.item.as_desc;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.edit, color: Colors.orange),
          SizedBox(width: 8),
          Text('Editar Status do Associado', style: TextStyle(fontSize: 17)),
        ],
      ),
      content: Form(
        key: _formKey,
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
                controller: _dateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Data do Status *',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Informe a data do status' : null,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dataRegistro,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      _dataRegistro = picked;
                      _dateController.text = widget.generalService.formatarDataBr(picked.toIso8601String());
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _percentController,
                enabled: isMonthly,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: isMonthly ? 'Porcentagem da Mensalidade (%) *' : 'Porcentagem da Mensalidade (N/A)',
                  prefixIcon: const Icon(Icons.percent),
                  suffixText: '%',
                  border: const OutlineInputBorder(),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+[\,\.]?\d{0,2}')),
                ],
                validator: (value) {
                  if (!isMonthly) return null;
                  if (value == null || value.trim().isEmpty) return 'Informe a porcentagem';
                  final parsed = double.tryParse(value.replaceAll(',', '.'));
                  if (parsed == null) return 'Digite uma porcentagem válida';
                  if (parsed < 0 || parsed > 100) return 'A porcentagem deve estar entre 0 e 100';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
          label: const Text('Excluir', style: TextStyle(color: Colors.red)),
          onPressed: widget.onDelete,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
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
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                widget.onSave(_dataRegistro, _percentController.text.trim(), isMonthly);
              },
            ),
          ],
        ),
      ],
    );
  }
}