import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:originais/models/custom_app_bar.dart';
import 'package:originais/services/general_service.dart';
import 'package:originais/controllers/bd_vmensalidades_distinct_controller.dart';
import 'package:originais/view/monthly_generation_details.dart';
import 'package:originais/controllers/bd_payment_value_controller.dart';
import 'package:originais/controllers/bd_profile_controller.dart';
import 'package:originais/controllers/bd_monthlypayments_controller.dart';

class MonthlyGeneration extends StatefulWidget {
  const MonthlyGeneration({super.key});

  // ==========================================
  @override
  State<MonthlyGeneration> createState() => MonthlyGenerationState();
}

class MonthlyGenerationState extends State<MonthlyGeneration> {
  final bdVMensalidadesDistinctController =
      getItBdVMensalidadesDistinctController<
        BdVMensalidadesDistinctController
      >();

  final bdPaymentValueController =
      getItBdPaymentValueController<BdPaymentValueController>();

  final bdProfileController = getItBdProfileController<BdProfileController>();

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
      appBar: CustomFloatingAppBar(title: 'Monthly Generation'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 16.0,
            ),
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
                          bdVMensalidadesDistinctController.loadingNotifier,
                          bdVMensalidadesDistinctController.errorNotifier,
                          bdVMensalidadesDistinctController
                              .vMensalidadeDistinctNotifier,
                        ]),
                        builder: (context, _) {
                          final isLoading = bdVMensalidadesDistinctController
                              .loadingNotifier
                              .value;

                          // final errorMessage =
                          //     bdVMensalidadesDistinctController.errorNotifier.value;

                          final itens = bdVMensalidadesDistinctController
                              .vMensalidadeDistinctNotifier
                              .value;

                          // if (errorMessage != null && !isLoading) {
                          //   return _buildErrorState(errorMessage);
                          // }

                          if (isLoading && itens.isEmpty) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          return RefreshIndicator(
                            onRefresh: bdVMensalidadesDistinctController
                                .loadMensalidadesDistincts,
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
                        onPressed: () => monthlyGenerationDetails(),
                        child: const Icon(Icons.add),
                      ),
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
                'Ref: ${item.mes_mes_referencia.toString().padLeft(2, '0')}/${item.mes_ano_referencia} - ${item.vpg_desc}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              // 👇 Usando Wrap para exibir os dados lado a lado (em colunas)
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Wrap(
                  spacing: 16.0,
                  runSpacing: 4.0,
                  children: [
                    // Coluna 1: Tempo Mínimo
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.monetization_on,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Valor de: ${generalService.currencyMoneyBr(item.vpg_valor_desconto)} até dia ${item.vpg_dia_valor_desconto}',
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
                          Icons.monetization_on,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Valor de: ${generalService.currencyMoneyBr(item.vpg_valor_normal)} até dia ${item.vpg_dia_valor_normal}',
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
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    onPressed: () {
                      deleteMonthlyGeneration(
                        item.mes_mes_referencia,
                        item.mes_ano_referencia,
                        item.mes_hld_id
                      );
                    },
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
  void monthlyGenerationDetails() async {
    bdPaymentValueController.loadPaymentValue();

    bdProfileController.loadProfiles();

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MonthlyGenerationDetails()),
      );
    }
  }

  // ==========================================
  Future<void> deleteMonthlyGeneration(
    String month,
    String year,
    String hldId,
  ) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: const Text(
            'Tem certeza que deseja apagar?\nEsta ação apaga todas mensalidades refentes ao mês/ano?',
          ),
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
        await bdVMensalidadesDistinctController.deleteMensalidadesDistincts(
          month,
          year,
          hldId,
        );

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
      } finally {
        final BdMonthlyPaymentsController bdMonthlyPaymentsController;

        bdMonthlyPaymentsController = 
          getItbdMonthlyPaymentsController<BdMonthlyPaymentsController>();
        
        bdMonthlyPaymentsController.loadCurrentMonthlyPayment();
      }
    }
  }
}
