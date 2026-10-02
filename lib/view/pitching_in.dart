import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:originais/services/general_service.dart';
import 'package:originais/view/default_appbar.dart';
import 'package:originais/controllers/monthly_payments_controller.dart';
import 'package:originais/controllers/payment_value_controller.dart';
import 'package:originais/controllers/profile_controller.dart';
import 'package:originais/controllers/ticket_controller.dart';
import 'package:originais/controllers/headquarters_bar_controller.dart';
import 'package:originais/controllers/products_controller.dart';
import 'package:originais/controllers/ticket_receipt_image_service.dart';
import 'package:originais/models/vprofile_model.dart';
import 'package:originais/models/products_model.dart';
import 'package:originais/models/ticket_model.dart';
import 'package:originais/view/default_snackbar.dart';

class PitchingIn extends StatefulWidget {
  final String? hldId;
  const PitchingIn({
    super.key,
    this.hldId,
  });

  @override
  State<PitchingIn> createState() => _PitchingInState();
}

class _PitchingInState extends State<PitchingIn> {
  final GeneralService generalService = GeneralService();
  late final BdMonthlyPaymentsController bdMonthlyPaymentsController;
  late final BdPaymentValueController bdPaymentValueController;
  late final BdProfileController bdProfileController;

  late final BdHeadquartersBarController barController;
  late final ProductsController productsController;

  final String tssId = '4';

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt', 'BR');

    bdMonthlyPaymentsController =
        getItbdMonthlyPaymentsController<BdMonthlyPaymentsController>();
    bdPaymentValueController =
        getItBdPaymentValueController<BdPaymentValueController>();
    bdProfileController =
        getItBdProfileController<BdProfileController>();
    barController =
        getItBdHeadquartersBarController<BdHeadquartersBarController>();
    productsController =
        getItProductsController<ProductsController>();

    DefaultSnackbar.attachErrorListener(
      context,
      barController.errorNotifier,
    );

    DefaultSnackbar.attachSuccessListener(
      context,
      barController.successNotifier,
    );

