import 'package:flutter/material.dart';
import 'package:originais/view/itens_form.dart';
import 'package:originais/controllers/bd_journeyriding_controller.dart';
import 'package:originais/models/custom_app_bar.dart';

class JourneyRiding extends StatefulWidget {
  const JourneyRiding({super.key});

  // ==========================================
  @override
  State<JourneyRiding> createState() => JourneyRidingState();
}

class JourneyRidingState extends State<JourneyRiding> {
  final bdJourneyRidingController =
      getItBdJourneyRidingController<BdJourneyRidingController>();

  // ==========================================
  @override
  void initState() {
    super.initState();
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
      try {
        // await bdJourneyRidingController.deleteItem( id );
        // if (context.mounted) {
        //   ScaffoldMessenger.of(
        //     context,
        //   ).showSnackBar(const SnackBar(
        //     content: Text( 'Item excluído!' )
        //   ));
        // }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao excluir.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomFloatingAppBar(title: 'Journey Riding'),
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
                      bdJourneyRidingController.loadingNotifier,
                      bdJourneyRidingController.errorNotifier,
                      bdJourneyRidingController.bdJourneyRidingNotifier,
                    ]),
                    builder: (context, _) {
                      final isLoading =
                          bdJourneyRidingController.loadingNotifier.value;

                      final errorMessage =
                          bdJourneyRidingController.errorNotifier.value;

                      final itens = bdJourneyRidingController
                          .bdJourneyRidingNotifier
                          .value;

                      if (errorMessage != null && !isLoading) {
                        return _buildErrorState(errorMessage);
                      }

                      if (isLoading && itens.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      return RefreshIndicator(
                        onRefresh: bdJourneyRidingController.loadJourneyRiding,
                        color: Colors.green,
                        child: itens.isEmpty
                            ? _buildEmptyState()
                            : _buildListView(itens),
                      );
                    },
                  ),
                ),

                Positioned(
                  bottom: 16.0,
                  right: 16.0,
                  child: FloatingActionButton(
                    heroTag: 'addItemCardFab',
                    elevation: 2,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ItensForm(
                            bdJourneyRidingController:
                                bdJourneyRidingController,
                            itemAtual: null,
                          ),
                        ),
                      );
                    },
                    child: const Icon(Icons.add),
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
            onPressed: bdJourneyRidingController.loadJourneyRiding,
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
  Widget _buildListView(List<dynamic> itens) {
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
                        const Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color:  Colors.grey,
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

                    // Coluna 2: Nível
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.leaderboard_outlined,
                          size: 14,
                          color:  Colors.grey,
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ItensForm(
                            bdJourneyRidingController:
                                bdJourneyRidingController,
                            itemAtual: item,
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmarExclusao(context, item.id),
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
