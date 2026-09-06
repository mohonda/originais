import 'package:flutter/material.dart';
import 'package:originais/controllers/bd_monthlypayments_controller.dart';
import 'package:originais/controllers/bd_profile_controller.dart';
import 'package:originais/models/mensalidades_model.dart';
import 'package:originais/services/general_service.dart';
import 'package:originais/view/monthly_payments_profile_page.dart';

class ProfileMonthlyPayment extends StatefulWidget {
  const ProfileMonthlyPayment({super.key});

  @override
  State<ProfileMonthlyPayment> createState() => _ProfileMonthlyPaymentState();
}

class _ProfileMonthlyPaymentState extends State<ProfileMonthlyPayment> {
  final GeneralService generalService = GeneralService();
  late final BdMonthlyPaymentsController bdMonthlyPaymentsController;
  late final BdProfileController bdProfileController;

  late String pflId = '';
  late String hldId = '';

  @override
  void initState() {
    super.initState();
    bdMonthlyPaymentsController =
        getItbdMonthlyPaymentsController<BdMonthlyPaymentsController>();
    bdProfileController = getItBdProfileController<BdProfileController>();

    pflId = bdProfileController.pessoaSelecionadaNotifier.value?.pfl_id ?? '';
    hldId = bdProfileController.pessoaSelecionadaNotifier.value?.hld_id ?? '';

    // 🟢 1. Escuta atualizações da lista geral acionadas pelo Realtime
    bdMonthlyPaymentsController.monthlyPaymentsNotifier.addListener(
      _onRealtimeUpdate,
    );

    // 🟢 Busca SOMENTE os dados do perfil selecionado no banco
    _carregarMensalidadesPerfil();
  }

  @override
  void dispose() {
    // 🟢 Remove o listener para evitar vazamento de memória
    bdMonthlyPaymentsController.monthlyPaymentsNotifier.removeListener(
      _onRealtimeUpdate,
    );
    super.dispose();
  }

  void _onRealtimeUpdate() {
    // Sempre que chegar um evento do Realtime no controller, recarrega o perfil
    bdMonthlyPaymentsController.loadMonthlyPaymentsByProfile(pflId, hldId);
  }

  Future<void> _carregarMensalidadesPerfil() async {
    await bdMonthlyPaymentsController.loadMonthlyPaymentsByProfile(
      pflId,
      hldId,
    );
    bdMonthlyPaymentsController.initRealtime(hldId);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ValueListenableBuilder<bool>(
            valueListenable: bdMonthlyPaymentsController.loadingNotifier,
            builder: (context, isLoading, child) {
              if (isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              // 🟢 Ouve o Notifier exclusivo do perfil
              return ValueListenableBuilder<List<MensalidadesModel>>(
                valueListenable:
                    bdMonthlyPaymentsController.monthlyPaymentsProfileNotifier,
                builder: (context, listaDoUsuario, child) {
                  if (listaDoUsuario.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nenhuma mensalidade registrada para este usuário.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    );
                  }

                  // 🟢 ORDENAÇÃO CRONOLÓGICA (Mais recente primeiro)
                  final listaOrdenada =
                      List<MensalidadesModel>.from(listaDoUsuario)
                        ..sort((a, b) {
                          final dateA = DateTime(
                            int.tryParse(a.mes_ano_referencia) ?? 0,
                            int.tryParse(a.mes_mes_referencia) ?? 0,
                          );
                          final dateB = DateTime(
                            int.tryParse(b.mes_ano_referencia) ?? 0,
                            int.tryParse(b.mes_mes_referencia) ?? 0,
                          );
                          return dateB.compareTo(dateA);
                        });

                  return Column(
                    children: [
                      _buildResumoUsuario(listaOrdenada),

                      const SizedBox(height: 8),

                      Expanded(
                        child: ListView.builder(
                          itemCount: listaOrdenada.length,
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          itemBuilder: (context, index) {
                            return _buildMensalidadeUsuarioCard(
                              listaOrdenada[index],
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildResumoUsuario(List<MensalidadesModel> lista) {
    final int total = lista.length;
    final int pagas = lista
        .where((m) => m.mes_data_pagamento.isNotEmpty)
        .length;
    final int pendentes = total - pagas;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                'Total',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                '$total',
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
                'Pagas',
                style: TextStyle(fontSize: 11, color: Colors.green),
              ),
              const SizedBox(height: 2),
              Text(
                '$pagas',
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
                'Pendentes',
                style: TextStyle(fontSize: 11, color: Colors.orange),
              ),
              const SizedBox(height: 2),
              Text(
                '$pendentes',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMensalidadeUsuarioCard(MensalidadesModel mensalidade) {
    final bool isPago = mensalidade.mes_data_pagamento.isNotEmpty;
    final bool isConfirmado = mensalidade.mes_data_confirmacao.isNotEmpty;
    late bool isCancelado = false;
    if (!isPago && isConfirmado) {
      isCancelado = true;
    }

    final now = DateTime.now();
    final int mesRef =
        int.tryParse(mensalidade.mes_mes_referencia.toString()) ?? 0;
    final int anoRef =
        int.tryParse(mensalidade.mes_ano_referencia.toString()) ?? 0;
    final bool isMesAnoAtual = (mesRef == now.month) && (anoRef == now.year);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ref: ${mensalidade.mes_mes_referencia.toString().padLeft(2, '0')}/${mensalidade.mes_ano_referencia}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (isPago) ...[
                    Text(
                    'Valor Ref: ${generalService.currencyMoneyBr(mensalidade.mes_valor)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                    const SizedBox(height: 2),
                    Text(
                      'Pago em: ${generalService.formatarDataBr(mensalidade.mes_data_pagamento)} (${mensalidade.fpg_descricao})',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ] else ...[
                    const SizedBox(height: 2),
                    Text(
                      'Valor: ${generalService.currencyMoneyBr(mensalidade.vpg_valor_normal)}',
                      style: TextStyle(fontSize: 12, color:  isCancelado ? Colors.redAccent : Colors.grey[700]),                      
                    ),
                    if (isCancelado) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Payment canceled for the Cashier.',
                        style: TextStyle(fontSize: 12, color: Colors.redAccent),                      
                      ),                        
                    ]
                  ],
                ],
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isPago ? Colors.green : Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onPressed: isMesAnoAtual
                  ? () => _abrirPagamentoPerfil(mensalidade)
                  : null,
              icon: const Icon(Icons.payment, size: 16),
              label: Text(
                isPago ? 'Detalhes' : 'Pagar',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirPagamentoPerfil(MensalidadesModel mensalidade) async {
    try {
      await bdMonthlyPaymentsController.loadMonthlyPaymentsIndividual(
        mensalidade.mes_pfl_id,
        mensalidade.mes_mes_referencia,
        mensalidade.mes_ano_referencia,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MonthlyPaymentsProfilePage(),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error ao abrir MonthlyPaymentsProfilePage: $e');
    }
  }
}
