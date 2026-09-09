import 'package:flutter/material.dart';
import 'package:originais/controllers/profile_controller.dart';
import 'package:originais/controllers/executive_committee_termofoffice_members_controller.dart';
import 'package:originais/models/executive_committee_termofoffice_members_model.dart';
import 'package:originais/services/general_service.dart';

class ProfileExecutiveCommittee extends StatefulWidget {
  final String? pflId;
  final String? hldId;
  final BdVExecutiveCommitteeTermOfOfficeMembersController? controller;
  final void Function(VExecutiveCommitteeTermOfOfficeMembersModel)? onEdit;

  const ProfileExecutiveCommittee({
    super.key,
    this.pflId,
    this.hldId,
    this.controller,
    this.onEdit,
  });

  @override
  State<ProfileExecutiveCommittee> createState() =>
      _ProfileExecutiveCommitteeState();
}

class _ProfileExecutiveCommitteeState
    extends State<ProfileExecutiveCommittee> {
  final GeneralService generalService = GeneralService();
  late final BdVExecutiveCommitteeTermOfOfficeMembersController controller;
  late final BdProfileController profileController;

  late String pflId = '';
  late String hldId = '';

  @override
  void initState() {
    super.initState();
    
    controller = widget.controller ??
        getItBdVExecutiveCommitteeTermOfOfficeMembersController
            .get<BdVExecutiveCommitteeTermOfOfficeMembersController>();
    
    profileController = getItBdProfileController<BdProfileController>();

    _atualizarECarregarCargos();
  }

  @override
  void didUpdateWidget(covariant ProfileExecutiveCommittee oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pflId != widget.pflId || oldWidget.hldId != widget.hldId) {
      _atualizarECarregarCargos();
    }
  }

  void _atualizarECarregarCargos() {
    final pessoaLogada = profileController.pessoaSelecionadaNotifier.value;

    pflId = widget.pflId ?? pessoaLogada?.pfl_id?.toString() ?? '';
    hldId = widget.hldId ?? pessoaLogada?.hld_id?.toString() ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarCargosExecutivos();
    });
  }

  Future<void> _carregarCargosExecutivos() async {
    if (pflId.isEmpty) return;
    await controller.loadExecutiveOrderByDateStart(pflId, hldId);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller.loadingNotifier,
      builder: (context, isLoading, child) {
        if (isLoading) {
          return const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return ValueListenableBuilder<
            List<VExecutiveCommitteeTermOfOfficeMembersModel>>(
          valueListenable: controller.executiveOrderByDateStart,
          builder: (context, listaCargos, child) {
            if (listaCargos.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    'Nenhum cargo executivo registrado para este perfil.',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 📊 Resumo do Usuário
                  _buildResumoCargos(listaCargos),

                  const SizedBox(height: 12),

                  // 📋 Lista de Cargos Executivos
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: listaCargos.length,
                    itemBuilder: (context, index) {
                      return _buildCargoCard(listaCargos[index]);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 📊 Card de Resumo de Cargos
  Widget _buildResumoCargos(
    List<VExecutiveCommitteeTermOfOfficeMembersModel> lista,
  ) {
    final int total = lista.length;

    final int ativos = lista.where((c) {
      final bool isAtivoFlag = c.ectm_date_end.isEmpty;
      final DateTime? endDate = DateTime.tryParse(c.ect_date_end ?? '');
      final bool dataValida = endDate == null || endDate.isAfter(DateTime.now());
      return isAtivoFlag && dataValida;
    }).length;

    final int encerrados = total - ativos;

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
            child: _buildResumoColumn('Total Mandatos', '$total', Colors.white70),
          ),
          Container(height: 24, width: 1, color: Colors.white24),
          Expanded(
            child: _buildResumoColumn('Mandato Ativo', '$ativos', Colors.greenAccent),
          ),
          Container(height: 24, width: 1, color: Colors.white24),
          Expanded(
            child: _buildResumoColumn('Anteriores', '$encerrados', Colors.white38),
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

  // 📋 Card Individual do Cargo/Mandato
  Widget _buildCargoCard(VExecutiveCommitteeTermOfOfficeMembersModel cargo) {
    bool isAtivo = false;

    final bool isAtivoFlag = cargo.ectm_date_end.isEmpty;
    if (!isAtivoFlag) {
      final DateTime? endDate = DateTime.tryParse(cargo.ect_date_end ?? '');
      isAtivo = isAtivoFlag && (endDate == null || endDate.isAfter(DateTime.now()));
    } else {
      isAtivo = isAtivoFlag;
    }

    final String cargoNome = cargo.ecm_name ?? cargo.ect_name ?? 'Cargo Executivo';
    final String inicioData = generalService.formatarDataBr(cargo.ect_date_start ?? '');
    final String fimData = cargo.ect_date_end != null && cargo.ectm_date_end.isNotEmpty
        ? generalService.formatarDataBr(cargo.ectm_date_end)
        : 'Atual';

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
          Icons.workspace_premium_outlined,
          color: isAtivo ? Colors.greenAccent : Colors.indigoAccent,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                cargoNome,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusBadge(isAtivo),
            if (widget.onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
                tooltip: 'Editar Mandato',
                onPressed: () => widget.onEdit!(cargo),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            'Gestão: $inicioData - $fimData',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ),
        children: [
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.all(12.0),
            color: Colors.black12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  'Comitê/Gestão:',
                  cargo.ecm_name ?? cargo.ect_name ?? 'Diretoria Executiva',
                ),
                const SizedBox(height: 6),
                _buildInfoRow('Data de Início:', inicioData),
                const SizedBox(height: 6),
                _buildInfoRow('Término Previsto:', fimData),
                if (cargo.ectm_motivo_saida != null && cargo.ectm_motivo_saida!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildInfoRow('Observações:', cargo.ectm_motivo_saida!),
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
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white54),
        ),
        Flexible(
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
    final String label = isAtivo ? 'EM EXERCÍCIO' : 'ENCERRADO';
    final Color color = isAtivo ? Colors.greenAccent : Colors.white38;
    final Color bgColor = isAtivo
        ? Colors.green.withValues(alpha: 0.15)
        : Colors.grey.withValues(alpha: 0.15);

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