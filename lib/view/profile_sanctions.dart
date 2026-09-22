import 'package:flutter/material.dart';
import 'package:originais/controllers/profile_controller.dart';
import 'package:originais/controllers/profiles_sanctions_controller.dart';
import 'package:originais/models/profiles_sanctions_model.dart';
import 'package:originais/services/general_service.dart';
import 'package:originais/view/default_loading.dart';
import 'package:originais/view/default_snackbar.dart'; 

class ProfileSanctions extends StatefulWidget {
  final String? pflId;
  final String? hldId;
  final BdVProfilesSanctionsController? controller;
  final void Function(VProfilesSanctionsModel)? onEdit;

  const ProfileSanctions({
    super.key,
    this.pflId,
    this.hldId,
    this.controller,
    this.onEdit,
  });

  @override
  State<ProfileSanctions> createState() => _ProfileSanctionsState();
}

class _ProfileSanctionsState extends State<ProfileSanctions> {
  late final GeneralService generalService;
  late final BdVProfilesSanctionsController controller;
  late final BdProfileController profileController;
  bool _isLocalController = false;

  String _pflIdResolvido = '';
  String _hldIdResolvido = '';

  bool isRealTime = false;

  @override
  void initState() {
    super.initState();
    generalService = GeneralService();

    // Se um controller foi passado pelo pai, utiliza ele.
    // Caso contrário, solicita uma nova instância ao Factory do GetIt.
    if (widget.controller != null) {
      controller = widget.controller!;
      _isLocalController = false;
    } else {
      controller = getItBdVProfilesSanctionsController
          .get<BdVProfilesSanctionsController>();
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
      _carregarSancoes();
    });
  }

  @override
  void dispose() {
    profileController.pessoaSelecionadaNotifier.removeListener(_onPerfilAtualizado);
    // Se o controller foi criado localmente via Factory, limpa a memória ao destruir o widget
    if (_isLocalController) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onPerfilAtualizado() {
    if (widget.pflId == null || widget.pflId!.isEmpty) {
      _carregarSancoes();
    }
  }

  @override
  void didUpdateWidget(covariant ProfileSanctions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pflId != widget.pflId || oldWidget.hldId != widget.hldId) {
      _carregarSancoes();
    }
  }

  Future<void> _carregarSancoes() async {
    final pessoaLogada = profileController.pessoaSelecionadaNotifier.value;

    _pflIdResolvido = (widget.pflId != null && widget.pflId!.isNotEmpty)
        ? widget.pflId!
        : (pessoaLogada?.pfl_id.toString() ?? '');

    _hldIdResolvido = (widget.hldId != null && widget.hldId!.isNotEmpty)
        ? widget.hldId!
        : (pessoaLogada?.hld_id.toString() ?? '');

    if (_pflIdResolvido.isEmpty || _hldIdResolvido.isEmpty) {
      controller.vProfilesSanctionsNotifier.value = [];
      return;
    }

    await controller.loadProfileSanctionsStatus(_pflIdResolvido, _hldIdResolvido);

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
                        onPressed: _carregarSancoes,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ValueListenableBuilder<List<VProfilesSanctionsModel>>(
              valueListenable: controller.vProfilesSanctionsNotifier,
              builder: (context, listaSancoes, child) {
                if (listaSancoes.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'Nenhuma sanção disciplinar registrada.',
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
                      _buildResumoSancoes(listaSancoes),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: listaSancoes.length,
                        itemBuilder: (context, index) {
                          return _buildSancaoCard(listaSancoes[index]);
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

  Widget _buildResumoSancoes(List<VProfilesSanctionsModel> lista) {
    final int total = lista.length;

    final int ativas = lista.where((s) {
      final String dateEndStr = s.psan_date_end;
      if (dateEndStr.isEmpty) return true;
      final DateTime? endDate = DateTime.tryParse(dateEndStr);
      return endDate == null || endDate.isAfter(DateTime.now());
    }).length;

    final int cumpridas = total - ativas;

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
          _buildResumoColumn('Total Registros', '$total', Colors.white70),
          Container(height: 24, width: 1, color: Colors.white24),
          _buildResumoColumn('Em Cumprimento', '$ativas', Colors.redAccent),
          Container(height: 24, width: 1, color: Colors.white24),
          _buildResumoColumn(
            'Cumpridas/Encerradas',
            '$cumpridas',
            Colors.greenAccent,
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
          style: const TextStyle(fontSize: 11, color: Colors.white54),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSancaoCard(VProfilesSanctionsModel sancao) {
    final String dateEndStr = sancao.psan_date_end;
    final DateTime? endDate = DateTime.tryParse(dateEndStr);
    final bool isAtiva =
        dateEndStr.isEmpty ||
        (endDate != null && endDate.isAfter(DateTime.now()));

    final String sancaoNome = sancao.san_name;
    final String inicioData = generalService.formatarDataBr(
      sancao.psan_date_start,
    );
    final String fimData = dateEndStr.isNotEmpty
        ? generalService.formatarDataBr(dateEndStr)
        : 'Em aberto';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.indigo.withValues(alpha: 0.3), width: 1),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
          Icons.gavel_outlined,
          color: isAtiva ? Colors.redAccent : Colors.brown,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                sancaoNome,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isAtiva ? Colors.redAccent : Colors.brown,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusBadge(isAtiva),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            'Período: $inicioData a $fimData',
            style: TextStyle(
              fontSize: 12,
              color: isAtiva ? Colors.redAccent : Colors.brown,
              ),
          ),
        ),
        trailing: widget.onEdit != null
            ? IconButton(
                icon: const Icon(Icons.edit, size: 20, color: Colors.orange),
                onPressed: () => widget.onEdit!(sancao),
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
                _buildInfoRow('Tipo de Sanção:', sancaoNome),
                const SizedBox(height: 6),
                _buildInfoRow('Início da Sanção:', inicioData),
                const SizedBox(height: 6),
                _buildInfoRow('Término Previsto/Real:', fimData),
                if (sancao.psan_desc.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildInfoRow('Observações / Motivo:', sancao.psan_desc),
                ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white54),
        ),
        const SizedBox(width: 12),
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

  Widget _buildStatusBadge(bool isAtiva) {
    final String label = isAtiva ? 'ATIVA' : 'CUMPRIDA';
    final Color color = isAtiva ? Colors.redAccent : Colors.brown; 
    final Color bgColor = isAtiva
        ? Colors.red.withValues(alpha: 0.15)
        : Colors.brown.withValues(alpha: 0.15);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
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