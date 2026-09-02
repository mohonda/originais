import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:originais/models/custom_app_bar.dart';
import 'package:originais/services/general_service.dart';
import 'package:originais/controllers/bd_journeyriding_controller.dart';
import 'package:originais/models/journeyriding_model.dart';

class AssociatesProfileJourneyRiding extends StatefulWidget {
  final JourneyRidingModel itemAtual;
  final lastLevel;
  final bool isNew;
  
  const AssociatesProfileJourneyRiding({
    super.key,
    required this.itemAtual,
    required this.lastLevel,
    required this.isNew
    });

  // ==========================================
  @override
  State<AssociatesProfileJourneyRiding>
    createState() => AssociatesProfileJourneyRidingState();
}

class AssociatesProfileJourneyRidingState
  extends State<AssociatesProfileJourneyRiding> {
  
  final bdJourneyRidingController =
      getItBdJourneyRidingController<BdJourneyRidingController>();
  
  final generalService = getItGeneralService<GeneralService>();

  final idController = TextEditingController();
  final hldController = TextEditingController();
  final fullNameController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  final datapagamento = TextEditingController();
  String? formaPagamentoSelecionada;

  // ==========================================
  @override
  void initState() {
    idController.text = widget.itemAtual.pfl_id.toString();
    fullNameController.text = widget.itemAtual.pfl_full_name.toString();
    hldController.text = widget.itemAtual.hld_name.toString();

    if ( !widget.isNew ) {
      datapagamento.text = generalService.formatarDataBr(
        widget.itemAtual.uj_promotion_date.toString()
      );
      
      formaPagamentoSelecionada =
        widget.itemAtual.jr_id.toString() ?? '';
    } else {
      datapagamento.text = generalService.formatarDataBr(DateTime.now().toIso8601String());
    }

    super.initState();
  }

  // ==========================================
  @override
  void dispose() {
    
    super.dispose();
  }

  // ==========================================
  @override
  Widget build(BuildContext context) {
    const double distance = 16.0;

    return Scaffold(
      appBar: CustomFloatingAppBar(
        title: 'Journey of the Riding - ${fullNameController.text}'
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. TOP FIXO (ID e Holding)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: idController,
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: 'ID:',
                            prefixIcon: Icon(Icons.key),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: distance),
                      Expanded(
                        child: TextFormField(
                          controller: hldController,
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: 'Holding:',
                            prefixIcon: Icon(Icons.verified_user),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: distance),

                  // 2. MEIO ROLÁVEL (Apenas as tabelas rolam)
                  Expanded(
                    child: SingleChildScrollView(
                      primary: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                              // 2. FORMA DE PAGAMENTO
                              ListenableBuilder(
                                listenable: bdJourneyRidingController
                                    .bdJourneyRidingNotifier,
                                builder: (context, child) {
                                  final listaFormas = bdJourneyRidingController
                                      .bdJourneyRidingNotifier
                                      .value;

                                  if (listaFormas.isEmpty) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  bool valorExisteNaLista = listaFormas.any(
                                    (forma) =>
                                        forma.jr_id.toString() ==
                                        formaPagamentoSelecionada.toString(),
                                  );
                                  if (!valorExisteNaLista) {
                                    formaPagamentoSelecionada = null;
                                  }
                                  final int level = int.parse(widget.lastLevel);

                                  List<JourneyRidingModel>? tmp;
                                  if (level >= 1) {
                                    tmp = listaFormas.where((p) {
                                      final itemLevel = int.tryParse(p.jr_level ?? '') ?? 0;
                                      
                                      return itemLevel > level;
                                    }).toList();
                                  } else {
                                    tmp = listaFormas;
                                  }
                                  
                                  return DropdownButtonFormField<String>(
                                    initialValue: formaPagamentoSelecionada,
                                    
                                    decoration: const InputDecoration(
                                      labelText: 'Journey Riding:',
                                      prefixIcon: Icon(Icons.payment),
                                      border: OutlineInputBorder(),
                                    ),
                                    hint: const Text('Selecione...'),
                                    items: tmp.map((forma) {
                                      return DropdownMenuItem<String>(
                                        value: forma.jr_id.toString(),
                                        child: Text(forma.jr_nome.toString()),
                                      );
                                    }).toList(),
                                    // onChanged: !widget.isNew
                                    //   ? null 
                                    //   : (String? newValue) {
                                    //   setState(() {
                                    //     formaPagamentoSelecionada = newValue;
                                    //   });
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        formaPagamentoSelecionada = newValue;
                                      });
                                    },
                                    validator: (value) =>
                                        value == null || value.isEmpty
                                        ? 'Selecione'
                                        : null,

                                  );
                                },
                              ),
                              const SizedBox(height: distance),

                             // 3. DATA DO PAGAMENTO
                              TextFormField(
                                controller: datapagamento,
                                textAlign: TextAlign.end,
                                decoration: const InputDecoration(
                                  labelText: 'Promotion Date:',
                                  prefixIcon: Icon(Icons.calendar_month),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (datapagamento) =>
                                    datapagamento == null ||
                                        datapagamento.trim().isEmpty
                                    ? 'Informe a data'
                                    : null,
                              ),
                              const SizedBox(height: distance),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: distance),

                   // --- BOTÕES DE AÇÃO ---
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Cancelar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.indigo,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      if ( !widget.isNew ) ...[
                        const SizedBox(width: distance),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                deleteProfileJourneyRiding(
                                  context,
                                  widget.itemAtual.uj_id,
                                  widget.itemAtual.pfl_id,
                                  widget.itemAtual.hld_id
                                );
                              }
                            },
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(width: distance),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              updateProfileJourneyRiding();
                            }
                          },
                          icon: const Icon(Icons.save),
                          label: const Text('Salvar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
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
    );
  }

  // ==========================================
  void updateProfileJourneyRiding() async {
    try {
      if ( widget.isNew ) {
        bdJourneyRidingController.insertProfileJourneyRiding(
          widget.itemAtual.pfl_id,
          widget.itemAtual.hld_id,
          formaPagamentoSelecionada ?? '',
          generalService.date2Supabase(datapagamento.text),
        );
      } else {
        bdJourneyRidingController.updateProfileJourneyRiding(
          widget.itemAtual.uj_id,
          widget.itemAtual.pfl_id,
          widget.itemAtual.hld_id,
          formaPagamentoSelecionada ?? '',
          generalService.date2Supabase(datapagamento.text),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error dados não atualizados!'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dados atualizados com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      context.pop();
    }
  }

    // ==========================================
  Future<void> deleteProfileJourneyRiding(
    BuildContext context,
    String ujId,
    String ujPflId,
    String ujHldId
  ) async {
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
        await bdJourneyRidingController
          .deleteProfileJourneyRiding( ujId, ujPflId, ujHldId );
        
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(
            content: Text( 'Item excluído!' )
          ));
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
      finally {
        context.pop();
      }
    }
  }

}
