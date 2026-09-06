import 'package:flutter/material.dart';
import 'package:originais/controllers/bd_profile_controller.dart';
import 'package:originais/controllers/bd_vprofile_associatestatus_controller.dart';
import 'package:originais/models/vprofile_associatestatus_model.dart';
import 'package:originais/services/general_service.dart';

class ProfileAssociateStatus extends StatefulWidget {
  const ProfileAssociateStatus({super.key});

  @override
  State<ProfileAssociateStatus> createState() => _ProfileAssociateStatusState();
}

class _ProfileAssociateStatusState extends State<ProfileAssociateStatus> {
  final GeneralService generalService = GeneralService();
  late final BdVProfileAssociateStatusController controller;
  late final BdProfileController profileController;

  late String pflId = '';
  late String hldId = '';

  @override
  void initState() {
    super.initState();
    controller =
        getItBdVProfileAssociateStatusController
            .get<BdVProfileAssociateStatusController>();
    profileController = getItBdProfileController<BdProfileController>();

    pflId = profileController.pessoaSelecionadaNotifier.value?.pfl_id ?? '';
    hldId = profileController.pessoaSelecionadaNotifier.value?.hld_id ?? '';

    _carregarStatusAssociado();
  }

  Future<void> _carregarStatusAssociado() async {
    await controller.loadProfileAssociateStatus(pflId, hldId);
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

        return ValueListenableBuilder<List<VProfileAssociateStatusModel>>(
          valueListenable: controller.vProfileAssociateStatusNotifier,
          builder: (context, listaStatus, child) {
            if (listaStatus.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    'Nenhum histórico de status de associado registrado para este perfil.',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),
              );
            }

            // Ordena os registros por data de início (Mais recente primeiro)
            final listaOrdenada =
                List<VProfileAssociateStatusModel>.from(listaStatus)
                  ..sort((a, b) {
                    final dateA =
                        DateTime.tryParse(a.pas_date ?? '') ??
                        DateTime(1970);
                    final dateB =
                        DateTime.tryParse(b.pas_date ?? '') ??
                        DateTime(1970);
                    return dateB.compareTo(dateA);
                  });

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 📊 Resumo do Status do Associado
                  _buildResumoStatus(listaOrdenada),

                  const SizedBox(height: 12),

                  // 📋 Lista de Histórico de Status
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: listaOrdenada.length,
                    itemBuilder: (context, index) {
                      return _buildStatusCard(listaOrdenada[index]);
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

  // 📊 Card de Resumo de Status
  Widget _buildResumoStatus(List<VProfileAssociateStatusModel> lista) {
    final int total = lista.length;

    final int ativos = lista.where((s) {
      final bool isAtivoFlag = s.pas_date.isNotEmpty;
      final DateTime? endDate = DateTime.tryParse(s.pas_date ?? '');
      final bool dataValida = endDate == null || endDate.isAfter(DateTime.now());
      return isAtivoFlag && dataValida;
    }).length;

    final VProfileAssociateStatusModel? statusAtualModel =
        lista.isNotEmpty ? lista.first : null;

    final String statusAtualNome = statusAtualModel?.as_desc ??
        statusAtualModel?.as_desc ??
        'N/A';

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
          _buildResumoColumn('Status Atual', statusAtualNome, Colors.greenAccent),
          Container(height: 24, width: 1, color: Colors.white24),
          _buildResumoColumn('Vigentes', '$ativos', Colors.indigoAccent),
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

  // 📋 Card Individual do Status do Associado
  Widget _buildStatusCard(VProfileAssociateStatusModel status) {
    final bool isAtivoFlag = status.pas_date.isNotEmpty ?? false;
    final DateTime? endDate = DateTime.tryParse(status.pas_date ?? '');
    final bool isAtivo = isAtivoFlag && (endDate == null || endDate.isAfter(DateTime.now()));

    final String statusNome =
        status.as_desc ?? status.as_desc ?? 'Status de Associado';
    final String inicioData =
        generalService.formatarDataBr(status.pas_date ?? '');
    final String fimData =
        status.pas_date != null && status.pas_date!.isNotEmpty
            ? generalService.formatarDataBr(status.pas_date!)
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
            'Vigência: $inicioData - $fimData',
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
                _buildInfoRow('Status do Associado:', statusNome),
                const SizedBox(height: 6),
                _buildInfoRow('Data Inicial:', inicioData),
                const SizedBox(height: 6),
                _buildInfoRow('Data Final / Previsão:', fimData),
                if (status.as_desc != null && status.as_desc!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildInfoRow('Motivo:', status.as_desc!),
                ],
                if (status.as_desc != null && status.as_desc!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildInfoRow('Observações:', status.as_desc!),
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

  // 🏷️ Badge de Status
  Widget _buildStatusBadge(bool isAtivo) {
    final String label = isAtivo ? 'ATIVO' : 'HISTÓRICO';
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