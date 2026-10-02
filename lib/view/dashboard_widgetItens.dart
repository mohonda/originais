import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:originais/controllers/headquarters_bar_controller.dart';
import 'package:originais/controllers/ticket_controller.dart';
import 'package:originais/services/general_service.dart';
import 'package:originais/view/default_loading.dart';

class DashboardWidgetItens extends StatefulWidget {
  final String? hldId;
  final String? tssId;

  const DashboardWidgetItens({
    super.key,
    this.hldId,
    this.tssId,
  });

  @override
  State<DashboardWidgetItens> createState() => _DashboardWidgetItensState();
}

class _DashboardWidgetItensState extends State<DashboardWidgetItens> {
  final GeneralService generalService = GeneralService();
  late final BdHeadquartersBarController barController;
  late final TicketController ticketController;

  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(true);

  int totalPeriodos = 0;
  int totalItensCount = 0;
  double valorTotalDespesas = 0.0;

  @override
  void initState() {
    super.initState();
    barController = BdHeadquartersBarController();
    ticketController = TicketController();
    _carregarDados();
  }

  @override
  void dispose() {
    isLoadingNotifier.dispose();
    super.dispose();
  }

  /// Carrega as barras/períodos e itera sobre cada uma para procurar os tickets/itens
  Future<void> _carregarDados() async {
    isLoadingNotifier.value = true;

    try {
      // 1. Carrega os períodos de despesa (Headquarters Bar)
      await barController.loadHeadquartersBar(
        widget.hldId?.toString() ?? '',
        widget.tssId?.toString() ?? '',
      );

      final periodos = barController.headquartersBarNotifier.value;
      totalPeriodos = periodos.length;

      int acumuloItens = 0;
      double acumuloValor = 0.0;

      // 2. Itera sobre cada barra/período e procura os respetivos tickets/itens
      for (final barItem in periodos) {
        final String barId = barItem.bar_id.toString();
        final String tssId = barItem.bar_tss_id?.toString() ?? widget.tssId?.toString() ?? '';
        final String hldId = barItem.bar_hld_id?.toString() ?? widget.hldId?.toString() ?? '';

        await ticketController.loadTicketsBarTypeSales(
          barId: barId,
          tssId: tssId,
          hldId: hldId,
        );

        final tickets = ticketController.ticketsBarTypeSalesNotifier.value;

        // 3. Percorre os tickets e os seus ticketsItems
        for (final tkt in tickets) {
          final List? tktItems = tkt.ticketsItems as List?;

          if (tktItems != null && tktItems.isNotEmpty) {
            acumuloItens += tktItems.length;

            for (final item in tktItems) {
              final rawVal = item.tit_value ?? item.tit_unit_value ?? 0.0;
              acumuloValor += (double.tryParse(rawVal.toString()) ?? 0.0);
            }
          } else {
            final rawVal = tkt.totalConsumo ?? 0.0;
            acumuloValor += (double.tryParse(rawVal.toString()) ?? 0.0);
          }
        }
      }

      totalItensCount = acumuloItens;
      valorTotalDespesas = acumuloValor;
    } catch (_) {
      // Falha tratada ou ignorada na renderização
    } finally {
      if (mounted) {
        isLoadingNotifier.value = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Cabeçalho do Card
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Despesas Operacionais',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(
                  Icons.receipt_long,
                  color: Colors.indigoAccent,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Exibição do estado de carregamento ou dados consolidados
            ValueListenableBuilder<bool>(
              valueListenable: isLoadingNotifier,
              builder: (context, isLoading, child) {
                if (isLoading) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(
                      child: DefaultLoading.showProgressIndicator(),
                    ),
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Coluna 1: Total de Períodos
                    InkWell(
                      onTap: () => context.go('/monthly_operating_expenses'),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Column(
                          children: [
                            const Text(
                              'Períodos',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$totalPeriodos',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Container(height: 28, width: 1, color: Colors.grey.shade300),

                    // Coluna 2: Total de Itens (tickets_items)
                    InkWell(
                      onTap: () => context.go('/monthly_operating_expenses'),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Column(
                          children: [
                            const Text(
                              'Itens',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$totalItensCount',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigoAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Container(height: 28, width: 1, color: Colors.grey.shade300),

                    // Coluna 3: Valor Total de Despesas
                    InkWell(
                      onTap: () => context.go('/monthly_operating_expenses'),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Column(
                          children: [
                            const Text(
                              'Total Despesas',
                              style: TextStyle(fontSize: 11, color: Colors.redAccent),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              generalService.currencyMoneyBr(valorTotalDespesas.toString()),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}