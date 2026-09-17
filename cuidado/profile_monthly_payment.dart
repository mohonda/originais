import 'package:flutter/material.dart';
import 'package:originais/controllers/monthly_payments_controller.dart';
import 'package:originais/controllers/profile_controller.dart';
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

    // Escuta atualizações via Realtime
    bdMonthlyPaymentsController.monthlyPaymentsNotifier.addListener(
      _onRealtimeUpdate,
    );

    _carregarMensalidadesPerfil();
  }

  @override
  void dispose() {
    bdMonthlyPaymentsController.monthlyPaymentsNotifier.removeListener(
      _onRealtimeUpdate,
    );
    super.dispose();
  }

  void _onRealtimeUpdate() {
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
    return ValueListenableBuilder<bool>(
      valueListenable: bdMonthlyPaymentsController.loadingNotifier,
      builder: (context, isLoading, child) {
        if (isLoading) {
          return const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return ValueListenableBuilder<List<MensalidadesModel>>(
          valueListenable:
              bdMonthlyPaymentsController.monthlyPaymentsProfileNotifier,
          builder: (context, listaDoUsuario, child) {
            if (listaDoUsuario.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    'Nenhuma mensalidade registrada para este usuário.',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),
              );
            }

            // Ordenação cronológica (Mais recente primeiro)
            final listaOrdenada = List<MensalidadesModel>.from(listaDoUsuario)
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

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 📊 Resumo do Usuário
                  _buildResumoUsuario(listaOrdenada),

                  const SizedBox(height: 12),

                  // 📋 Lista de Mensalidades
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: listaOrdenada.length,
                    itemBuilder: (context, index) {
                      return _buildMensalidadeUsuarioCard(
                        listaOrdenada[index],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 📊 Card de Resumo
  Widget _buildResumoUsuario(List<MensalidadesModel> lista) {
    final int total = lista.length;
    final int pagas =
        lista.where((m) => m.mes_data_pagamento.isNotEmpty).length;
    final int pendentes = total - pagas;

    final double totalPago = lista.fold<double>(0.0, (soma, m) {
      if (m.mes_data_pagamento.isNotEmpty) {
        final double valor = double.tryParse(m.mes_valor.toString()) ?? 0.0;
        return soma + valor;
      }
      return soma;
    });

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.indigo.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildResumoColumn('Total', '$total', Colors.white70),
          Container(height: 24, width: 1, color: Colors.white24),
          _buildResumoColumn('Pagas', '$pagas', Colors.greenAccent),
          Container(height: 24, width: 1, color: Colors.white24),
          _buildResumoColumn('Pendentes', '$pendentes', Colors.orangeAccent),
          Container(height: 24, width: 1, color: Colors.white24),
          _buildResumoColumn(
            'Total Pago',
            generalService.currencyMoneyBr(totalPago.toString()),
            Colors.indigoAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildResumoColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
        ),
      ],
    );
  }

  // 📋 Card Individual da Mensalidade
  Widget _buildMensalidadeUsuarioCard(MensalidadesModel mensalidade) {
    final bool isPago = mensalidade.mes_data_pagamento.isNotEmpty;
    final bool isConfirmado = mensalidade.mes_data_confirmacao.isNotEmpty;
    final bool isCancelado = !isPago && isConfirmado;

    final now = DateTime.now();
    final int mesRef = int.tryParse(mensalidade.mes_mes_referencia.toString()) ?? 0;
    final int anoRef = int.tryParse(mensalidade.mes_ano_referencia.toString()) ?? 0;
    final bool isMesAnoAtual = (mesRef == now.month) && (anoRef == now.year);

    final String valorExibicao = isPago
        ? generalService.currencyMoneyBr(mensalidade.mes_valor)
        : generalService.currencyMoneyBr(mensalidade.vpg_valor_normal);

    final String refFormatada =
        'Ref: ${mensalidade.mes_mes_referencia.toString().padLeft(2, '0')}/${mensalidade.mes_ano_referencia}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.indigo.withValues(alpha: 0.3), width: 1),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
          Icons.calendar_month_outlined,
          color: isCancelado
              ? Colors.redAccent
              : (isPago ? Colors.greenAccent : Colors.orangeAccent),
        ),
        title: Row(
          children: [
            Text(
              refFormatada,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(width: 8),
            _buildStatusBadge(isPago, isCancelado),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            'Valor: $valorExibicao',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ),
        children: [
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.all(12.0),
            color: Colors.black12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPago) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pago em:',
                        style: TextStyle(fontSize: 12, color: Colors.white54),
                      ),
                      Text(
                        generalService.formatarDataBr(mensalidade.mes_data_pagamento),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
                      ),
                    ],
                  ),
                  if (mensalidade.fpg_descricao.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Forma de Pagamento:',
                          style: TextStyle(fontSize: 12, color: Colors.white54),
                        ),
                        Text(
                          mensalidade.fpg_descricao,
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ] else if (isCancelado) ...[
                  const Text(
                    'Pagamento cancelado para o Caixa.',
                    style: TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Valor Normal:',
                        style: TextStyle(fontSize: 12, color: Colors.white54),
                      ),
                      Text(
                        valorExibicao,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),

                // 🔘 Botão de Ação
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPago ? Colors.indigo : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: isMesAnoAtual
                          ? () => _abrirPagamentoPerfil(mensalidade)
                          : null,
                      icon: Icon(isPago ? Icons.visibility : Icons.payment, size: 16),
                      label: Text(
                        isPago ? 'Detalhes' : 'Pagar Agora',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🏷️ Badge de Status
  Widget _buildStatusBadge(bool isPago, bool isCancelado) {
    String label = 'PENDENTE';
    Color color = Colors.orangeAccent;
    Color bgColor = Colors.orange.withValues(alpha: 0.15);

    if (isPago) {
      label = 'PAGO';
      color = Colors.greenAccent;
      bgColor = Colors.green.withValues(alpha: 0.15);
    } else if (isCancelado) {
      label = 'CANCELADO';
      color = Colors.redAccent;
      bgColor = Colors.red.withValues(alpha: 0.15);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
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
      debugPrint('Erro ao abrir MonthlyPaymentsProfilePage: $e');
    }
  }
}