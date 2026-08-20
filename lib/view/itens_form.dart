import 'package:flutter/material.dart';
import '../controllers/bd_journeyriding_controller.dart';
import '../models/Journeyriding_model.dart';
import 'package:go_router/go_router.dart';
import 'package:gorouter_exemplo/models/custom_app_bar.dart';

class ItensForm extends StatefulWidget {
  final BdJourneyRidingController bdJourneyRidingController;
  final JourneyRidingModel? itemAtual;

  const ItensForm({super.key, required this.bdJourneyRidingController, this.itemAtual});

  // ==========================================
  @override
  State<ItensForm> createState() => _FormViewState();
}

class _FormViewState extends State<ItensForm> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();

  // ==========================================
  @override
  void initState() {
    super.initState();
    if (widget.itemAtual != null) {
      // _textController.text = widget.itemAtual!.nome;
    }
  }

  // ==========================================
  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // ==========================================
  Future<void> _salvar() async {
    if (_formKey.currentState!.validate()) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(
                child: CircularProgressIndicator()
              ),
        );

        if (widget.itemAtual == null) {
          // await widget.bdJourneyRidingController
            // .saveItem(_textController.text);
        } else {
          // await widget.bdJourneyRidingController
          //   .updateItem(
          //     widget.itemAtual!.id,
          //     _textController.text,
          //   );
        }

        if (mounted) Navigator.pop( context );

        if (mounted) {
          ScaffoldMessenger.of( context )
            .showSnackBar(
              const SnackBar(
                content: Text('Item salvo com sucesso!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) Navigator.pop(context);

        if (mounted) {
          ScaffoldMessenger.of(context)
            .showSnackBar(
              const SnackBar(
                content: Text('Erro ao salvar. Verifique sua conexão.'),
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
    final bool editando = widget.itemAtual != null;

    return Scaffold(
      appBar: CustomFloatingAppBar(
        title: editando ? 'Editar Item' : 'Novo Item',
      ),
      body: Padding(
        // padding: const EdgeInsets.all(16.0),
        padding: const EdgeInsets.only(
          left: 8.0,
          right: 8.0,
          top: 16.0,
          bottom: 16.0,
        ),
        // child: Center(
        child: SizedBox.expand(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Item',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'O nome não pode ser vazio.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: context.pop,
                            icon: const Icon(Icons.cancel),
                            label: const Text('Cancelar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.indigo,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16
                              ),
                            ),                            
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _salvar,
                            icon: const Icon(Icons.save),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16
                              ),
                            ),
                            label: Text(editando ? 'Salvar Alterações' : 'Cadastrar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

}
