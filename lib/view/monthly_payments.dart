import 'package:flutter/material.dart';
import 'package:originais/services/general_service.dart';
import 'package:originais/models/custom_app_bar.dart';
import 'package:originais/controllers/bd_monthlypayments_controller.dart';
import 'package:originais/models/mensalidades_model.dart';
import 'package:originais/view/monthly_payments_cashier_page.dart';
import 'package:originais/view/monthly_payments_profile_page.dart';

class MonthlyPayments extends StatefulWidget {
  const MonthlyPayments({super.key});

  @override
  State<MonthlyPayments> createState() => _MonthlyPaymentsState();
}

class _MonthlyPaymentsState extends State<MonthlyPayments> {
  final GeneralService generalService = GeneralService();
  late final BdMonthlyPaymentsController bdMonthlyPaymentsController;

  final String _searchQuery = '';
  String _filtroStatus = 'Todos';

  @override
  void initState() {
    super.initState();
    bdMonthlyPaymentsController =
        getItbdMonthlyPaymentsController<BdMonthlyPaymentsController>();
    bdMonthlyPaymentsController.initRealtime(bdMonthlyPaymentsController.hld_id);
  }
  
  @override
  void dispose() {
    bdMonthlyPaymentsController.disposeRealtime();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomFloatingAppBar(title: 'Monthly Payments'),
      body: ValueListenableBuilder<bool>(
        valueListenable: bdMonthlyPaymentsController.loadingNotifier,
        builder: (context, isLoading, child) {
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ValueListenableBuilder<List<MensalidadesModel>>(
            valueListenable:
                bdMonthlyPaymentsController.monthlyPaymentsNotifier,
            builder: (context, lista, child) {
              if (lista.isEmpty) {
                return const Center(
                  child: Text('Nenhuma mensalidade encontrada.'),
                );
              }

              // 1. Extrai os meses/anos únicos
              final listaMesAno = lista
                  .map(
                    (m) =>
                        '${m.mes_mes_referencia.toString().padLeft(2, '0')}/${m.mes_ano_referencia}',
                  )
                  .toSet()
                  .toList();

              // 2. Ordena cronologicamente por Ano e Mês (mais recente para o mais antigo)
              listaMesAno.sort((a, b) {
                final partsA = a.split('/');
                final partsB = b.split('/');

                final dateA = DateTime(
                  int.parse(partsA[1]),
                  int.parse(partsA[0]),
                );
                final dateB = DateTime(
                  int.parse(partsB[1]),
                  int.parse(partsB[0]),
                );

                return dateB.compareTo(dateA);
              });

              // 3. Define a aba inicial com base no Mês/Ano atual
              final now = DateTime.now();
              final mesAnoAtual =
                  '${now.month.toString().padLeft(2, '0')}/${now.year}';
              final indexAtual = listaMesAno.indexOf(mesAnoAtual);
              final int initialIndex = indexAtual != -1 ? indexAtual : 0;

              return DefaultTabController(
                length: listaMesAno.length,
                initialIndex: initialIndex,
                child: Builder(
                  builder: (tabContext) {
                    return Column(
                      children: [
                        // 1. Linha com Abas e Filtro (Fixo no topo)
                        Row(
                          children: [
                            Expanded(
                              child: TabBar(
                                isScrollable: true,
                                tabAlignment: TabAlignment.start,
                                tabs: listaMesAno
                                    .map((mesAno) => Tab(text: 'Ref: $mesAno'))
                                    .toList(),
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.filter_alt_outlined,
                                color: _filtroStatus == 'Todos'
                                    ? Colors.grey
                                    : Colors.green,
                              ),
                              tooltip: 'Filtrar status',
                              initialValue: _filtroStatus,
                              onSelected: (status) =>
                                  setState(() => _filtroStatus = status),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'Todos',
                                  child: Text('Todos'),
                                ),
                                const PopupMenuItem(
                                  value: 'Pagas',
                                  child: Text('Pagas'),
                                ),
                                const PopupMenuItem(
                                  value: 'Pendentes',
                                  child: Text('Pendentes'),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // 2. Conteúdo das Listas
                        Expanded(
                          child: TabBarView(
                            children: listaMesAno.map((mesAnoRef) {
                              final listaFiltrada = lista.where((m) {
                                final refAtual =
                                    '${m.mes_mes_referencia.toString().padLeft(2, '0')}/${m.mes_ano_referencia}';
                                if (refAtual != mesAnoRef) return false;

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
                                  child: Text('Nenhum registro para este filtro.'),
                                );
                              }

                              return Column(
                                children: [
                                  // 📊 Balancete exibido no topo antes dos cards
                                  _buildBalancete(listaFiltrada),

                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: listaFiltrada.length,
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      itemBuilder: (context, index) {
                                        return _buildMensalidadeCard(
                                          listaFiltrada[index],
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),

                        // 🟢 3. Mensagem no Rodapé da Página (Elimina o flicker)
                        AnimatedBuilder(
                          animation: DefaultTabController.of(tabContext),
                          builder: (context, child) {
                            final controller = DefaultTabController.of(tabContext);
                            final abaSelecionada = listaMesAno[controller.index];
                            final isAbaAtual = abaSelecionada == mesAnoAtual;

                            if (isAbaAtual) return const SizedBox.shrink();

                            return Container(
                              width: double.infinity,
                              color: Colors.amber.shade900.withValues(alpha: 0.8),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.lock_clock, color: Colors.white, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    'Modo de Consulta (Somente Leitura)',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // 🟢 WIDGET DO BALANCETE / RESUMO
  // ==========================================
  Widget _buildBalancete(List<MensalidadesModel> lista) {
    final int totalPessoas = lista.length;
    final int quantasPagaram =
        lista.where((m) => m.mes_data_pagamento.isNotEmpty).length;

    final double totalValorPago = lista.fold<double>(0.0, (soma, m) {
      if (m.mes_data_pagamento.isNotEmpty) {
        final double valor = double.tryParse(m.mes_valor.toString()) ?? 0.0;
        return soma + valor;
      }
      return soma;
    });

    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.indigo.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.indigo.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Text(
                'Total Pessoas',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                '$totalPessoas',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          Container(height: 24, width: 1, color: Colors.grey.shade400),
          Column(
            children: [
              const Text(
                'Pagaram',
                style: TextStyle(fontSize: 11, color: Colors.green),
              ),
              const SizedBox(height: 2),
              Text(
                '$quantasPagaram',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          Container(height: 24, width: 1, color: Colors.grey.shade400),
          Column(
            children: [
              const Text(
                'Total Pago',
                style: TextStyle(fontSize: 11, color: Colors.green),
              ),
              const SizedBox(height: 2),
              Text(
                generalService.currencyMoneyBr(totalValorPago.toString()),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.green,
                ),
              ),
            ],
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

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MonthlyPaymentsProfilePage(),
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

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MonthlyPaymentsCashierPage(),
          ),
        );
      }
    } catch (e) {
      debugPrint('monthlyPaymentsCashier error: $e');
    }
  }

  // ==========================================
  Widget _buildMensalidadeCard(MensalidadesModel mensalidade) {
    final bool isPago = mensalidade.mes_data_pagamento.isNotEmpty;
    final bool isConfirmado = mensalidade.mes_data_confirmacao.isNotEmpty;
    late bool isCancelado = false;
    if (!isPago && isConfirmado) {
      isCancelado = true;
    }

    // Validação de Mês/Ano Atual
    final now = DateTime.now();
    final int mesRef =
        int.tryParse(mensalidade.mes_mes_referencia.toString()) ?? 0;
    final int anoRef =
        int.tryParse(mensalidade.mes_ano_referencia.toString()) ?? 0;

    final bool isMesAnoAtual = (mesRef == now.month) && (anoRef == now.year);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: isPago
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    child: Icon(
                      isPago ? Icons.check_circle : Icons.pending_actions,
                      color: isPago ? Colors.green : Colors.orange,
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
            ),

            // COLUNA 1: DADOS DO SÓCIO
            Expanded(
              flex: 3,
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
                    'Valor Ref: ${generalService.currencyMoneyBr(mensalidade.vpg_valor_normal)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),

            const VerticalDivider(width: 16, thickness: 1),

            // COLUNA 2: DADOS DO PAGAMENTO
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPago ? Colors.green : Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 28),
                    ),
                    onPressed: isMesAnoAtual
                        ? () => monthlyPaymentsIndividual(mensalidade, context)
                        : null,
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
                      color: isCancelado ? Colors.redAccent : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Data: ${generalService.formatarDataBr(mensalidade.mes_data_pagamento)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isCancelado ? Colors.redAccent : Colors.grey[800],
                    ),
                  ),
                  Text(
                    'Forma: ${mensalidade.fpg_descricao}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isCancelado ? Colors.redAccent : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const VerticalDivider(width: 16, thickness: 1),

            // COLUNA 3: CONFIRMAÇÃO DO TESOUREIRO
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPago ? Colors.green : Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 28),
                    ),
                    onPressed: (isMesAnoAtual && isPago)
                        ? () => monthlyPaymentsCashier(mensalidade, context)
                        : null,
                    child: const Text(
                      'Cashier',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Date: ${isConfirmado || isCancelado ? generalService.formatarDataBr(mensalidade.mes_data_confirmacao) : ""}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Cashier: ${isConfirmado || isCancelado ? mensalidade.mes_full_name_confirmacao : ""}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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