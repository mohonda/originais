import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:originais/controllers/headquarters_bar_controller.dart';
import 'package:originais/controllers/ticket_controller.dart';
import 'package:originais/services/general_service.dart';
import 'package:originais/view/default_loading.dart';

class DashboardWidgetDespesasBar extends StatefulWidget {
  final String? hldId;
  final String? tssId;
  final String? barId;

  const DashboardWidgetDespesasBar({
    super.key,
    this.hldId,
    this.tssId,
    this.barId,
  });

  @override
  State<DashboardWidgetDespesasBar> createState() => _DashboardWidgetDespesasBarState();
}

class _DashboardWidgetDespesasBarState extends State<DashboardWidgetDespesasBar> {
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
    _carregarDadosDespesas();
  }

  @override
  void dispose() {
    isLoadingNotifier.dispose();
    super.dispose();
  }

  /// Carrega os registros de despesas operacionais do bar
  Future<void> _carregarDadosDespesas() async {
    isLoadingNotifier.value = true;

    try {
      await barController.loadHeadquartersBar(
        widget.hldId?.toString() ?? '',
        widget.tssId?.toString() ?? '',
      );

      final periodos = barController.headquartersBarNotifier.value;
      totalPeriodos = periodos.length;

      int acumuloItens = 0;
      double acumuloValor = 0.0;

      for (final barItem in periodos) {
        final String barId = widget.barId ?? barItem.bar_id.toString();
        final String tssId = barItem.bar_tss_id?.toString() ?? widget.tssId?.toString() ?? '';
        final String hldId = barItem.bar_hld_id?.toString() ?? widget.hldId?.toString() ?? '';

        await ticketController.loadTicketsBarTypeSales(
          barId: barId,
          tssId: tssId,
          hldId: hldId,
        );

        final tickets = ticketController.ticketsBarTypeSalesNotifier.value;

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
      // Exceção tratada para manter a consistência da UI
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
            // Header do Card
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.money_off_rounded,
                      color: Colors.greenAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Despesas do Bar',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18, color: Colors.grey),
                  onPressed: _carregarDadosDespesas,
                  tooltip: 'Atualizar Despesas',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Conteúdo dinâmico com ValueListenableBuilder
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
                    // Coluna 1: Total de Períodos/Registros
                    Expanded(
                      child: InkWell(
                        onTap: () => context.go('/monthly_operating_expenses'),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Container(height: 28, width: 1, color: Colors.grey.shade300),

                    // Coluna 2: Total de Itens de Despesa
                    Expanded(
                      child: InkWell(
                        onTap: () => context.go('/monthly_operating_expenses'),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            children: [
                              const Text(
                                'Itens Lançados',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$totalItensCount',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigoAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Container(height: 28, width: 1, color: Colors.grey.shade300),

                    // Coluna 3: Valor Acumulado das Despesas
                    Expanded(
                      child: InkWell(
                        onTap: () => context.go('/monthly_operating_expenses'),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            children: [
                              const Text(
                                'Total Recebido',
                                style: TextStyle(fontSize: 11, color: Colors.greenAccent),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  generalService.currencyMoneyBr(valorTotalDespesas.toString()),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.greenAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
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