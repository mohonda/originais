import 'package:flutter/material.dart';
import 'package:originais/models/custom_app_bar.dart';
import 'package:originais/services/general_service.dart';
import 'package:originais/controllers/monthly_distinct_controller.dart';
import 'package:originais/view/monthly_generation_details.dart';
import 'package:originais/controllers/payment_value_controller.dart';
import 'package:originais/controllers/profile_controller.dart';
import 'package:originais/controllers/monthly_payments_controller.dart';

class MonthlyGeneration extends StatefulWidget {
  const MonthlyGeneration({super.key});

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

  final datapagamento = TextEditingController();
  String? formaPagamentoSelecionada;

  // ==========================================
  void _onErrorChanged() {
    final error = bdVMensalidadesDistinctController.errorNotifier.value;

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

    bdVMensalidadesDistinctController.errorNotifier.addListener(_onErrorChanged);

    bdVMensalidadesDistinctController.loadMensalidadesDistincts();
  }

  // ==========================================
  @override
  void dispose() {
    // Desvincular o listener para evitar vazamentos de memória (memory leaks)
    bdVMensalidadesDistinctController.errorNotifier.removeListener(_onErrorChanged);
    idController.dispose();
    hldController.dispose();
    fullNameController.dispose();
    datapagamento.dispose();
    super.dispose();
  }

  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomFloatingAppBar(title: 'Monthly Generation'),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          bdVMensalidadesDistinctController.loadingNotifier,
          bdVMensalidadesDistinctController.errorNotifier,
          bdVMensalidadesDistinctController.vMensalidadeDistinctNotifier,
        ]),
        builder: (context, _) {
          final isLoading =
              bdVMensalidadesDistinctController.loadingNotifier.value;
          final errorMessage =
              bdVMensalidadesDistinctController.errorNotifier.value;
          final itens =
              bdVMensalidadesDistinctController.vMensalidadeDistinctNotifier.value;

          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 12.0,
                ),
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
                              child: (errorMessage != null &&
                                      errorMessage.isNotEmpty &&
                                      itens.isEmpty)
                                  ? _buildErrorState(errorMessage)
                                  : RefreshIndicator(
                                      onRefresh: bdVMensalidadesDistinctController
                                          .loadMensalidadesDistincts,
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
                                    : () => monthlyGenerationDetails(),
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

              // Overlay global de carregamento enquanto a requisição do banco está em execução
              if (isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
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
                                'Processando requisição...',
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
              await bdVMensalidadesDistinctController
                  .loadMensalidadesDistincts();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
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
                'Ref: ${item.mes_mes_referencia.toString().padLeft(2, '0')}/${item.mes_ano_referencia} - ${item.vpg_desc}',
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
                    onPressed: isLoading
                        ? null
                        : () {
                            deleteMonthlyGeneration(
                              item.mes_mes_referencia.toString(),
                              item.mes_ano_referencia.toString(),
                              item.mes_hld_id.toString(),
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
    bdProfileController.loadProfiles('1');

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const MonthlyGenerationDetails(),
        ),
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
            'Tem certeza que deseja apagar?\nEsta ação apaga todas mensalidades referentes ao mês/ano.',
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
      await bdVMensalidadesDistinctController.deleteMensalidadesDistincts(
        month,
        year,
        hldId,
      );

      final error = bdVMensalidadesDistinctController.errorNotifier.value;
      if (context.mounted && (error == null || error.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mensalidades excluídas com sucesso!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        final bdMonthlyPaymentsController =
            getItbdMonthlyPaymentsController<BdMonthlyPaymentsController>();
        await bdMonthlyPaymentsController.loadCurrentMonthlyPayment();
      }
    }
  }
}