import 'package:flutter/material.dart';
import 'package:originais/controllers/profile_controller.dart';
import 'package:originais/controllers/ticket_controller.dart';
import 'package:originais/models/ticket_model.dart';
import 'package:originais/services/general_service.dart';
import 'package:originais/view/headquartersbar_opened.dart';

class ProfileHeadquartersBar extends StatefulWidget {
  final String pflId;
  final String hldId;
  /// Data atual do caixa/bar aberto (Ex: "YYYY-MM-DD").
  final String? currentOpenDate;

  const ProfileHeadquartersBar({
    super.key,
    required this.pflId,
    required this.hldId,
    this.currentOpenDate,
  });

  @override
  State<ProfileHeadquartersBar> createState() => _ProfileHeadquartersBarState();
}

class _ProfileHeadquartersBarState extends State<ProfileHeadquartersBar> {
  late final TicketController ticketController;
  late final GeneralService generalService;
  late final BdProfileController profileController;

  bool _isLoading = true;
  String _pflIdResolvido = '';
  String _hldIdResolvido = '';

  @override
  void initState() {
    super.initState();
    ticketController = getItTicketController<TicketController>();
    generalService = getItGeneralService<GeneralService>();
    profileController = getItBdProfileController<BdProfileController>();

    // 🟢 Escuta mudanças caso o perfil demore para carregar no controller global
    profileController.pessoaSelecionadaNotifier.addListener(_onPessoaChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarDados();
    });
  }

  @override
  void dispose() {
    profileController.pessoaSelecionadaNotifier.removeListener(_onPessoaChanged);
    ticketController.disposeRealtimeProfile();
    super.dispose();
  }

  void _onPessoaChanged() {
    if (_pflIdResolvido.isEmpty) {
      _carregarDados();
    }
  }

  @override
  void didUpdateWidget(covariant ProfileHeadquartersBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pflId != widget.pflId || oldWidget.hldId != widget.hldId) {
      _carregarDados();
    }
  }

  Future<void> _carregarDados() async {
    final pessoaLogada = profileController.pessoaSelecionadaNotifier.value;

    // 🟢 Resolve dinamicamente os IDs (prioriza o Widget, senão busca do Perfil Logado)
    final String idResolvido = widget.pflId.isNotEmpty 
        ? widget.pflId 
        : (pessoaLogada?.pfl_id?.toString() ?? '');

    final String hldResolvido = widget.hldId.isNotEmpty 
        ? widget.hldId 
        : (pessoaLogada?.hld_id?.toString() ?? '');

    if (idResolvido.isEmpty) {
      debugPrint('⚠️ ProfileHeadquartersBar: pflId ainda não está disponível.');
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _pflIdResolvido = idResolvido;
    _hldIdResolvido = hldResolvido;

    if (mounted) setState(() => _isLoading = true);

    try {
      // debugPrint('🔍 Buscando tickets no banco para pflId: $_pflIdResolvido, hldId: $_hldIdResolvido');
      
      await ticketController.loadTicketsByProfileWithItems(_pflIdResolvido, _hldIdResolvido);
      ticketController.initRealtimeProfile(_pflIdResolvido, _hldIdResolvido);
      
      debugPrint('✅ Tickets retornados: ${ticketController.profileTicketsWithItemsNotifier.value.length}');
    } catch (e) {
      debugPrint('❌ Erro ao buscar tickets: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

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
              _buildResumoUsuario(tickets),
              const SizedBox(height: 12),
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

  Widget _buildTicketCard(BuildContext context, TicketsModel ticket) {
    final bool temItens = ticket.ticketsItems.isNotEmpty;
    final bool temComprovante = ticket.tkt_paiment_path != null && ticket.tkt_paiment_path!.trim().isNotEmpty;
    final bool isPago = ticket.tst_name == 'Ticket closed (Paid)' || temComprovante;
    final bool isCancelado = ticket.tst_name == 'Ticket closed without payment';

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
          color: isCancelado
              ? Colors.redAccent
              : (isPago ? Colors.greenAccent : (ticket.tkt_has_discount ? Colors.amber : Colors.indigoAccent)),
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
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (temComprovante)
                      OutlinedButton.icon(
                        onPressed: () => _mostrarComprovante(context, ticket),
                        icon: const Icon(Icons.image_search, size: 16),
                        label: const Text('Ver Comprovante'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orangeAccent,
                          side: const BorderSide(color: Colors.orangeAccent),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    if (!isPago && !isCancelado)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        onPressed: () => _irParaPagamento(context, ticket),
                        icon: const Icon(Icons.payment, size: 16),
                        label: const Text('Pagar Agora', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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

  void _irParaPagamento(BuildContext context, TicketsModel ticket) async {
    final String barOpenDate = widget.currentOpenDate ?? ticket.tkt_bar_open_date;

    if (widget.currentOpenDate != null && ticket.tkt_bar_open_date != widget.currentOpenDate) {
      final bool? confirmar = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Comanda de Data Anterior', style: TextStyle(fontSize: 16)),
          content: Text(
            'Esta comanda é do dia ${generalService.formatarDataBr(ticket.tkt_bar_open_date)}.\n\n'
            'Deseja realizar o pagamento no caixa ativo do dia ${generalService.formatarDataBr(widget.currentOpenDate!)}?',
            style: const TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Prosseguir'),
            ),
          ],
        ),
      );

      if (confirmar != true) return;
    }

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HeadquartersBarOpened(
          ticketSelecionado: ticket,
          barId: ticket.tkt_bar_id,
          openDate: barOpenDate,
          hld_id: widget.hldId,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(TicketsModel ticket) {
    String label = 'ABERTO';
    Color color = Colors.orangeAccent;
    Color bgColor = Colors.orange.withValues(alpha: 0.15);

    final bool temComprovante = ticket.tkt_paiment_path != null && ticket.tkt_paiment_path!.trim().isNotEmpty;

    if (ticket.tst_name == 'Ticket closed (Paid)' || temComprovante) {
      label = 'PAGO';
      color = Colors.greenAccent;
      bgColor = Colors.green.withValues(alpha: 0.15);
    } else if (ticket.tst_name == 'Ticket closed without payment') {
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

  void _mostrarComprovante(BuildContext context, TicketsModel ticket) {
    final String imageUrl = ticket.tkt_paiment_path!;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Comprovante - ${ticket.tkt_table_number}',
          style: const TextStyle(fontSize: 16),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Text(
                        'Erro ao carregar imagem do comprovante.',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}