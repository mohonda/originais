import 'package:flutter/material.dart';
import 'package:gorouter_exemplo/services/general_service.dart';
import 'package:gorouter_exemplo/models/custom_app_bar.dart';
import 'package:gorouter_exemplo/controllers/bd_monthlypayments_controller.dart';
import 'package:gorouter_exemplo/models/mensalidades_model.dart';
import 'package:gorouter_exemplo/view/monthly_payments_profile.dart';
import 'package:gorouter_exemplo/view/monthly_payments_cashier.dart';

class MonthlyPayments extends StatefulWidget {
  const MonthlyPayments({super.key});

  // ==========================================
  @override
  State<MonthlyPayments> createState() => _MonthlyPayments();
}

class _MonthlyPayments extends State<MonthlyPayments> {
  final GeneralService generalService = GeneralService();
  late final BdMonthlyPaymentsController bdMonthlyPaymentsController;

  String _searchQuery = '';
  String _filtroStatus = 'Todos';

  // ==========================================
  @override
  void initState() {
    super.initState();

    bdMonthlyPaymentsController =
        getItbdMonthlyPaymentsController<BdMonthlyPaymentsController>();
  }

  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomFloatingAppBar(title: 'Monthly Payments'),

      body: Column(
        children: [
          // 1. Barra de Busca e Filtros
          Padding(
            // padding: const EdgeInsets.all(12.0),
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 16.0,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['Todos', 'Pagas', 'Pendentes'].map((status) {
                    final isSelected = _filtroStatus == status;
                    return ChoiceChip(
                      label: Text(status),
                      selected: isSelected,
                      onSelected: (_) =>
                        setState( () => _filtroStatus = status ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          Expanded(
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
                        // padding: const EdgeInsets.all(24.0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 16.0,
                        ),

                        // 2. Lista Reativa de Mensalidades
                        child: ValueListenableBuilder<bool>(
                          valueListenable:
                              bdMonthlyPaymentsController.loadingNotifier,
                          builder: (context, isLoading, child) {
                            if (isLoading) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            return ValueListenableBuilder<
                              List<MensalidadesModel>>(
                              valueListenable: bdMonthlyPaymentsController
                                  .monthlyPaymentsNotifier,
                              builder: (context, lista, child) {
                                // Aplicação dos Filtros de Busca e Status
                                final listaFiltrada = lista.where((m) {
                                  final nomeMatch = m.pfl_full_name
                                      .toLowerCase()
                                      .contains(_searchQuery.toLowerCase());
                                  final isPago = m.mes_data_pagamento.isNotEmpty;

                                  if (_filtroStatus == 'Pagas') {
                                    return nomeMatch && isPago;
                                  }
                                  if (_filtroStatus == 'Pendentes') {
                                    return nomeMatch && !isPago;
                                  }
                                  return nomeMatch;
                                }).toList();

                                if (listaFiltrada.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'Nenhuma mensalidade encontrada.',
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  itemCount: listaFiltrada.length,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  itemBuilder: (context, index) {
                                    final mensalidade = listaFiltrada[index];
                                    return _buildMensalidadeCard(mensalidade);
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  Future<void> monthlyPaymentsIndividual(
    MensalidadesModel mensalidade,
    BuildContext context,
  ) async {
    try {
      await bdMonthlyPaymentsController.loadMonthlyPaymentsIndividual(
        mensalidade.mes_pfl_id,
        mensalidade.mes_mes_referencia,
        mensalidade.mes_ano_referencia,
      );

      // Abre a tela somente após carregar os dados com sucesso
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
              const MonthlyPaymentsProfile(),
          ),
        );
      }
    } catch (e) {
      debugPrint('monthlyPaymentsIndividual error: $e');
    }
  }

  // ==========================================
  Future<void> monthlyPaymentsCashier(
    MensalidadesModel mensalidade,
    BuildContext context,
  ) async {
    try {
      await bdMonthlyPaymentsController.loadMonthlyPaymentsIndividual(
        mensalidade.mes_pfl_id,
        mensalidade.mes_mes_referencia,
        mensalidade.mes_ano_referencia,
      );

      // Abre a tela somente após carregar os dados com sucesso
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
              const MonthlyPaymentsCashier(),
          ),
        );
      }
    } catch (e) {
      debugPrint('monthlyPaymentsIndividual error: $e');
    }
  }

  // ==========================================
  Widget _buildMensalidadeCard(MensalidadesModel mensalidade) {
    final bool isPago = mensalidade.mes_data_pagamento.isNotEmpty;
    final bool isConfirmado = mensalidade.mes_data_confirmacao.isNotEmpty;
    late bool isCancelado = false;
    if( !isPago && isConfirmado ){
      isCancelado = true;
    }

    return Card(
      margin: const EdgeInsets.only( bottom: 8 ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10)
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1, // Ocupa 3/8 do espaço horizontal
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundColor: isPago
                            ? Colors.green.shade100
                            : Colors.orange.shade100,
                        child: Icon(
                          isPago
                            ? Icons.check_circle
                            : Icons.pending_actions,
                          color:
                            isPago 
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isPago ? '  PAGO  ' : 'PENDENTE',
                        style: TextStyle(
                          color: isPago
                              ? Colors.green.shade900
                              : Colors.orange.shade900,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ================= COLUNA 1: DADOS DO SÓCIO =================
            Expanded(
              flex: 3, // Ocupa 3/8 do espaço horizontal
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mensalidade.pfl_full_name.isNotEmpty
                        ? mensalidade.pfl_full_name
                        : 'Membro',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ref: ${mensalidade.mes_mes_referencia.toString().padLeft(2, '0')}/${mensalidade.mes_ano_referencia}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Valor Ref: ${
                      generalService.currencyMoneyBr(
                        mensalidade.vpg_valor_normal
                      )
                    }',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700]
                    ),
                  ),
                ],
              ),
            ),

            const VerticalDivider(width: 16, thickness: 1), // Divisória visual
            // ================= COLUNA 2: DADOS DO PAGAMENTO =================
            Expanded(
              flex: 2, // Ocupa 3/8 do espaço horizontal
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPago
                            ? Colors.green
                            : Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 28),
                    ),
                    onPressed: () =>
                        monthlyPaymentsIndividual(mensalidade, context),
                    child: const Text(
                      'Payment',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                  Text(
                    generalService.currencyMoneyBr(mensalidade.mes_valor),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isCancelado 
                        ? Colors.redAccent 
                        :Colors.white
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Data: ${
                      generalService
                      .formatarDataBr(
                        mensalidade.mes_data_pagamento
                      )
                    }',
                    style: TextStyle(
                      fontSize: 11,
                      color: isCancelado 
                        ? Colors.redAccent 
                        :Colors.grey[800]
                    ),
                  ),
                  Text(
                    'Forma: ${mensalidade.fpg_descricao}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isCancelado 
                        ? Colors.redAccent 
                        : Colors.grey[600]
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const VerticalDivider(width: 16, thickness: 1),
            // ================= COLUNA 3: CONFIRMAÇÃO DO TESOUREIRO =================
            Expanded(
              flex: 2, // Ocupa 2/8 do espaço horizontal
              child: Column(
                crossAxisAlignment:
                  CrossAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPago
                            ? Colors.green
                            : Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 28),
                    ),
                    onPressed: () =>{ isPago ? monthlyPaymentsCashier(mensalidade, context):()},
                    child: const Text(
                      'Cashier',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Date: ${ 
                      isConfirmado || isCancelado
                      ? generalService.formatarDataBr(
                          mensalidade.mes_data_confirmacao)
                      : ""
                    }',
                    
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Cashier: ${
                      isConfirmado || isCancelado
                      ? mensalidade.mes_full_name_confirmacao
                      : ""
                    }',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600]
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