    loadData();
  }

  void loadData() {
    barController.loadHeadquartersBar(widget.hldId.toString(), tssId);
  }

  @override
  void dispose() {
    bdMonthlyPaymentsController.disposeRealtime();
    super.dispose();
  }

  void _abrirDialogAdicionarBar() async {
    await bdProfileController.loadProfiles('1');
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AddPitchingInDialog(
        bdProfileController: bdProfileController,
        onConfirm: (DateTime data, VProfileModel? profile, String pix) async {
          await barController.openHeadquartersBar(
            profile!.pfl_id.toString(),
            widget.hldId.toString(),
            data.toString(),
            pix.toString(),
            tssId,
          );
          loadData();

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registro adicionado com sucesso!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  void _abrirDialogEditarBar(dynamic item, bool temComprovante, bool jaGerouTickets) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _EditPitchingInDialog(
        item: item,
        hasReceipt: temComprovante,
        jaGerouTickets: jaGerouTickets,
        onSave: (DateTime novaData, String novoPix) async {
          final String barId = item.bar_id.toString();

          await barController.updateHeadquartersBar(
            barId,
            novaData.toString(),
            novoPix,
          );
          loadData();
        },
        onDelete: () async {
          final String barId = item.bar_id.toString();

          await barController.deleteBar(barId);
          loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DefaultAppbar(title: 'Pitching in'),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addPitchingInFab',
        elevation: 2,
        backgroundColor: Colors.indigo,
        onPressed: _abrirDialogAdicionarBar,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          barController.loadingNotifier,
          barController.errorNotifier,
          barController.headquartersBarNotifier,
        ]),
        builder: (context, _) {
          final isLoading = barController.loadingNotifier.value;
          final errorMessage = barController.errorNotifier.value;
          final lista = barController.headquartersBarNotifier.value;

          return Stack(
            children: [
              if (isLoading && lista.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (errorMessage != null &&
                  errorMessage.isNotEmpty &&
                  lista.isEmpty)
                _buildErrorState(errorMessage)
              else if (lista.isEmpty)
                _buildEmptyState()
              else
                _buildListContent(lista),

              if (isLoading && lista.isNotEmpty)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: Center(
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 16.0,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(width: 16),
                              Text(
                                'Processando...',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'Nenhum registro encontrado.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Atualizar'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.redAccent),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListContent(List<dynamic> lista) {
    return RefreshIndicator(
      onRefresh: () async => loadData(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: lista.length,
        itemBuilder: (context, index) {
          final item = lista[index];
          final String barId = (item.bar_id ?? item.hqb_id ?? index).toString();
          return _BarItemCard(
            key: ValueKey(barId),
            item: item,
            hldId: widget.hldId,
            productsController: productsController,
            onEditBar: (bool temComprovante, bool jaGerouTickets) =>
                _abrirDialogEditarBar(item, temComprovante, jaGerouTickets),
          );
        },
      ),
    );
  }
}

// ==========================================
// CARD DO BAR COM INTEGRAÇÃO DE TICKETS & CÁLCULO DE TOTAL
// ==========================================
class _BarItemCard extends StatefulWidget {
  final dynamic item;
  final String? hldId;
  final ProductsController productsController;
  final void Function(bool temComprovante, bool jaGerouTickets) onEditBar;

  const _BarItemCard({
    super.key,
    required this.item,
    required this.hldId,
    required this.productsController,
    required this.onEditBar,
  });

  @override
  State<_BarItemCard> createState() => _BarItemCardState();
}

class _BarItemCardState extends State<_BarItemCard> {
  late final TicketController _ticketController;
  late final TicketReceiptImageService _paymentService;

  final ValueNotifier<bool> _uploadLoadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> _uploadErrorNotifier = ValueNotifier<String?>(null);

  bool _isExpanded = false;
  List<VProfileModel> _participantesDivisao = [];
  bool _ticketsGerados = false;
  double totalGastos = 0.0;

  @override
  void initState() {
    super.initState();
    _ticketController = getItTicketController<TicketController>();
    _paymentService = TicketReceiptImageService(
      loadingNotifier: _uploadLoadingNotifier,
      errorNotifier: _uploadErrorNotifier,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _carregarTickets();
        _inicializarParticipanteCriador();
      }
    });
  }

  @override
  void dispose() {
    _uploadLoadingNotifier.dispose();
    _uploadErrorNotifier.dispose();
    super.dispose();
  }

  void _inicializarParticipanteCriador() async {
    final bdProfileController = getItBdProfileController<BdProfileController>();
    await bdProfileController.loadProfiles('1');
    
    final profiles = bdProfileController.profilesNotifier.value ?? [];
    final String barOpenPflId = (widget.item.bar_open_pfl_id ?? '').toString();

    if (barOpenPflId.isNotEmpty) {
      final criador = profiles.firstWhere(
        (p) => p.pfl_id.toString() == barOpenPflId,
      );

      if (mounted) {
        setState(() {
          _participantesDivisao = [criador];
        });
      }
    }
  }

  void _carregarTickets() {
    final String barId = (widget.item.bar_id ?? widget.item.hqb_id ?? '').toString();
    final String openDate = (widget.item.bar_open_date ?? '').toString();
    final String hldId = (widget.hldId ?? '').toString();

    _ticketController.loadTickets(barId, openDate, hldId);
  }

  void _abrirDialogSelecionarParticipantes() async {
    final bdProfileController = getItBdProfileController<BdProfileController>();
    await bdProfileController.loadProfiles('1');

    if (!mounted) return;

    final idsExistentes = _participantesDivisao
        .map((p) => p.pfl_id.toString())
        .toSet();

    final todosTickets = _ticketController.ticketNotifier.value;
    for (final t in todosTickets) {
      final items = t.ticketsItems ?? [];
      final isDivisao = items.any((item) => item.tit_pdt_id?.toString() == '44');
      if (isDivisao) {
        final pflId = t.tkt_pfl_id?.toString();
        if (pflId != null && pflId.isNotEmpty) {
          idsExistentes.add(pflId);
        }
      }
    }

    final perfisDisponiveis = (bdProfileController.profilesNotifier.value ?? [])
        .where((c) => c.as_ismonthlypayment == 'true')
        .where((c) => !idsExistentes.contains(c.pfl_id.toString()))
        .toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SelectMultipleProfilesDialog(
        profiles: perfisDisponiveis,
        selectedProfiles: const [],
        onConfirm: (List<VProfileModel> novosSelecionados) {
          setState(() {
            _participantesDivisao = [
              ..._participantesDivisao,
              ...novosSelecionados,
            ];
          });
        },
      ),
    );
  }

  void _confirmarRemocaoParticipante(VProfileModel pessoa) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remover Participante'),
        content: Text('Deseja realmente remover ${pessoa.pfl_full_name} da divisão dos gastos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _participantesDivisao.remove(pessoa);
              });
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${pessoa.pfl_full_name} foi removido(a) da divisão.'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  Future<void> _gerarTickets() async {
    if (_participantesDivisao.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmar Geração'),
        content: Text(
          'Deseja realmente gerar os tickets da divisão de gastos para ${_participantesDivisao.length} participante(s)?\n\n'
          'Após gerar, a alteração e edição dos itens ficarão bloqueadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Gerar Tickets'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final String barId = (widget.item.bar_id ?? widget.item.hqb_id ?? '').toString();
    final String openDate = (widget.item.bar_open_date ?? '').toString();
    final String hldId = (widget.hldId ?? '').toString();

    double valor = totalGastos / _participantesDivisao.length;

    for (final pessoa in _participantesDivisao) {
      final tktId = await _ticketController.insertTickets(
        hldId: hldId,
        openDate: openDate,
        nTable: '-1',
        clienteName: pessoa.pfl_full_name,
        pflId: pessoa.pfl_id.toString(),
        barId: barId,
      );
      final ticketsItems = TicketsItemsModel(
        tit_hld_id: hldId,
        tit_tkt_id: tktId,
        tit_pdt_id: '44',
        tit_quantities: 1,
        tit_unit_value: valor,
        tit_value: valor,
      );

      await _ticketController.insertTicketsItems(
        ticketsItems,
        barId,
        openDate,
        hldId,
      );
    }

    _carregarTickets();

    setState(() {
      _ticketsGerados = true;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tickets gerados com sucesso! Edição bloqueada.'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _anexarComprovanteTicket(dynamic ticket) async {
    final String barId = (widget.item.bar_id ?? widget.item.hqb_id ?? '').toString();
    final String openDate = (widget.item.bar_open_date ?? '').toString();

    final payload = {
      'tkt_id': ticket.tkt_id,
      'pfl_id': ticket.tkt_pfl_id,
      'tkt_tst_id': '3',
      'barId': ticket.tkt_bar_id ?? barId,
      'openDate': ticket.tkt_bar_open_date ?? openDate,
      'valor': ticket.totalConsumo ?? 0.0,
      'hld_id': widget.hldId,
      'changeTitValue': true,
    };

    await _paymentService.selecionarAnexoEEnviar(
      context: context,
      payload: payload,
    );

    if (mounted) {
      if (_uploadErrorNotifier.value != null && _uploadErrorNotifier.value!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_uploadErrorNotifier.value!),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _carregarTickets();
      }
    }
  }

  void _mostrarComprovante(BuildContext context, dynamic ticket) {
    final String imageUrl = ticket.tkt_paiment_path ?? '';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.receipt_long, color: Colors.orangeAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Comprovante - Ticket #${ticket.tkt_id}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
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
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 180,
                        color: Colors.black12,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'Erro ao carregar a imagem do comprovante.',
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
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
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              _anexarComprovanteTicket(ticket);
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Substituir'),
          ),
        ],
      ),
    );
  }

  void _abrirDialogAdicionarTicket() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AddTicketItemDialog(
        hldId: widget.hldId,
        productsController: widget.productsController,
        onConfirm: (String pdtId, double valor, int quantidade) async {
          final String barId = widget.item.bar_id.toString();
          final String hldId = widget.hldId.toString();
          final String openDate = widget.item.bar_open_date.toString();
          final String pflId = widget.item.bar_open_pfl_id.toString();
          final String clienteName = widget.item.open_profile_name ?? widget.item.bar_open_pfl_id.toString();

          final tktId = await _ticketController.insertTickets(
            hldId: hldId,
            openDate: openDate,
            nTable: '-1',
            clienteName: clienteName,
            pflId: pflId,
            barId: barId,
          );

          final ticketsItems = TicketsItemsModel(
            tit_hld_id: hldId,
            tit_tkt_id: tktId,
            tit_pdt_id: pdtId,
            tit_quantities: quantidade,
            tit_unit_value: valor,
            tit_value: valor * quantidade,
          );

          await _ticketController.insertTicketsItems(
            ticketsItems,
            barId,
            openDate,
            hldId,
          );

          _carregarTickets();

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ticket e item adicionados com sucesso!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  void _abrirDialogEditarTicket(dynamic ticketItem) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _EditTicketItemDialog(
        ticketItem: ticketItem,
        onSave: (String novaDescricao, double novoValor, int novaQuantidade) async {
          final String titId = (ticketItem.tit_id ?? '').toString();
          final String barId = widget.item.bar_id.toString();
          final String openDate = widget.item.bar_open_date.toString();
          final String hldId = widget.hldId.toString();

          try {
            await _ticketController.updateTicketsItems_value(
              titId,
              novaQuantidade,
              novoValor,
              barId,
              openDate,
              hldId,
            );

            _carregarTickets();

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ticket/Item atualizado com sucesso!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } catch (e) {
            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro ao atualizar ticket/item: $e'),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        onDelete: () async {
          final String titId = (ticketItem.tit_id ?? '').toString();
          final String tktId = (ticketItem.tit_tkt_id ?? ticketItem.tkt_id ?? '').toString();

          try {
            if (titId.isNotEmpty) {
              await _ticketController.deleteTit(titId);
            }
            if (tktId.isNotEmpty) {
              await _ticketController.deleteTkt(tktId);
            }

            _carregarTickets();

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ticket/Item removido com sucesso!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } catch (e) {
            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro ao apagar ticket/item: $e'),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.item.open_profile_name ?? 'Pessoa não informada';
    final String pix = widget.item.bar_desc ?? '';
    final String dateStr = widget.item.bar_open_date != null
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(widget.item.bar_open_date.toString()))
        : '-';
    final String status = 'Pendente';

    return Stack(
      children: [
        Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.indigo.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CABEÇALHO
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.indigo.withValues(alpha: 0.2),
                      child: const Icon(Icons.person, color: Colors.indigoAccent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 12, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(
                                dateStr,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(status),
                    const SizedBox(width: 4),

                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueAccent),
                      tooltip: 'Editar Registro',
                      onPressed: () {
                        final tickets = _ticketController.ticketNotifier.value;
                        final bool temComprovante = tickets.any((t) {
                          final String? path = t.tkt_paiment_path;
                          return path != null && path.trim().isNotEmpty;
                        });
                        final bool ticketsDivisaoExist = tickets.any((t) {
                          final items = t.ticketsItems ?? [];
                          return items.any((item) => item.tit_pdt_id?.toString() == '44');
                        });
                        final bool jaGerou = _ticketsGerados || ticketsDivisaoExist;

                        widget.onEditBar(temComprovante, jaGerou);
                      },
                    ),

                    IconButton(
                      icon: Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 24,
                        color: Colors.white70,
                      ),
                      tooltip: _isExpanded ? 'Recolher' : 'Expandir',
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                    ),
                  ],
                ),

                // PIX
                if (pix.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.pix, size: 18, color: Colors.tealAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'PIX: $pix',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18, color: Colors.white70),
                        tooltip: 'Copiar PIX',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: pix));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Chave PIX copiada!'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],

                // CONTEÚDO EXPANSÍVEL
                if (_isExpanded) ...[
                  const Divider(height: 20),

                  ListenableBuilder(
                    listenable: _ticketController.ticketNotifier,
                    builder: (context, _) {
                      final List<dynamic> todosTickets = _ticketController.ticketNotifier.value;

                      final ticketsGastos = todosTickets.where((t) {
                        final items = t.ticketsItems ?? [];
                        return items.any((item) => item.tit_pdt_id?.toString() != '44');
                      }).toList();

                      final ticketsDivisao = todosTickets.where((t) {
                        final items = t.ticketsItems ?? [];
                        return items.any((item) => item.tit_pdt_id?.toString() == '44');
                      }).toList();

                      totalGastos = 0.0;
                      for (final t in todosTickets) {
                        final items = t.ticketsItems ?? [];
                        for (final item in items) {
                          if (item.tit_pdt_id?.toString() != '44') {
                            final qtd = int.tryParse(item.tit_quantities?.toString() ?? '1') ?? 1;
                            final valorUnit = double.tryParse(item.tit_unit_value?.toString() ?? '0') ?? 0.0;
                            totalGastos += (valorUnit * qtd);
                          }
                        }
                      }

                      final bool jaGerouTickets = _ticketsGerados || ticketsDivisao.isNotEmpty;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.confirmation_number_outlined,
                                      size: 18, color: Colors.indigoAccent),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Tickets / Itens (${ticketsGastos.length})',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: jaGerouTickets ? Colors.grey : Colors.indigoAccent,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: jaGerouTickets ? null : _abrirDialogAdicionarTicket,
                                icon: const Icon(Icons.add_circle_outline, size: 16),
                                label: const Text('+ Ticket', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          if (ticketsGastos.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 6.0),
                              child: Text(
                                'Nenhum ticket/item adicionado.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white54,
                                ),
                              ),
                            )
                          else ...[
                            Column(
                              children: [
                                for (final t in ticketsGastos)
                                  for (final item in (t.ticketsItems ?? []))
                                    if (item.tit_pdt_id?.toString() != '44') ...[
                                      Builder(
                                        builder: (context) {
                                          final int qtd = int.tryParse(item.tit_quantities?.toString() ?? '1') ?? 1;
                                          final double valorUnit = double.tryParse(item.tit_unit_value?.toString() ?? '0') ?? 0.0;
                                          final String itemDesc = item.pdt_name ?? item.tit_pdt_id?.toString() ?? 'Item';
                                          final double valorTotal = valorUnit * qtd;

                                          final String? comprovanteUrl = t.tkt_paiment_path;
                                          final bool temComprovante = comprovanteUrl != null && comprovanteUrl.trim().isNotEmpty;

                                          return Container(
                                            margin: const EdgeInsets.symmetric(vertical: 3),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.black12,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.indigo.withValues(alpha: 0.2)),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    '$qtd x $itemDesc',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(valorTotal),
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.greenAccent,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),

                                                IconButton(
                                                  constraints: const BoxConstraints(),
                                                  padding: const EdgeInsets.all(4),
                                                  icon: Icon(
                                                    temComprovante ? Icons.image_search : Icons.add_a_photo,
                                                    size: 17,
                                                    color: temComprovante ? Colors.orangeAccent : Colors.grey,
                                                  ),
                                                  tooltip: temComprovante ? 'Visualizar Comprovante' : 'Anexar Comprovante',
                                                  onPressed: () {
                                                    if (temComprovante) {
                                                      _mostrarComprovante(context, t);
                                                    } else {
                                                      _anexarComprovanteTicket(t);
                                                    }
                                                  },
                                                ),

                                                IconButton(
                                                  constraints: const BoxConstraints(),
                                                  padding: const EdgeInsets.all(4),
                                                  icon: Icon(
                                                    Icons.edit_outlined,
                                                    size: 17,
                                                    color: (temComprovante || jaGerouTickets)
                                                        ? Colors.grey
                                                        : Colors.blueAccent,
                                                  ),
                                                  tooltip: jaGerouTickets
                                                      ? 'Não é possível editar após gerar a divisão de gastos'
                                                      : (temComprovante
                                                          ? 'Não é possível editar ou apagar um ticket com comprovante'
                                                          : 'Editar Ticket/Item'),
                                                  onPressed: (temComprovante || jaGerouTickets)
                                                      ? null
                                                      : () => _abrirDialogEditarTicket(item),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                              ],
                            ),

                            const SizedBox(height: 10),

                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.indigo.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Gastos:',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(totalGastos),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.greenAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // DIVISÃO DOS GASTOS
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black12,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.indigo.withValues(alpha: 0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.people_outline, size: 18, color: Colors.indigoAccent),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Divisão dos Gastos (${ticketsDivisao.isNotEmpty ? ticketsDivisao.length : _participantesDivisao.length})',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                      TextButton.icon(
                                        style: TextButton.styleFrom(
                                          foregroundColor: jaGerouTickets ? Colors.grey : Colors.indigoAccent,
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: jaGerouTickets ? null : _abrirDialogSelecionarParticipantes,
                                        icon: const Icon(Icons.person_add_alt_1, size: 16),
                                        label: Text(
                                          _participantesDivisao.isEmpty && ticketsDivisao.isEmpty ? 'Selecionar' : 'Adicionar',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  if (ticketsDivisao.isNotEmpty) ...[
                                    Column(
                                      children: ticketsDivisao.map((t) {
                                        final String nome = (t.pfl_full_name ?? t.cliente_name ?? t.open_profile_name ?? 'Participante').toString();
                                        final String? comprovanteUrl = t.tkt_paiment_path;
                                        final bool temComprovante = comprovanteUrl != null && comprovanteUrl.trim().isNotEmpty;

                                        double valorDivisao = 0.0;
                                        final items = t.ticketsItems ?? [];
                                        for (final item in items) {
                                          if (item.tit_pdt_id?.toString() == '44') {
                                            valorDivisao = double.tryParse((item.tit_value ?? item.tit_unit_value ?? '0').toString()) ?? 0.0;
                                          }
                                        }

                                        return Container(
                                          margin: const EdgeInsets.symmetric(vertical: 3),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black12,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.indigo.withValues(alpha: 0.15)),
                                          ),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 12,
                                                backgroundColor: Colors.indigo.withValues(alpha: 0.2),
                                                child: Text(
                                                  nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                                                  style: const TextStyle(fontSize: 11, color: Colors.indigoAccent),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  nome,
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                                ),
                                              ),
                                              if (valorDivisao > 0) ...[
                                                Text(
                                                  NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(valorDivisao),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.greenAccent,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                              ],
                                              IconButton(
                                                constraints: const BoxConstraints(),
                                                padding: const EdgeInsets.all(4),
                                                icon: Icon(
                                                  temComprovante ? Icons.image_search : Icons.add_a_photo,
                                                  size: 18,
                                                  color: temComprovante ? Colors.orangeAccent : Colors.grey,
                                                ),
                                                tooltip: temComprovante ? 'Visualizar Comprovante' : 'Carregar Comprovante',
                                                onPressed: () {
                                                  if (temComprovante) {
                                                    _mostrarComprovante(context, t);
                                                  } else {
                                                    _anexarComprovanteTicket(t);
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ] else if (_participantesDivisao.isEmpty)
                                    const Text(
                                      'Nenhum participante adicionado à divisão.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.white54,
                                      ),
                                    )
                                  else ...[
                                    Column(
                                      children: _participantesDivisao.map((p) {
                                        return Container(
                                          margin: const EdgeInsets.symmetric(vertical: 3),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black12,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.indigo.withValues(alpha: 0.15)),
                                          ),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 12,
                                                backgroundColor: Colors.indigo.withValues(alpha: 0.2),
                                                child: Text(
                                                  p.pfl_full_name.isNotEmpty ? p.pfl_full_name[0].toUpperCase() : '?',
                                                  style: const TextStyle(fontSize: 11, color: Colors.indigoAccent),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  p.pfl_full_name,
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                                ),
                                              ),
                                              IconButton(
                                                constraints: const BoxConstraints(),
                                                padding: const EdgeInsets.all(4),
                                                icon: Icon(
                                                  Icons.close,
                                                  size: 18,
                                                  color: jaGerouTickets ? Colors.grey : Colors.redAccent,
                                                ),
                                                tooltip: jaGerouTickets
                                                    ? 'Não é possível remover após gerar tickets'
                                                    : 'Remover Pessoa',
                                                onPressed: jaGerouTickets ? null : () => _confirmarRemocaoParticipante(p),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),

                                    if (totalGastos > 0) ...[
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Valor por pessoa: ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(totalGastos / _participantesDivisao.length)}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.greenAccent,
                                              ),
                                            ),
                                          ),
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: jaGerouTickets ? Colors.grey : Colors.indigo,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              visualDensity: VisualDensity.compact,
                                            ),
                                            onPressed: jaGerouTickets ? null : _gerarTickets,
                                            icon: const Icon(Icons.confirmation_number_outlined, size: 16),
                                            label: Text(
                                              jaGerouTickets ? 'Tickets Gerados' : 'Gerar Tickets',
                                              style: const TextStyle(fontSize: 11),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),

        ValueListenableBuilder<bool>(
          valueListenable: _uploadLoadingNotifier,
          builder: (context, isUploading, child) {
            if (!isUploading) return const SizedBox.shrink();
            return Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text(
                        'A enviar comprovativo...',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    bool isPago = status.toLowerCase() == 'pago' || status.toLowerCase() == 'concluido';
    String label = isPago ? 'PAGO' : status.toUpperCase();
    Color color = isPago ? Colors.greenAccent : Colors.orangeAccent;
    Color bgColor = (isPago ? Colors.green : Colors.orange).withValues(alpha: 0.15);

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
}

// ==========================================
// DIÁLOGO: ADICIONAR PITCHING IN / BAR
// ==========================================
class _AddPitchingInDialog extends StatefulWidget {
  final BdProfileController bdProfileController;
  final Function(DateTime data, VProfileModel? profile, String pix) onConfirm;

  const _AddPitchingInDialog({
    required this.bdProfileController,
    required this.onConfirm,
  });

  @override
  State<_AddPitchingInDialog> createState() => _AddPitchingInDialogState();
}

class _AddPitchingInDialogState extends State<_AddPitchingInDialog> {
  DateTime _dataSelecionada = DateTime.now();
  VProfileModel? _perfilSelecionado;
  final TextEditingController _pixController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _pixController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _dataSelecionada) {
      setState(() {
        _dataSelecionada = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfis = widget.bdProfileController.profilesNotifier.value ?? [];

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Novo Registro'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Data: ${DateFormat('dd/MM/yyyy').format(_dataSelecionada)}'),
                trailing: const Icon(Icons.calendar_today, color: Colors.indigoAccent),
                onTap: () => _selecionarData(context),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<VProfileModel>(
                value: _perfilSelecionado,
                decoration: const InputDecoration(
                  labelText: 'Responsável',
                  border: OutlineInputBorder(),
                ),
                items: perfis.map((p) {
                  return DropdownMenuItem<VProfileModel>(
                    value: p,
                    child: Text(p.pfl_full_name),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _perfilSelecionado = val),
                validator: (val) => val == null ? 'Selecione um responsável' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pixController,
                decoration: const InputDecoration(
                  labelText: 'Chave PIX',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Informe a chave PIX' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              widget.onConfirm(_dataSelecionada, _perfilSelecionado, _pixController.text);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

// ==========================================
// DIÁLOGO: EDITAR PITCHING IN / BAR
// ==========================================
class _EditPitchingInDialog extends StatefulWidget {
  final dynamic item;
  final bool hasReceipt;
  final bool jaGerouTickets;
  final Function(DateTime novaData, String novoPix) onSave;
  final VoidCallback onDelete;

  const _EditPitchingInDialog({
    required this.item,
    required this.hasReceipt,
    required this.jaGerouTickets,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<_EditPitchingInDialog> createState() => _EditPitchingInDialogState();
}

class _EditPitchingInDialogState extends State<_EditPitchingInDialog> {
  late DateTime _dataSelecionada;
  late TextEditingController _pixController;

  @override
  void initState() {
    super.initState();
    final dateStr = widget.item.bar_open_date?.toString();
    _dataSelecionada = dateStr != null ? DateTime.tryParse(dateStr) ?? DateTime.now() : DateTime.now();
    _pixController = TextEditingController(text: widget.item.bar_desc?.toString() ?? '');
  }

  @override
  void dispose() {
    _pixController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dataSelecionada = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Editar Registro'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Data: ${DateFormat('dd/MM/yyyy').format(_dataSelecionada)}'),
              trailing: const Icon(Icons.calendar_today, color: Colors.indigoAccent),
              onTap: () => _selecionarData(context),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pixController,
              decoration: const InputDecoration(
                labelText: 'Chave PIX',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          tooltip: 'Excluir',
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Excluir Registro'),
                content: const Text('Deseja realmente apagar este registro?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                      widget.onDelete();
                    },
                    child: const Text('Excluir', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          },
        ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            widget.onSave(_dataSelecionada, _pixController.text);
            Navigator.of(context).pop();
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

// ==========================================
// DIÁLOGO: SELECIONAR MÚLTIPLOS PARTICIPANTES
// ==========================================
class _SelectMultipleProfilesDialog extends StatefulWidget {
  final List<VProfileModel> profiles;
  final List<VProfileModel> selectedProfiles;
  final Function(List<VProfileModel> selecionados) onConfirm;

  const _SelectMultipleProfilesDialog({
    required this.profiles,
    required this.selectedProfiles,
    required this.onConfirm,
  });

  @override
  State<_SelectMultipleProfilesDialog> createState() =>
      _SelectMultipleProfilesDialogState();
}

class _SelectMultipleProfilesDialogState
    extends State<_SelectMultipleProfilesDialog> {
  late List<VProfileModel> _tempSelecionados;

  @override
  void initState() {
    super.initState();
    _tempSelecionados = List.from(widget.selectedProfiles);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Adicionar Participantes'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: widget.profiles.isEmpty
            ? const Center(child: Text('Nenhum participante disponível.'))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: widget.profiles.length,
                itemBuilder: (context, index) {
                  final item = widget.profiles[index];
                  final isSelected = _tempSelecionados.any(
                    (p) => p.pfl_id.toString() == item.pfl_id.toString(),
                  );

                  return CheckboxListTile(
                    title: Text(item.pfl_full_name),
                    value: isSelected,
                    onChanged: (bool? checked) {
                      setState(() {
                        if (checked == true) {
                          _tempSelecionados.add(item);
                        } else {
                          _tempSelecionados.removeWhere(
                            (p) => p.pfl_id.toString() == item.pfl_id.toString(),
                          );
                        }
                      });
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            widget.onConfirm(_tempSelecionados);
            Navigator.of(context).pop();
          },
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}

// ==========================================
// DIÁLOGO: ADICIONAR ITEM DO TICKET
// ==========================================
class _AddTicketItemDialog extends StatefulWidget {
  final String? hldId;
  final ProductsController productsController;
  final Function(String pdtId, double valor, int quantidade) onConfirm;

  const _AddTicketItemDialog({
    required this.hldId,
    required this.productsController,
    required this.onConfirm,
  });

  @override
  State<_AddTicketItemDialog> createState() => _AddTicketItemDialogState();
}

class _AddTicketItemDialogState extends State<_AddTicketItemDialog> {
  ProductsModel? _produtoSelecionado;
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _qtdController = TextEditingController(text: '1');
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    widget.productsController.loadProdutos(widget.hldId ?? '');
  }

  @override
  void dispose() {
    _valorController.dispose();
    _qtdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Adicionar Item'),
      content: ValueListenableBuilder<List<ProductsModel>>(
        valueListenable: widget.productsController.productsNotifier,
        builder: (context, produtos, _) {
          return SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<ProductsModel>(
                    value: _produtoSelecionado,
                    decoration: const InputDecoration(
                      labelText: 'Produto',
                      border: OutlineInputBorder(),
                    ),
                    items: produtos
                        .where((p) => p.pdt_id.toString() != '44')
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p.pdt_name ?? ''),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _produtoSelecionado = val;
                        if (val?.pdt_value_member != null) {
                          _valorController.text = val!.pdt_value_member.toString();
                        }
                      });
                    },
                    validator: (val) => val == null ? 'Selecione um produto' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _qtdController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantidade',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) =>
                        (val == null || int.tryParse(val) == null || int.parse(val) <= 0)
                            ? 'Quantidade inválida'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _valorController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Valor Unitário (R\$)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) =>
                        (val == null || double.tryParse(val) == null)
                            ? 'Valor inválido'
                            : null,
                  ),
                ],
              ),
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              final double valor = double.parse(_valorController.text.replaceAll(',', '.'));
              final int qtd = int.parse(_qtdController.text);
              widget.onConfirm(_produtoSelecionado!.pdt_id.toString(), valor, qtd);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
}

// ==========================================
// DIÁLOGO: EDITAR ITEM DO TICKET
// ==========================================
class _EditTicketItemDialog extends StatefulWidget {
  final dynamic ticketItem;
  final Function(String novaDescricao, double novoValor, int novaQuantidade) onSave;
  final VoidCallback onDelete;

  const _EditTicketItemDialog({
    required this.ticketItem,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<_EditTicketItemDialog> createState() => _EditTicketItemDialogState();
}

class _EditTicketItemDialogState extends State<_EditTicketItemDialog> {
  late TextEditingController _valorController;
  late TextEditingController _qtdController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final double valor = double.tryParse((widget.ticketItem.tit_unit_value ?? widget.ticketItem.tit_value ?? '0').toString()) ?? 0.0;
    final int qtd = int.tryParse((widget.ticketItem.tit_quantities ?? '1').toString()) ?? 1;

    _valorController = TextEditingController(text: valor.toString());
    _qtdController = TextEditingController(text: qtd.toString());
  }

  @override
  void dispose() {
    _valorController.dispose();
    _qtdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String nomeProduto = widget.ticketItem.pdt_name ?? 'Item';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Editar $nomeProduto'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _qtdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantidade',
                border: OutlineInputBorder(),
              ),
              validator: (val) =>
                  (val == null || int.tryParse(val) == null || int.parse(val) <= 0)
                      ? 'Quantidade inválida'
                      : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _valorController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Valor Unitário (R\$)',
                border: OutlineInputBorder(),
              ),
              validator: (val) =>
                  (val == null || double.tryParse(val) == null)
                      ? 'Valor inválido'
                      : null,
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          tooltip: 'Excluir Item',
          onPressed: () {
            Navigator.of(context).pop();
            widget.onDelete();
          },
        ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              final double valor = double.parse(_valorController.text.replaceAll(',', '.'));
              final int qtd = int.parse(_qtdController.text);
              widget.onSave(nomeProduto, valor, qtd);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}