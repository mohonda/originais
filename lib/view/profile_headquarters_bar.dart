import 'package:flutter/material.dart';
import 'package:originais/controllers/profile_controller.dart';
import 'package:originais/controllers/ticket_controller.dart';
import 'package:originais/models/ticket_model.dart';
import 'package:originais/services/general_service.dart';
import 'package:originais/controllers/ticket_receipt_image_service.dart'; // 🟢 Serviço de upload adicionado

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

  // 🟢 Controladores de estado do serviço de imagem
  final loadingNotifier = ValueNotifier<bool>(false);
  final errorNotifier = ValueNotifier<String?>(null);
  late final TicketReceiptImageService paymentService;

  bool _isLoading = true;
  String _pflIdResolvido = '';
  String _hldIdResolvido = '';

  @override
  void initState() {
    super.initState();
    ticketController = getItTicketController<TicketController>();
    generalService = getItGeneralService<GeneralService>();
    profileController = getItBdProfileController<BdProfileController>();

    // 🟢 Inicializa o serviço de upload de imagens
    paymentService = TicketReceiptImageService(
      loadingNotifier: loadingNotifier,
      errorNotifier: errorNotifier,
    );

    // 🟢 Escuta mudanças caso o perfil demore para carregar no controller global
    profileController.pessoaSelecionadaNotifier.addListener(_onPessoaChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarDados();
    });
  }

  @override
  void dispose() {
    profileController.pessoaSelecionadaNotifier.removeListener(
      _onPessoaChanged,
    );
    ticketController.disposeRealtimeProfile();
    loadingNotifier.dispose();
    errorNotifier.dispose();
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
      await ticketController.loadTicketsByProfileWithItems(
        _pflIdResolvido,
        _hldIdResolvido,
      );
      ticketController.initRealtimeProfile(_pflIdResolvido, _hldIdResolvido);
    } catch (e) {
      debugPrint('❌ Erro ao buscar tickets: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 🟢 Função para recuperar o ID do status "Pago"
  String id_ticketStatusList(String name) {
    try {
      final tmp = ticketController.ticketStatusNotifier.value
          .where((c) => c.tst_name == name)
          .firstOrNull
          ?.tst_id;
      return tmp.toString();
    } catch (e) {
      return '';
    }
  }

  // 🟢 Novo fluxo de Pagamento via Modal de Upload
  // void _irParaPagamento(BuildContext context, TicketsModel ticket) async {
  //   showDialog(
  //     context: context,
  //     builder: (dialogContext) {
  //       return StatefulBuilder(
  //         builder: (context, setDialogState) {
  //           final bool temFoto = ticket.tkt_paiment_path != null;

  //           return AlertDialog(
  //             shape: RoundedRectangleBorder(
  //               borderRadius: BorderRadius.circular(16),
  //             ),
  //             title: Text('Pagamento: ${ticket.tkt_table_number}'),
  //             content: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   'Total a pagar: ${generalService.currencyMoneyBr(ticket.totalConsumo.toString())}\n\n'
  //                   'Comprovante/Foto confirma seu pagamento!!!',
  //                 ),
  //                 const SizedBox(height: 16),

  //                 // 📸 Botão para capturar ou escolher a foto do comprovante
  //                 SizedBox(
  //                   width: double.infinity,
  //                   child: OutlinedButton.icon(
  //                     onPressed: () async {
  //                       final tst_id = id_ticketStatusList(
  //                         'Ticket closed (Paid)',
  //                       );

  //                       await paymentService.selecionarAnexoEEnviar(
  //                         context: context,
  //                         payload: {
  //                           'tkt_id': ticket.tkt_id,
  //                           'pfl_id': ticket.tkt_pfl_id,
  //                           'tkt_tst_id': ticket.tkt_tst_id,
  //                           'barId': ticket.tkt_bar_id,
  //                           'openDate': ticket.tkt_bar_open_date,
  //                           'hld_id': widget.hldId,
  //                         },
  //                       );
  //                       if (context.mounted && errorNotifier.value == null) {
  //                         Navigator.of(
  //                           context,
  //                         ).pop(); // Fecha o Dialog da comanda
  //                       }
  //                     },
  //                     icon: const Icon(
  //                       Icons.add_a_photo,
  //                       color: Colors.orangeAccent,
  //                     ),
  //                     label: const Text(
  //                       'Anexar Comprovante / Foto',
  //                       style: TextStyle(
  //                         color: Colors.orangeAccent,
  //                         fontWeight: FontWeight.bold,
  //                       ),
  //                     ),
  //                     style: OutlinedButton.styleFrom(
  //                       side: const BorderSide(color: Colors.indigoAccent),
  //                       padding: const EdgeInsets.symmetric(vertical: 12),
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             actions: [
  //               TextButton(
  //                 onPressed: () => Navigator.pop(dialogContext),
  //                 child: const Text('Cancelar'),
  //               ),
  //             ],
  //           );
  //         },
  //       );
  //     },
  //   );
  // }
// 🟢 Fluxo de Pagamento via Modal de Upload com Confirmação para tss_id == '2'
  void _irParaPagamento(BuildContext context, TicketsModel ticket) async {
    final bool isTipo2 = ticket.bar_tss_id == '2';

    // Estado inicial de Data e Valor
    DateTime dataPagamento = DateTime.tryParse(ticket.tkt_bar_open_date) ?? DateTime.now();
    double valorFinal = double.tryParse(ticket.totalConsumo.toString()) ?? 0.0;

    final TextEditingController valorController = TextEditingController(
      text: valorFinal.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Pagamento: ${ticket.tkt_table_number.isNotEmpty ? ticket.tkt_table_number : 'Ticket #${ticket.tkt_id}'}',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isTipo2) ...[
                      Text(
                        'Total a pagar: ${generalService.currencyMoneyBr(ticket.totalConsumo.toString())}\n\n'
                        'Comprovante/Foto confirma seu pagamento!!!',
                      ),
                    ] else ...[
                      const Text(
                        'Confirme a data e o valor do pagamento antes de anexar o comprovante:',
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                      const SizedBox(height: 16),

                      // 📅 1. Campo de Seleção da Data do Pagamento
                      InkWell(
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: dataPagamento,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            setDialogState(() {
                              dataPagamento = pickedDate;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Data do Pagamento',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today, size: 20),
                          ),
                          child: Text(
                            '${dataPagamento.day.toString().padLeft(2, '0')}/${dataPagamento.month.toString().padLeft(2, '0')}/${dataPagamento.year}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 💵 2. Campo de Valor do Pagamento
                      TextField(
                        controller: valorController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Valor do Pagamento (R\$)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money, size: 20),
                        ),
                        onChanged: (val) {
                          final parsed = double.tryParse(val.replaceAll(',', '.'));
                          if (parsed != null) {
                            valorFinal = parsed;
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Comprovante/Foto confirma seu pagamento!',
                        style: TextStyle(fontSize: 12, color: Colors.white54),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // 📸 Botão para capturar ou escolher a foto do comprovante
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          // Formatação da data escolhida em YYYY-MM-DD
                          final String dataFormatada =
                              '${dataPagamento.year}-${dataPagamento.month.toString().padLeft(2, '0')}-${dataPagamento.day.toString().padLeft(2, '0')}';

                          final payload = {
                            'tkt_id': ticket.tkt_id,
                            'pfl_id': ticket.tkt_pfl_id,
                            'tkt_tst_id': ticket.tkt_tst_id,
                            'barId': ticket.tkt_bar_id,
                            'openDate': isTipo2 ? dataFormatada : ticket.tkt_bar_open_date,
                            'valor': isTipo2 ? valorFinal : ticket.totalConsumo,
                            'hld_id': widget.hldId,
                          };

                          await paymentService.selecionarAnexoEEnviar(
                            context: context,
                            payload: payload,
                          );

                          if (context.mounted && errorNotifier.value == null) {
                            Navigator.of(context).pop(); // Fecha o Dialog da comanda
                          }
                        },
                        icon: const Icon(
                          Icons.add_a_photo,
                          color: Colors.orangeAccent,
                        ),
                        label: const Text(
                          'Anexar Comprovante / Foto',
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.indigoAccent),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 🟢 Conteúdo Principal da Tela
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          ValueListenableBuilder<List<TicketsModel>>(
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
          ),

        // 🟢 Overlay de Carregamento para o Upload
        ValueListenableBuilder<bool>(
          valueListenable: loadingNotifier,
          builder: (context, isLoading, child) {
            if (!isLoading) return const SizedBox.shrink();
            return Container(
              color: Colors.black54, // Fundo escuro semi-transparente
              child: const Center(child: CircularProgressIndicator()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildResumoUsuario(List<TicketsModel> lista) {
    final int total = lista.length;

    final int pagos = lista.where((t) {
      final temComprovante =
          t.tkt_paiment_path != null && t.tkt_paiment_path!.trim().isNotEmpty;
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
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white54),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTicketCard(BuildContext context, TicketsModel ticket) {
    final bool temItens = ticket.ticketsItems.isNotEmpty;
    final bool temComprovante =
        ticket.tkt_paiment_path != null &&
        ticket.tkt_paiment_path!.trim().isNotEmpty;
    final bool isPago =
        ticket.tst_name == 'Ticket closed (Paid)' || temComprovante;
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
          (ticket.bar_tss_id == '1')
              ? Icons.confirmation_number_outlined
              : (ticket.bar_tss_id == '2'
                    ? Icons.calendar_month
                    : (ticket.bar_tss_id == '3'
                          ? Icons.gavel_outlined
                          : Icons.view_cozy)),
          color: isCancelado
              ? Colors.redAccent
              : (isPago
                    ? Colors.greenAccent
                    : (ticket.tkt_has_discount
                          ? Colors.amber
                          : Colors.indigoAccent)),
        ),
        title: Row(
          children: [
            Text(
              ticket.tkt_table_number.isNotEmpty
                  ? ticket.tkt_table_number
                  : 'Ticket #${ticket.tkt_id}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(width: 8),
            _buildStatusBadge(ticket),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            'Sales: ${ticket.tss_desc} • Data: ${generalService.formatarDataBr(ticket.tkt_bar_open_date)} • Total: ${generalService.currencyMoneyBr(ticket.totalConsumo.toString())}',
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
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                if (!temItens)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Nenhum item registrado neste ticket.',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
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
                                Text(
                                  item.pdt_name.toString(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${item.tit_quantities}x ${generalService.currencyMoneyBr(item.tit_unit_value.toString())}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            generalService.currencyMoneyBr(
                              item.tit_value.toString(),
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.greenAccent,
                            ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                        ),
                        onPressed: () => _irParaPagamento(context, ticket),
                        icon: const Icon(Icons.payment, size: 16),
                        label: const Text(
                          'Pagar Agora',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
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

  Widget _buildStatusBadge(TicketsModel ticket) {
    String label = 'ABERTO';
    Color color = Colors.orangeAccent;
    Color bgColor = Colors.orange.withValues(alpha: 0.15);

    final bool temComprovante =
        ticket.tkt_paiment_path != null &&
        ticket.tkt_paiment_path!.trim().isNotEmpty;

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
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
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
