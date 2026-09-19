import 'package:flutter/material.dart';
import 'package:originais/controllers/journey_riding_controller.dart';
import 'package:originais/models/custom_app_bar.dart';
import 'package:originais/controllers/profile_controller.dart';

class JourneyRiding extends StatefulWidget {
  const JourneyRiding({super.key});

  @override
  State<JourneyRiding> createState() => JourneyRidingState();
}

class JourneyRidingState extends State<JourneyRiding> {
  final bdJourneyRidingController =
      getItBdJourneyRidingController<BdJourneyRidingController>();
  
  final bdProfileController = getItBdProfileController<BdProfileController>();

  late String pflId = '';
  late String hldId = '';

  // ==========================================
  void _onErrorChanged() {
    final error = bdJourneyRidingController.errorNotifier.value;

    if (error != null && error.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $error'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ==========================================
  @override
  void initState() {
    super.initState();

    pflId = bdProfileController.pessoaSelecionadaNotifier.value?.pfl_id ?? '';
    hldId = bdProfileController.pessoaSelecionadaNotifier.value?.hld_id ?? '';

    bdJourneyRidingController.errorNotifier.addListener(_onErrorChanged);

    bdJourneyRidingController.loadJourneyRiding(hldId);
  }

  // ==========================================
  @override
  void dispose() {
    bdJourneyRidingController.errorNotifier.removeListener(_onErrorChanged);
    super.dispose();
  }

  // ==========================================
  Future<void> _confirmarExclusao(BuildContext context, String id) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: const Text('Tem certeza que deseja apagar este item?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Excluir',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar == true && context.mounted) {
      await bdJourneyRidingController.deleteProfileJourneyRiding( id, pflId, hldId );
      
      if (context.mounted &&
          (bdJourneyRidingController.errorNotifier.value == null ||
              bdJourneyRidingController.errorNotifier.value!.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item excluído com sucesso!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomFloatingAppBar(title: 'Journey Riding'),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          bdJourneyRidingController.loadingNotifier,
          bdJourneyRidingController.errorNotifier,
          bdJourneyRidingController.bdJourneyRidingNotifier,
        ]),
        builder: (context, _) {
          final isLoading = bdJourneyRidingController.loadingNotifier.value;
          final errorMessage = bdJourneyRidingController.errorNotifier.value;
          final itens = bdJourneyRidingController.bdJourneyRidingNotifier.value;

          return Stack(
            children: [
              Padding(
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
                          child: (errorMessage != null &&
                                  errorMessage.isNotEmpty &&
                                  itens.isEmpty)
                              ? _buildErrorState(errorMessage)
                              : RefreshIndicator(
                                  onRefresh: () async {
                                    await bdJourneyRidingController.loadJourneyRiding(hldId);
                                  },
                                  color: Colors.green,
                                  child: (itens.isEmpty && !isLoading)
                                      ? _buildEmptyState()
                                      : _buildListView(itens, isLoading),
                                ),
                        ),
                        Positioned(
                          bottom: 16.0,
                          right: 16.0,
                          child: FloatingActionButton(
                            heroTag: 'addItemCardFab',
                            elevation: 2,
                            onPressed: isLoading
                                ? null
                                : () {
                                    // Navigator.push(
                                    //   context,
                                    //   MaterialPageRoute(
                                    //     builder: (context) => ItensForm(
                                    //       bdJourneyRidingController:
                                    //           bdJourneyRidingController,
                                    //       itemAtual: null,
                                    //     ),
                                    //   ),
                                    // );
                                  },
                            child: const Icon(Icons.add),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Overlay de carregamento unificado enquanto o banco processa
              if (isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: Center(
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 16.0,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(width: 16),
                              Text(
                                'Processando...',
                                style: TextStyle(fontWeight: FontWeight.w600),
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
            onPressed: () async {
              await bdJourneyRidingController.loadJourneyRiding(hldId);
            },
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
  Widget _buildListView(List<dynamic> itens, bool isLoading) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(),
      itemCount: itens.length,
      itemBuilder: (context, index) {
        final item = itens[index];
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
                item.jr_nome,
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
                        const Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.jr_minimum_time_indays} dias',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.leaderboard_outlined,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Nível ${item.jr_level}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
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
                    onPressed: isLoading
                        ? null
                        : () {
                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(
                            //     builder: (context) => ItensForm(
                            //       bdJourneyRidingController:
                            //           bdJourneyRidingController,
                            //       itemAtual: item,
                            //     ),
                            //   ),
                            // );
                          },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: isLoading
                        ? null
                        : (){},
                        // : () => _confirmarExclusao(context, item.jr_id.toString()),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}