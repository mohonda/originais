import 'package:flutter/material.dart';
import 'package:originais/controllers/bd_journeyriding_controller.dart';
import 'package:originais/controllers/bd_profile_controller.dart';
import 'package:originais/models/journeyriding_model.dart';
import 'package:originais/services/general_service.dart';

class ProfileJourneyRiding extends StatefulWidget {
  final String? pflId;
  final String? hldId;
  final void Function(JourneyRidingModel)? onEdit;

  const ProfileJourneyRiding({
    super.key,
    required this.pflId,
    required this.hldId,
    this.onEdit,
  });

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

    final pessoaLogada = profileController.pessoaSelecionadaNotifier.value;
    
    pflId = widget.pflId ?? pessoaLogada?.pfl_id?.toString() ?? '';
    hldId = widget.hldId ?? pessoaLogada?.hld_id?.toString() ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarJornada();
    });
  }

  Future<void> _carregarJornada() async {
    if (pflId.isEmpty) return;

    await Future.wait([
      controller.loadJourneyRidingDetais(pflId, hldId),
      controller.loadJourneyRiding(hldId),
    ]);
  }

  int _parseLevel(dynamic levelValue) {
    if (levelValue == null) return 0;
    final str = levelValue.toString().trim();
    if (str.isEmpty) return 0;

    final directInt = int.tryParse(str);
    if (directInt != null) return directInt;

    final directDouble = double.tryParse(str);
    if (directDouble != null) return directDouble.toInt();

    final onlyDigits = str.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(onlyDigits) ?? 0;
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
          builder: (context, listaJornadaPerfil, child) {
            return ValueListenableBuilder<List<JourneyRidingModel>>(
              valueListenable: controller.bdJourneyRidingNotifier,
              builder: (context, todasEtapas, child) {
                if (listaJornadaPerfil.isEmpty) {
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

                // 1. Identifica a graduação ATUAL pela data mais recente
                final historicoPorData = List<JourneyRidingModel>.from(listaJornadaPerfil)
                  ..sort((a, b) {
                    final dateA = DateTime.tryParse(a.uj_promotion_date ?? '') ?? DateTime(1900);
                    final dateB = DateTime.tryParse(b.uj_promotion_date ?? '') ?? DateTime(1900);
                    final dateComp = dateB.compareTo(dateA);
                    if (dateComp != 0) return dateComp;
                    return _parseLevel(b.jr_level).compareTo(_parseLevel(a.jr_level));
                  });

                final graduacaoAtual = historicoPorData.first;
                final int currentLevel = _parseLevel(graduacaoAtual.jr_level);

                // 2. Ordena histórico do perfil por Nível (Decrescente)
                final historicoOrdenado = List<JourneyRidingModel>.from(listaJornadaPerfil)
                  ..sort((a, b) => _parseLevel(b.jr_level).compareTo(_parseLevel(a.jr_level)));

                // 3. Ordena o catálogo global por Nível (Crescente)
                final catalogoOrdenado = List<JourneyRidingModel>.from(todasEtapas)
                  ..sort((a, b) => _parseLevel(a.jr_level).compareTo(_parseLevel(b.jr_level)));

                // 4. Busca o IMEDIATO PRÓXIMO NÍVEL
                JourneyRidingModel? proximoNivel;
                for (var etapa in catalogoOrdenado) {
                  final lvl = _parseLevel(etapa.jr_level);
                  if (lvl > currentLevel) {
                    proximoNivel = etapa;
                    break;
                  }
                }

                // SingleChildScrollView adicionado para evitar overflow com muitas promoções
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 📊 Resumo do Usuário
                      _buildResumoJornada(
                        lista: historicoOrdenado,
                        proximoNivel: proximoNivel,
                        catalogoCarregado: todasEtapas.isNotEmpty,
                        isLoading: isLoading,
                      ),

                      const SizedBox(height: 12),

                      // 🎯 Card de Destaque: Próximo Level
                      if (proximoNivel != null) ...[
                        _buildProximoNivelCard(
                          proximo: proximoNivel,
                          graduacaoAtual: graduacaoAtual,
                        ),
                        const SizedBox(height: 16),
                      ],

                      const Text(
                        'Histórico de Graduações',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 📋 Lista de Etapas Concluídas
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: historicoOrdenado.length,
                        itemBuilder: (context, index) {
                          final bool isAtual = historicoOrdenado[index].jr_id == graduacaoAtual.jr_id;
                          return _buildJornadaCard(
                            historicoOrdenado[index],
                            isAtual,
                          );
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

  // 📊 Card de Resumo da Jornada
  Widget _buildResumoJornada({
    required List<JourneyRidingModel> lista,
    required JourneyRidingModel? proximoNivel,
    required bool catalogoCarregado,
    required bool isLoading,
  }) {
    final int totalEtapas = lista.length;
    final JourneyRidingModel? graduacaoAtual =
        lista.isNotEmpty ? lista.first : null;

    final String nomeGraduacaoAtual =
        graduacaoAtual?.jr_nome ??
        (graduacaoAtual?.jr_level != null ? 'Lvl ${graduacaoAtual!.jr_level}' : 'N/A');

    final String nomeProximaGraduacao;
    if (proximoNivel != null) {
      nomeProximaGraduacao = proximoNivel.jr_nome ?? 'Lvl ${_parseLevel(proximoNivel.jr_level)}';
    } else if (isLoading || (!catalogoCarregado && totalEtapas > 0)) {
      nomeProximaGraduacao = 'Carregando...';
    } else {
      nomeProximaGraduacao = 'Nível Máximo';
    }

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
            child: _buildResumoColumn('Total Etapas', '$totalEtapas', Colors.white70),
          ),
          Container(height: 24, width: 1, color: Colors.white24),
          Expanded(
            child: _buildResumoColumn(
              'Graduação Atual',
              nomeGraduacaoAtual,
              Colors.greenAccent,
            ),
          ),
          Container(height: 24, width: 1, color: Colors.white24),
          Expanded(
            child: _buildResumoColumn(
              'Próximo Level',
              nomeProximaGraduacao,
              proximoNivel != null ? Colors.amberAccent : Colors.cyanAccent,
            ),
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
            fontSize: 13,
            color: color,
          ),
        ),
      ],
    );
  }

  // 🎯 Card de Próximo Nível
  Widget _buildProximoNivelCard({
    required JourneyRidingModel proximo,
    required JourneyRidingModel? graduacaoAtual,
  }) {
    final String nome = proximo.jr_nome ?? 'Próxima Graduação';
    final String nivel = proximo.jr_level?.toString() ?? '';

    final String? promoDateStr = graduacaoAtual?.uj_promotion_date;
    final DateTime? promoDate =
        promoDateStr != null ? DateTime.tryParse(promoDateStr) : null;
    final int minDays = _parseLevel(graduacaoAtual?.jr_minimum_time_indays);

    DateTime? dataElegivel;
    int? diasRestantes;

    if (promoDate != null && minDays > 0) {
      dataElegivel = promoDate.add(Duration(days: minDays));
      final hoje = DateTime.now();
      final hojeDataApenas = DateTime(hoje.year, hoje.month, hoje.day);
      final elegivelDataApenas = DateTime(
        dataElegivel.year,
        dataElegivel.month,
        dataElegivel.day,
      );
      diasRestantes = elegivelDataApenas.difference(hojeDataApenas).inDays;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withValues(alpha: 0.15),
            Colors.orange.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.stars_rounded,
                  color: Colors.amberAccent,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'PRÓXIMO OBJETIVO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.amberAccent,
                            letterSpacing: 0.8,
                          ),
                        ),
                        if (nivel.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Lvl $nivel',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nome,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              _buildBadgeContagemRegressiva(diasRestantes),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Colors.white12),
          const SizedBox(height: 10),

          if (minDays > 0) ...[
            _buildInfoLinhaProgresso(
              'Tempo Mínimo Exigido:',
              '$minDays dias no nível atual',
            ),
            if (dataElegivel != null) ...[
              const SizedBox(height: 4),
              _buildInfoLinhaProgresso(
                'Elegível a partir de:',
                generalService.formatarDataBr(dataElegivel.toIso8601String()),
              ),
            ],
          ] else ...[
            const Text(
              'Sem tempo mínimo de permanência exigido para a promoção.',
              style: TextStyle(fontSize: 11, color: Colors.white54),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadgeContagemRegressiva(int? diasRestantes) {
    if (diasRestantes == null) return const SizedBox.shrink();

    final bool isApto = diasRestantes <= 0;
    final String textoBadge =
        isApto ? 'APTO / CONCLUÍDO' : 'Faltam $diasRestantes dia(s)';
    final Color corBase = isApto ? Colors.greenAccent : Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: corBase.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: corBase.withValues(alpha: 0.6), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isApto ? Icons.check_circle_outline : Icons.timer_outlined,
            size: 13,
            color: corBase,
          ),
          const SizedBox(width: 4),
          Text(
            textoBadge,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: corBase,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoLinhaProgresso(String rotulo, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          rotulo,
          style: const TextStyle(fontSize: 11, color: Colors.white54),
        ),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildJornadaCard(JourneyRidingModel etapa, bool isAtual) {
    final String tituloEtapa = etapa.jr_nome ?? 'Graduação / Etapa';
    final String dataPromocao = generalService.formatarDataBr(
      etapa.uj_promotion_date ?? '',
    );

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
          color: isAtual ? Colors.greenAccent : Colors.indigoAccent,
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
            if (widget.onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
                tooltip: 'Editar Nível',
                onPressed: () => widget.onEdit!(etapa),
              ),
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
                if (etapa.jr_level != null) ...[
                  const SizedBox(height: 6),
                  _buildInfoRow('Nível:', '${etapa.jr_level}'),
                ],
                const SizedBox(height: 6),
                _buildInfoRow('Data da Promoção:', dataPromocao),
                if (etapa.jr_minimum_time_indays != null) ...[
                  const SizedBox(height: 6),
                  _buildInfoRow(
                    'Tempo Mínimo Exigido:',
                    '${etapa.jr_minimum_time_indays} dias',
                  ),
                ],
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