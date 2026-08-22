import 'package:flutter/material.dart';
import 'package:gorouter_exemplo/controllers/bd_journeyriding_controller.dart';
import 'package:gorouter_exemplo/models/vprofile_model.dart';
import 'package:gorouter_exemplo/services/general_service.dart';
import 'package:gorouter_exemplo/controllers/bd_profile_controller.dart';
import 'package:gorouter_exemplo/models/custom_app_bar.dart';
import 'package:gorouter_exemplo/view/associates_details.dart';

class Associates extends StatefulWidget {
  const Associates({super.key});

  // ==========================================
  @override
  State<Associates> createState() => AssociatesState();
}

class AssociatesState extends State<Associates> {
  final bdProfileController =
      getItBdProfileController<BdProfileController>();
  
  final bdJourneyRidingController =
      getItBdJourneyRidingController<BdJourneyRidingController>();

  final generalService = getItGeneralService<GeneralService>();

  // ==========================================
  @override
  void initState() {
    super.initState();
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
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: ListenableBuilder(
                    listenable: Listenable.merge([
                      bdProfileController.loadingNotifier,
                      bdProfileController.errorNotifier,
                      bdProfileController.profilesNotifier,
                    ]),
                    builder: (context, _) {
                      final isLoading =
                          bdProfileController.loadingNotifier.value;

                      final errorMessage =
                          bdProfileController.errorNotifier.value;

                      final itens = bdProfileController
                          .profilesNotifier
                          .value;

                      if (errorMessage != null && !isLoading) {
                        return _buildErrorState(errorMessage);
                      }

                      if (isLoading && itens.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      return RefreshIndicator(
                        onRefresh: bdProfileController.loadProfiles,
                        color: Colors.green,
                        child: itens.isEmpty
                            ? _buildEmptyState()
                            : _buildListView(itens),
                      );
                    },
                  ),
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
          Text(
            errorMessage,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: bdProfileController.loadProfiles,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
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
            child: const Center(child: Text('Nenhum item cadastrado.')),
          ),
        );
      },
    );
  }

  // ==========================================
  Widget _buildListView( List<dynamic> profiles ) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(),
      itemCount: profiles.length,
      itemBuilder: (context, index) {
        final profile = profiles[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 2.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: ListTile(
              title: Text(
                profile.pfl_full_name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              // 👇 Usando Wrap para exibir os dados lado a lado (em colunas)
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Wrap(
                  spacing: 16.0, // Espaço horizontal entre as "colunas"
                  runSpacing:
                      4.0, // Espaço vertical caso falte espaço na tela e quebre a linha
                  children: [
                    // Coluna 1: Tempo Mínimo
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.leaderboard_outlined,
                          size: 14,
                          color: profile.as_id.toString() == '1' 
                            ? Colors.greenAccent 
                            : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Holding: ${profile.hld_name}',
                          style: TextStyle(
                            fontSize: 13,
                            color: profile.as_id.toString() == '1' 
                              ? Colors.greenAccent 
                              : Colors.red,
                          ),
                        ),
                      ],
                    ),

                    // Coluna 2: Nível
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          profile.as_id.toString() == '1' 
                            ? Icons.check_circle 
                            : Icons.error,
                          size: 14,
                          color: profile.as_id.toString() == '1' 
                            ? Colors.greenAccent 
                            : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Status: ${ profile.as_desc }',
                          style: TextStyle(
                            fontSize: 13,
                            color: profile.as_id.toString() == '1' 
                              ? Colors.greenAccent 
                              : Colors.red,
                          ),
                        ),
                      ],
                    ),

                    // Coluna 2: Nível
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_month,
                          size: 14,
                          color: profile.as_id.toString() == '1'
                            ? Colors.greenAccent
                            : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Journey Riding: ${ profile.jr_nome }',
                          style: TextStyle(
                            fontSize: 13,
                            color: profile.as_id.toString() == '1'
                              ? Colors.greenAccent 
                              : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    

                  ],
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.orange),
                    onPressed: () {
                      _associatesDetails( profile, context );
                    }
                    // onPressed: () {
                    //   Navigator.push(
                    //     context,
                    //     MaterialPageRoute(
                          
                    //       // builder: (context) => AssociatesDetails(),
                    //       builder: (context) => _associatesDetails( profile, context )
                    //       // builder: (context) => ItensForm(
                    //       //   bdProfileController:
                    //       //       bdProfileController,
                    //       //   itemAtual: item,
                    //       ),
                    //     );
                    // },
                  ),
                ],
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
    try {
      // tmp = AssociatesDetails(itemAtual: vProfileModel )
      await bdJourneyRidingController.loadJourneyRidingDetais(
        vProfileModel.pfl_id, 
        vProfileModel.hld_id
      );

      // Abre a tela somente após carregar os dados com sucesso
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
              AssociatesDetails( itemAtual: vProfileModel ),
          ),
        );
      }
    } catch (e) {
      debugPrint('monthlyPaymentsIndividual error: $e');
    }
  }

}
