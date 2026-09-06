import 'package:flutter/material.dart';
import 'package:originais/controllers/bd_journeyriding_controller.dart';
import 'package:originais/controllers/bd_profile_controller.dart';
import 'package:originais/models/journeyriding_model.dart';
import 'package:originais/services/general_service.dart';

class ProfileJourneyRiding extends StatefulWidget {
  const ProfileJourneyRiding({super.key});

  @override
  State<ProfileJourneyRiding> createState() => _ProfileJourneyRidingState();
}

class _ProfileJourneyRidingState extends State<ProfileJourneyRiding> {
  final GeneralService generalService = GeneralService();
  late final BdJourneyRidingController controller;
  late final BdProfileController profileController;

  late String pflId = '';
  late String hldId = '';

  @override
  void initState() {
    super.initState();
    controller =
        getItBdJourneyRidingController.get<BdJourneyRidingController>();
    profileController = getItBdProfileController<BdProfileController>();

    pflId = profileController.pessoaSelecionadaNotifier.value?.pfl_id ?? '';
    hldId = profileController.pessoaSelecionadaNotifier.value?.hld_id ?? '';

    _carregarJornada();
  }

  Future<void> _carregarJornada() async {
    await controller.loadJourneyRidingDetais(pflId, hldId);
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

        return ValueListenableBuilder<List<JourneyRidingModel>>(
          valueListenable: controller.vProfileJourneyridingDetaisNotifier,
          builder: (context, listaJornada, child) {
            if (listaJornada.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    'Nenhuma graduação ou etapa registrada para este perfil.',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),
              );
            }

            // Ordena os registros pela data de promoção (Mais recente primeiro)
            final listaOrdenada = List<JourneyRidingModel>.from(listaJornada)
              ..sort((a, b) {
                // final dateA = DateTime.tryParse(a.uj_promotion_date ?? '') ?? DateTime(1970);
                // final dateB = DateTime.tryParse(b.uj_promotion_date ?? '') ?? DateTime(1970);
                final levelA = a.jr_level;
                final levelB = b.jr_level;
                return levelB.compareTo(levelA);
              });

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 📊 Resumo do Usuário
                  _buildResumoJornada(listaOrdenada),

                  const SizedBox(height: 12),

                  // 📋 Lista de Etapas da Jornada
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: listaOrdenada.length,
                    itemBuilder: (context, index) {
                      final bool isAtual = index == 0; // A mais recente é a graduação atual
                      return _buildJornadaCard(listaOrdenada[index], isAtual);
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

  // 📊 Card de Resumo da Jornada
  Widget _buildResumoJornada(List<JourneyRidingModel> lista) {
    final int totalEtapas = lista.length;
    final JourneyRidingModel? graduacaoAtual = lista.isNotEmpty ? lista.first : null;

    final String nomeGraduacaoAtual = graduacaoAtual?.jr_nome ??
        graduacaoAtual?.jr_nome ??
        graduacaoAtual?.jr_level ??
        'N/A';

    final String dataUltimaPromocao = graduacaoAtual?.uj_promotion_date != null
        ? generalService.formatarDataBr(graduacaoAtual!.uj_promotion_date!)
        : 'N/A';

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
          _buildResumoColumn('Total Etapas', '$totalEtapas', Colors.white70),
          Container(height: 24, width: 1, color: Colors.white24),
          _buildResumoColumn('Graduação Atual', nomeGraduacaoAtual, Colors.greenAccent),
          Container(height: 24, width: 1, color: Colors.white24),
          _buildResumoColumn('Última Promoção', dataUltimaPromocao, Colors.indigoAccent),
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

  // 📋 Card Individual da Promoção / Graduação
  Widget _buildJornadaCard(JourneyRidingModel etapa, bool isAtual) {
    final String tituloEtapa = etapa.jr_nome ?? etapa.jr_nome ?? 'Graduação / Etapa';
    final String dataPromocao = generalService.formatarDataBr(etapa.uj_promotion_date ?? '');

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
          Icons.military_tech_outlined,
          color: isAtual ? Colors.amberAccent : Colors.indigoAccent,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                tituloEtapa,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusBadge(isAtual),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            'Promovido em: $dataPromocao',
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
                _buildInfoRow('Etapa / Graduação:', tituloEtapa),
                const SizedBox(height: 6),
                _buildInfoRow('Data da Promoção:', dataPromocao),
                if (etapa.jr_desc != null && etapa.jr_desc!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildInfoRow('Observações:', etapa.jr_desc!),
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
  Widget _buildStatusBadge(bool isAtual) {
    final String label = isAtual ? 'ATUAL' : 'CONCLUÍDA';
    final Color color = isAtual ? Colors.greenAccent : Colors.white38;
    final Color bgColor = isAtual
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