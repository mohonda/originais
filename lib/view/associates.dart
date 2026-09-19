import 'package:flutter/material.dart';
import 'package:originais/controllers/journey_riding_controller.dart';
import 'package:originais/controllers/profile_associate_status_controller.dart';
import 'package:originais/controllers/profiles_sanctions_controller.dart';
import 'package:originais/models/vprofile_model.dart';
import 'package:originais/services/general_service.dart';
import 'package:originais/controllers/profile_controller.dart';
import 'package:originais/models/custom_app_bar.dart';
import 'package:originais/view/associates_details.dart';
import 'package:originais/controllers/executive_committee_termofoffice_members_controller.dart';

class Associates extends StatefulWidget {
  const Associates({super.key});

  @override
  State<Associates> createState() => AssociatesState();
}

class AssociatesState extends State<Associates> {
  final bdProfileController =
      getItBdProfileController<BdProfileController>();

  final bdJourneyRidingController =
      getItBdJourneyRidingController<BdJourneyRidingController>();

  final bdVProfileAssociateStatusController =
      getItBdVProfileAssociateStatusController<BdVProfileAssociateStatusController>();

  final bdVProfilesSanctionsController =
      getItBdVProfilesSanctionsController<BdVProfilesSanctionsController>();

  final bdVExecutiveCommitteeTermOfOfficeMembersController =
      getItBdVExecutiveCommitteeTermOfOfficeMembersController<BdVExecutiveCommitteeTermOfOfficeMembersController>();

  final generalService = getItGeneralService<GeneralService>();

  // Notifier para controlar o indicador de carregamento ao abrir detalhes
  final ValueNotifier<bool> isProcessingDetailsNotifier = ValueNotifier<bool>(false);

  // ==========================================
  @override
  void initState() {
    super.initState();
    // 🔔 Ouve mudanças no errorNotifier do controller
    bdProfileController.errorNotifier.addListener(_handleError);

    // Carregamento inicial dos dados após a renderização da árvore
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarPerfis();
    });
  }

  // ==========================================
  void _carregarPerfis() {
    bdProfileController.loadProfiles('1');
  }

  // ==========================================
  void _handleError() {
    final errorMessage = bdProfileController.errorNotifier.value;
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
  void dispose() {
    bdProfileController.errorNotifier.removeListener(_handleError);
    isProcessingDetailsNotifier.dispose();
    super.dispose();
  }

  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomFloatingAppBar(title: 'Associates'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
        child: SizedBox.expand(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Stack(
              children: [
                // Conteúdo principal reativo
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: ListenableBuilder(
                    listenable: Listenable.merge([
                      bdProfileController.loadingNotifier,
                      bdProfileController.profilesNotifier,
                    ]),
                    builder: (context, _) {
                      final isLoading = bdProfileController.loadingNotifier.value;
                      final errorMessage = bdProfileController.errorNotifier.value;
                      final itens = bdProfileController.profilesNotifier.value;

                      if (errorMessage != null && errorMessage.isNotEmpty && itens.isEmpty && !isLoading) {
                        return _buildErrorState(errorMessage);
                      }

                      if (isLoading && itens.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      return RefreshIndicator(
                        onRefresh: () async => _carregarPerfis(),
                        color: Colors.indigo,
                        child: itens.isEmpty
                            ? _buildEmptyState()
                            : _buildListView(itens),
                      );
                    },
                  ),
                ),

                // Indicador visual de processamento ao carregar detalhes do associado
                ValueListenableBuilder<bool>(
                  valueListenable: isProcessingDetailsNotifier,
                  builder: (context, isProcessing, _) {
                    if (!isProcessing) return const SizedBox.shrink();
                    return Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.3),
                        child: Center(
                          child: Card(
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  CircularProgressIndicator(),
                                  SizedBox(width: 16),
                                  Text(
                                    'Carregando dados do associado...',
                                    style: TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(
            errorMessage,
            style: const TextStyle(color: Colors.red, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _carregarPerfis,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: const Center(
              child: Text(
                'Nenhum associado encontrado.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  Widget _buildListView(List<dynamic> profiles) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: profiles.length,
      itemBuilder: (context, index) {
        final profile = profiles[index];
        final String asId = profile.as_id?.toString() ?? '';
        final String isMonthly = profile.as_ismonthlypayment?.toString() ?? 'false';

        final Color statusColor = asId == '1'
            ? Colors.green
            : (isMonthly == 'true' ? Colors.orange : Colors.red);

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: ListTile(
              title: Text(
                profile.pfl_full_name ?? 'Associado Sem Nome',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Wrap(
                  spacing: 16.0,
                  runSpacing: 4.0,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.leaderboard_outlined,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Holding: ${profile.hld_name ?? 'N/A'}',
                          style: TextStyle(fontSize: 13, color: statusColor),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          asId == '1' ? Icons.check_circle : Icons.error,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Status: ${profile.as_desc ?? 'N/A'}',
                          style: TextStyle(fontSize: 13, color: statusColor),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_month,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Journey Riding: ${profile.jr_nome ?? 'N/A'}',
                          style: TextStyle(fontSize: 13, color: statusColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.orange),
                onPressed: () => _associatesDetails(profile, context),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  Future<void> _associatesDetails(
    VProfileModel vProfileModel,
    BuildContext context,
  ) async {
    isProcessingDetailsNotifier.value = true;
    try {
      final pflId = vProfileModel.pfl_id.toString();
      final hldId = vProfileModel.hld_id.toString();

      // Carregamento paralelo das dependências do perfil
      await Future.wait([
        bdJourneyRidingController.loadJourneyRidingDetais(pflId, hldId),
        bdVProfileAssociateStatusController.loadProfileAssociateStatus(pflId, hldId),
        bdVProfilesSanctionsController.loadProfileSanctionsStatus(pflId, hldId),
        bdVExecutiveCommitteeTermOfOfficeMembersController.loadExecutiveOrderByDateStart(pflId, hldId),
      ]);

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AssociatesDetails(itemAtual: vProfileModel),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erro ao carregar detalhes do associado: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao carregar detalhes: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      isProcessingDetailsNotifier.value = false;
    }
  }

}