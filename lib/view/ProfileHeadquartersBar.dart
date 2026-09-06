import 'package:flutter/material.dart';
import 'package:originais/controllers/ticketController.dart';
import 'package:originais/models/ticketModel.dart';
import 'package:originais/services/general_service.dart';

class ProfileHeadquartersBar extends StatefulWidget {
  final String pflId;
  final String hldId;

  const ProfileHeadquartersBar({
    super.key,
    required this.pflId,
    required this.hldId,
  });

  @override
  State<ProfileHeadquartersBar> createState() => _ProfileHeadquartersBarState();
}

class _ProfileHeadquartersBarState extends State<ProfileHeadquartersBar> {
  late final TicketController ticketController;
  late final GeneralService generalService;

  @override
  void initState() {
    super.initState();
    ticketController = getItTicketController<TicketController>();
    generalService = getItGeneralService<GeneralService>();

    // 🟢 1. Carrega os dados iniciais do usuário atual
    _carregarEIniciarRealtime();
  }

  Future<void> _carregarEIniciarRealtime() async {
    await ticketController.loadTicketsByProfileWithItems(widget.pflId, widget.hldId);
    // 🟢 2. Ativa o canal Realtime para este perfil
    ticketController.initRealtime(widget.pflId, widget.hldId);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<TicketsModel>>(
      valueListenable: ticketController.profileTicketsWithItemsNotifier,
      builder: (context, tickets, child) {
        if (tickets.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                'Nenhum ticket encontrado para este perfil.',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📊 Resumo de Consumo e Totais (atualiza automaticamente com o Notifier)
              _buildResumoUsuario(tickets),

              const SizedBox(height: 12),

              // 📋 Lista de Tickets / Comandas
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tickets.length,
                itemBuilder: (context, index) {
                  return _buildTicketCard(context, tickets[index]);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 📊 Card de Resumo e Totais
  Widget _buildResumoUsuario(List<TicketsModel> lista) {
    final int total = lista.length;

    final int pagos = lista.where((t) {
      final temComprovante = t.tkt_paiment_path != null && t.tkt_paiment_path!.trim().isNotEmpty;
      final isPagoStatus = t.tst_name == 'Ticket closed (Paid)';
      return temComprovante || isPagoStatus;
    }).length;

    final int pendentes = total - pagos;

    final double totalGasto = lista.fold<double>(0.0, (soma, t) {
      final double valor = double.tryParse(t.totalConsumo.toString()) ?? 0.0;
      return soma + valor;
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
          _buildResumoColumn('Total Tickets', '$total', Colors.white70),
          Container(height: 24, width: 1, color: Colors.white24),
          _buildResumoColumn('Pagos', '$pagos', Colors.greenAccent),
          Container(height: 24, width: 1, color: Colors.white24),
          _buildResumoColumn('Pendentes', '$pendentes', Colors.orangeAccent),
          Container(height: 24, width: 1, color: Colors.white24),
          _buildResumoColumn(
            'Total Consumido',
            generalService.currencyMoneyBr(totalGasto.toString()),
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

  // Card individual do Ticket
  Widget _buildTicketCard(BuildContext context, TicketsModel ticket) {
    final bool temItens = ticket.ticketsItems.isNotEmpty;
    final bool temComprovante = ticket.tkt_paiment_path != null && ticket.tkt_paiment_path!.trim().isNotEmpty;

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
          Icons.confirmation_number_outlined,
          color: ticket.tkt_has_discount ? Colors.amber : Colors.indigoAccent,
        ),
        title: Row(
          children: [
            Text(
              ticket.tkt_table_number.isNotEmpty ? ticket.tkt_table_number : 'Ticket #${ticket.tkt_id}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(width: 8),
            _buildStatusBadge(ticket),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            'Data: ${generalService.formatarDataBr(ticket.tkt_bar_open_date)} • Total: ${generalService.currencyMoneyBr(ticket.totalConsumo.toString())}',
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
                const Text(
                  'Itens Consumidos:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                if (!temItens)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Nenhum item registrado neste ticket.',
                      style: TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: ticket.ticketsItems.length,
                    separatorBuilder: (_, _) => const Divider(height: 8),
                    itemBuilder: (context, idx) {
                      final item = ticket.ticketsItems[idx];
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.pdt_name.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                Text(
                                  '${item.tit_quantities}x ${generalService.currencyMoneyBr(item.tit_unit_value.toString())}',
                                  style: const TextStyle(fontSize: 11, color: Colors.white54),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            generalService.currencyMoneyBr(item.tit_value.toString()),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TicketsModel ticket) {
    String label = 'ABERTO';
    Color color = Colors.orangeAccent;
    Color bgColor = Colors.orange.withValues(alpha: 0.15);

    if (ticket.tkt_paiment_path != null && ticket.tkt_paiment_path!.isNotEmpty) {
      label = 'PAGO';
      color = Colors.greenAccent;
      bgColor = Colors.green.withValues(alpha: 0.15);
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
}