import 'package:flutter/material.dart';
import 'package:gorouter_exemplo/view/itens_form.dart';
import 'package:gorouter_exemplo/controllers/bd_item_controller.dart';
import 'package:gorouter_exemplo/models/custom_app_bar.dart';

class Itens extends StatefulWidget {
  const Itens({super.key});

  @override
  State<Itens> createState() => _Itens();
}

class _Itens extends State<Itens> {
  final bdItemController = getItBdItemController<BdItemController>();

  @override
  void initState() {
    super.initState();
  }

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
        await bdItemController.deleteItem(id);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Item excluído!')));
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomFloatingAppBar(title: 'Lista de Itens'),
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
                      bdItemController.loadingNotifier,
                      bdItemController.errorNotifier,
                      bdItemController.itensNotifier,
                    ]),
                    builder: (context, _) {
                      final isLoading = bdItemController.loadingNotifier.value;
                      final errorMessage = bdItemController.errorNotifier.value;
                      final itens = bdItemController.itensNotifier.value;

                      if (errorMessage != null && !isLoading) {
                        return _buildErrorState(errorMessage);
                      }

                      if (isLoading && itens.isEmpty) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: bdItemController.loadItems,
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
                            bdItemController: bdItemController,
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
            onPressed: bdItemController.loadItems,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

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

  Widget _buildListView(List<dynamic> itens) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(),
      itemCount: itens.length,
      itemBuilder: (context, index) {
        final item = itens[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(
            bottom: 2.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: ListTile(
              title: Text(
                item.nome,
                style: const TextStyle(fontWeight: FontWeight.w500),
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
                            bdItemController: bdItemController,
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
