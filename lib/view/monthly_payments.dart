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
    bdMonthlyPaymentsController =
        getItbdMonthlyPaymentsController<BdMonthlyPaymentsController>();

    super.initState();
  }

  // ==========================================
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

              // // 1. Extrai e ordena os meses/anos únicos disponíveis na lista
              // final listaMesAno = lista
              //     .map((m) => '${m.mes_mes_referencia.toString().padLeft(2, '0')}/${m.mes_ano_referencia}')
              //     .toSet()
              //     .toList()..sort((a, b) => b.compareTo(a)); // Mais recentes primeiro

              // 1. Extrai os meses/anos únicos
              final listaMesAno = lista
                  .map(
                    (m) =>
                        '${m.mes_mes_referencia.toString().padLeft(2, '0')}/${m.mes_ano_referencia}',
                  )
                  .toSet()
                  .toList();

              // 2. Ordena cronologicamente por Ano e Mês (do mais recente para o mais antigo)
              listaMesAno.sort((a, b) {
                final partsA = a.split('/'); // [MM, AAAA]
                final partsB = b.split('/'); // [MM, AAAA]

                final dateA = DateTime(
                  int.parse(partsA[1]),
                  int.parse(partsA[0]),
                );
                final dateB = DateTime(
                  int.parse(partsB[1]),
                  int.parse(partsB[0]),
                );

                return dateB.compareTo(
                  dateA,
                ); // Troque para dateA.compareTo(dateB) se preferir a ordem antiga -> recente
              });

              return DefaultTabController(
                length: listaMesAno.length,
                child: Column(
                  children: [
                    Row(
                      children: [
                        // 1. As abas de mês/ano ocupam a maior parte da linha
                        Expanded(
                          child: TabBar(
                            isScrollable: true,
                            tabAlignment: TabAlignment.start,
                            tabs: listaMesAno
                                .map((mesAno) => Tab(text: 'Ref: $mesAno'))
                                .toList(),
                          ),
                        ),

                        // 2. Ícone discreto de filtro no canto direito
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

                    // 4. CONTEÚDO DAS LISTAS POR MÊS/ANO
                    Expanded(
                      child: TabBarView(
                        children: listaMesAno.map((mesAnoRef) {
                          // Filtra os itens do mês específico da aba + status selecionado
                          final listaFiltrada = lista.where((m) {
                            final refAtual =
                                '${m.mes_mes_referencia.toString().padLeft(2, '0')}/${m.mes_ano_referencia}';
                            if (refAtual != mesAnoRef) return false;

                            final nomeMatch = m.pfl_full_name
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase());
                            final isPago = m.mes_data_pagamento.isNotEmpty;

                            if (_filtroStatus == 'Pagas')
                              return nomeMatch && isPago;
                            if (_filtroStatus == 'Pendentes')
                              return nomeMatch && !isPago;
                            return nomeMatch;
                          }).toList();

                          if (listaFiltrada.isEmpty) {
                            return const Center(
                              child: Text('Nenhum registro para este filtro.'),
                            );
                          }

                          return ListView.builder(
                            itemCount: listaFiltrada.length,
                            padding: const EdgeInsets.all(8.0),
                            itemBuilder: (context, index) {
                              return _buildMensalidadeCard(
                                listaFiltrada[index],
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
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
            builder: (context) => const MonthlyPaymentsProfile(),
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
            builder: (context) => const MonthlyPaymentsCashier(),
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
    if (!isPago && isConfirmado) {
      isCancelado = true;
    }

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
                    'Valor Ref: ${generalService.currencyMoneyBr(mensalidade.vpg_valor_normal)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
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
                      backgroundColor: isPago ? Colors.green : Colors.orange,
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
                      color: isCancelado ? Colors.redAccent : Colors.white,
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
            // ================= COLUNA 3: CONFIRMAÇÃO DO TESOUREIRO =================
            Expanded(
              flex: 2, // Ocupa 2/8 do espaço horizontal
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
                    onPressed: () => {
                      isPago
                          ? monthlyPaymentsCashier(mensalidade, context)
                          : (),
                    },
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
