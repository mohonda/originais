import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:originais/controllers/monthly_payments_controller.dart';
import 'package:originais/controllers/profile_controller.dart';
import 'package:originais/services/general_service.dart';
import 'package:originais/view/default_loading.dart';

class DashboardWidgetUsers extends StatefulWidget {
  const DashboardWidgetUsers({super.key});

  @override
  State<DashboardWidgetUsers> createState() => _DashboardWidgetUsersState();
}

class _DashboardWidgetUsersState extends State<DashboardWidgetUsers> {
  final GeneralService generalService = GeneralService();

  @override
  Widget build(BuildContext context) {
    final bdProfileController = getItBdProfileController<BdProfileController>();
    final bdMonthlyPaymentsController = getItbdMonthlyPaymentsController<BdMonthlyPaymentsController>();

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
                  'Resumo de Usuários & Pagamentos',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(
                  Icons.verified_user,
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Reatividade unificada para Usuários e Mensalidades
            ListenableBuilder(
              listenable: Listenable.merge([
                bdProfileController.loadingNotifier,
                bdProfileController.profilesNotifier,
                bdMonthlyPaymentsController.loadingNotifier,
                bdMonthlyPaymentsController.monthlyPaymentsNotifier,
              ]),
              builder: (context, child) {
                final isLoading = bdProfileController.loadingNotifier.value ||
                    bdMonthlyPaymentsController.loadingNotifier.value;

                if (isLoading) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(
                      child: DefaultLoading.showProgressIndicator(),
                    ),
                  );
                }

                // 1. Quantidade de Usuários
                final profiles = bdProfileController.profilesNotifier.value ?? [];
                // final int totalUsuarios = profiles.length;

                // 2. Filtragem de Mensalidades (Mês atual ou total carregado)
                final mensalidades = bdMonthlyPaymentsController.monthlyPaymentsNotifier.value;
                final now = DateTime.now();

                final mensalidadesMesAtual = mensalidades.where((m) {
                  final mMonth = int.tryParse(m.month.toString()) ?? 0;
                  final mYear = int.tryParse(m.year.toString()) ?? 0;
                  return mMonth == now.month && mYear == now.year;
                }).toList();

                // Utiliza o mês atual se houver dados, senão usa a lista global carregada
                final listaCalculo = mensalidadesMesAtual.isNotEmpty
                    ? mensalidadesMesAtual
                    : mensalidades;

                // 3. Total de Pagantes (comprovante anexado)
                final int totalPagantes = listaCalculo
                    .where((m) => m.tkt_paiment_path.isNotEmpty)
                    .length;

                // 4. Valor Pago Acumulado
                final double valorPago = listaCalculo.fold<double>(0.0, (soma, m) {
                  if (m.tkt_paiment_path.isNotEmpty) {
                    final double valor = double.tryParse(m.tit_unit_value.toString()) ?? 0.0;
                    return soma + valor;
                  }
                  return soma;
                });

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Coluna 1: Total de Usuários
                    InkWell(
                      onTap: () => context.go('/profile_screen'),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Column(
                          children: [
                            const Text(
                              'Usuários',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${listaCalculo.length}',
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

                    // Coluna 2: Total de Pagantes
                    InkWell(
                      onTap: () => context.go('/mensalidades'),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Column(
                          children: [
                            const Text(
                              'Pagantes',
                              style: TextStyle(fontSize: 11, color: Colors.green),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$totalPagantes',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Container(height: 28, width: 1, color: Colors.grey.shade300),

                    // Coluna 3: Valor Pago até o momento
                    InkWell(
                      onTap: () => context.go('/mensalidades'),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Column(
                          children: [
                            const Text(
                              'Total Pago',
                              style: TextStyle(fontSize: 11, color: Colors.green),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              generalService.currencyMoneyBr(valorPago.toString()),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
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