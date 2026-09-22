import 'package:flutter/material.dart';
import 'package:originais/controllers/profile_controller.dart';
import 'package:originais/controllers/profile_associate_status_controller.dart';
import 'package:originais/models/profile_associate_status_model.dart';
import 'package:originais/services/general_service.dart';
import 'package:originais/view/default_loading.dart';
import 'package:originais/view/default_snackbar.dart'; 

class ProfileAssociateStatus extends StatefulWidget {
  final String? pflId;
  final String? hldId;
  final BdVProfileAssociateStatusController? controller;
  final void Function(VProfileAssociateStatusModel)? onEdit;

  const ProfileAssociateStatus({
    super.key,
    this.pflId,
    this.hldId,
    this.controller,
    this.onEdit,
  });

  @override
  State<ProfileAssociateStatus> createState() => _ProfileAssociateStatusState();
}

class _ProfileAssociateStatusState extends State<ProfileAssociateStatus> {
  late final GeneralService generalService;
  late final BdVProfileAssociateStatusController controller;
  late final BdProfileController profileController;
  bool _isLocalController = false;

  String _pflIdResolvido = '';
  String _hldIdResolvido = '';

  bool isRealTime = false;

  @override
  void initState() {
    super.initState();
    generalService = GeneralService();

    // Se um controller foi passado pelo widget pai, reutiliza a instância escopada.
    // Caso contrário, solicita uma nova instância isolada via Factory do GetIt.
    if (widget.controller != null) {
      controller = widget.controller!;
      _isLocalController = false;
    } else {
      controller = getItBdVProfileAssociateStatusController
          .get<BdVProfileAssociateStatusController>();
      _isLocalController = true;
    }

    profileController = getItBdProfileController<BdProfileController>();
    profileController.pessoaSelecionadaNotifier.addListener(_onPerfilAtualizado);
    
    DefaultSnackbar.attachErrorListener(
      context,
      controller.errorNotifier
    );
    
    DefaultSnackbar.attachSuccessListener(
      context,
      controller.successNotifier
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarStatusAssociado();
    });
  }

  @override
  void dispose() {
    profileController.pessoaSelecionadaNotifier.removeListener(_onPerfilAtualizado);
    // Descarta o controller apenas se ele foi criado localmente via Factory
    if (_isLocalController) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onPerfilAtualizado() {
    if (widget.pflId == null || widget.pflId!.isEmpty) {
      _carregarStatusAssociado();
    }
  }

  @override
  void didUpdateWidget(covariant ProfileAssociateStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pflId != widget.pflId || oldWidget.hldId != widget.hldId) {
      _carregarStatusAssociado();
    }
  }

  Future<void> _carregarStatusAssociado() async {
    final pessoaLogada = profileController.pessoaSelecionadaNotifier.value;

    _pflIdResolvido = (widget.pflId != null && widget.pflId!.isNotEmpty)
        ? widget.pflId!
        : (pessoaLogada?.pfl_id.toString() ?? '');

    _hldIdResolvido = (widget.hldId != null && widget.hldId!.isNotEmpty)
        ? widget.hldId!
        : (pessoaLogada?.hld_id.toString() ?? '');

    if (_pflIdResolvido.isEmpty) return;

    await controller.loadProfileAssociateStatus(_pflIdResolvido, _hldIdResolvido);
    if ( isRealTime == false ){
      controller.subscribeToRealtime(_pflIdResolvido, _hldIdResolvido);
      isRealTime = true;
    }

  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller.loadingNotifier,
      builder: (context, isLoading, child) {
        if (isLoading) {
          return DefaultLoading.showProgressIndicator();
          // return const Padding(
          //   padding: EdgeInsets.all(32.0),
          //   child: Center(child: CircularProgressIndicator()),
          // );
        }

        return ValueListenableBuilder<String?>(
          valueListenable: controller.errorNotifier,
          builder: (context, errorMessage, child) {
            if (errorMessage != null && errorMessage.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.redAccent,
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _carregarStatusAssociado,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ValueListenableBuilder<List<VProfileAssociateStatusModel>>(
              valueListenable: controller.vProfileAssociateStatusNotifier,
              builder: (context, listaStatus, child) {
                if (listaStatus.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'Nenhum histórico de status de associado registrado.',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildResumoStatus(listaStatus),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: listaStatus.length,
                        itemBuilder: (context, index) {
                          return _buildStatusCard(listaStatus[index]);
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildResumoStatus(List<VProfileAssociateStatusModel> lista) {
    final int total = lista.length;
    final int ativos = lista.where((s) {
      final bool isAtivoFlag = s.pas_date.isNotEmpty;
      final DateTime? endDate = DateTime.tryParse(s.pas_date);
      return isAtivoFlag &&
          (endDate == null || endDate.isAfter(DateTime.now()));
    }).length;

    final VProfileAssociateStatusModel? statusAtualModel =
        lista.isNotEmpty ? lista.first : null;
    final String statusAtualNome = statusAtualModel?.as_desc ?? 'N/A';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.indigo.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _buildResumoColumn('Total Registros', '$total', Colors.white70),
          ),
          Container(height: 24, width: 1, color: Colors.white24),
          Expanded(
            child: _buildResumoColumn('Status Atual', statusAtualNome, Colors.greenAccent),
          ),
          Container(height: 24, width: 1, color: Colors.white24),
          Expanded(
            child: _buildResumoColumn('Vigentes', '$ativos', Colors.indigoAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: Colors.white54),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(VProfileAssociateStatusModel status) {
    final bool isAtivoFlag = status.pas_date.isNotEmpty;
    final DateTime? endDate = DateTime.tryParse(status.pas_date);
    final bool isAtivo =
        isAtivoFlag && (endDate == null || endDate.isAfter(DateTime.now()));

    final String statusNome = status.as_desc;
    final String inicioData = generalService.formatarDataBr(status.pas_date);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.indigo.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
          Icons.badge_outlined,
          color: isAtivo ? Colors.greenAccent : Colors.indigoAccent,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                statusNome,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusBadge(isAtivo),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            'Data: $inicioData',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ),
        trailing: widget.onEdit != null
            ? IconButton(
                icon: const Icon(Icons.edit, size: 20, color: Colors.orange),
                onPressed: () => widget.onEdit!(status),
              )
            : null,
        children: [
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.all(12.0),
            color: Colors.black12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Status do Associado:', statusNome),
                const SizedBox(height: 6),
                _buildInfoRow('Data do Registro:', inicioData),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white54),
        ),
        Expanded(
          child: Text(
            valor,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool isAtivo) {
    final String label = isAtivo ? 'ATIVO' : 'HISTÓRICO';
    final Color color = isAtivo ? Colors.greenAccent : Colors.white38;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isAtivo
            ? Colors.green.withValues(alpha: 0.15)
            : Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}