import 'package:flutter/material.dart';
import 'package:originais/controllers/bd_profile_controller.dart';
import 'package:originais/controllers/bd_vprofiles_sanctions_controller.dart';
import 'package:originais/models/vprofiles_sanctions_model.dart';
import 'package:originais/services/general_service.dart';

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

  String _pflIdResolvido = '';
  String _hldIdResolvido = '';

  @override
  void initState() {
    super.initState();
    generalService = GeneralService();
    
    // Instância compartilhada do pai ou resolvida via GetIt
    controller =
        widget.controller ??
        getItBdVProfilesSanctionsController
            .get<BdVProfilesSanctionsController>();
    profileController = getItBdProfileController<BdProfileController>();

    // 🟢 1. Escuta mudanças caso o perfil global demore a carregar
    profileController.pessoaSelecionadaNotifier.addListener(_onPerfilAtualizado);

    // 🟢 2. Garante o carregamento após a renderização do primeiro frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarSancoes();
    });
  }

  @override
  void dispose() {
    profileController.pessoaSelecionadaNotifier.removeListener(_onPerfilAtualizado);
    super.dispose();
  }

  void _onPerfilAtualizado() {
    // Tenta carregar novamente se os IDs ainda não foram resolvidos
    if (_pflIdResolvido.isEmpty || _hldIdResolvido.isEmpty) {
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

    // 🟢 3. Resolve dinamicamente os IDs
    _pflIdResolvido = (widget.pflId != null && widget.pflId!.isNotEmpty)
        ? widget.pflId!
        : (pessoaLogada?.pfl_id?.toString() ?? '');

    _hldIdResolvido = (widget.hldId != null && widget.hldId!.isNotEmpty)
        ? widget.hldId!
        : (pessoaLogada?.hld_id?.toString() ?? '');

    if (_pflIdResolvido.isEmpty || _hldIdResolvido.isEmpty) {
      debugPrint('⚠️ ProfileSanctions: pflId ou hldId ainda indisponíveis.');
      return;
    }

    try {
      debugPrint('🔍 Buscando sanções para pflId: $_pflIdResolvido, hldId: $_hldIdResolvido');
      await controller.loadProfileSanctionsStatus(_pflIdResolvido, _hldIdResolvido);
    } catch (e) {
      debugPrint('❌ Erro ao buscar sanções: $e');
    }
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

            // Ordena as sanções por data de início (Mais recente primeiro)
            final listaOrdenada =
                List<VProfilesSanctionsModel>.from(listaSancoes)..sort((a, b) {
                  final dateA =
                      DateTime.tryParse(a.psan_date_start ?? '') ??
                      DateTime(1970);
                  final dateB =
                      DateTime.tryParse(b.psan_date_start ?? '') ??
                      DateTime(1970);
                  return dateB.compareTo(dateA);
                });

            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildResumoSancoes(listaOrdenada),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: listaOrdenada.length,
                    itemBuilder: (context, index) {
                      return _buildSancaoCard(listaOrdenada[index]);
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

  // 📊 Card de Resumo de Sanções
  Widget _buildResumoSancoes(List<VProfilesSanctionsModel> lista) {
    final int total = lista.length;

    final int ativas = lista.where((s) {
      final String dateEndStr = s.psan_date_end ?? '';
      if (dateEndStr.isEmpty) return true; // Sem data de término = Ativa
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
          _buildResumoColumn('Em Cumpirmento', '$ativas', Colors.redAccent),
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

  // 📋 Card Individual da Sanção
  Widget _buildSancaoCard(VProfilesSanctionsModel sancao) {
    final String dateEndStr = sancao.psan_date_end ?? '';
    final DateTime? endDate = DateTime.tryParse(dateEndStr);
    final bool isAtiva =
        dateEndStr.isEmpty ||
        (endDate != null && endDate.isAfter(DateTime.now()));

    final String sancaoNome =
        sancao.san_name ?? sancao.psan_desc ?? 'Sanção Disciplinar';
    final String inicioData = generalService.formatarDataBr(
      sancao.psan_date_start ?? '',
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
          color: isAtiva ? Colors.redAccent : Colors.greenAccent,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                sancaoNome,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
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
            style: const TextStyle(fontSize: 12, color: Colors.white70),
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
                if (sancao.psan_desc != null &&
                    sancao.psan_desc!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildInfoRow('Observações / Motivo:', sancao.psan_desc!),
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
    final Color color = isAtiva ? Colors.redAccent : Colors.greenAccent;
    final Color bgColor = isAtiva
        ? Colors.red.withValues(alpha: 0.15)
        : Colors.green.withValues(alpha: 0.15);

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