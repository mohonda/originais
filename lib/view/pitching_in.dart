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

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registro adicionado com sucesso!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          loadData();
        },
      ),
    );
  }

  void _abrirDialogEditarBar(dynamic item, bool temComprovante) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _EditPitchingInDialog(
        item: item,
        hasReceipt: temComprovante,
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
            onEditBar: (bool temComprovante) => _abrirDialogEditarBar(item, temComprovante),
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
  final void Function(bool temComprovante) onEditBar;

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

  // Estado para controlar a expansão/retração das informações detalhadas
  bool _isExpanded = false;

  // Lista de perfis selecionados para a divisão dos gastos
  List<VProfileModel> _participantesDivisao = [];

  // Estado para controlar se os tickets da divisão foram gerados
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

    final todosPerfis = bdProfileController.profilesNotifier.value ?? [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SelectMultipleProfilesDialog(
        profiles: todosPerfis,
        selectedProfiles: _participantesDivisao,
        onConfirm: (List<VProfileModel> selecionados) {
          setState(() {
            _participantesDivisao = selecionados;
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
              backgroundColor: Colors.red,
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

  // Gera os tickets para cada participante da divisão
  Future<void> _gerarTickets() async {
    if (_participantesDivisao.isEmpty) return;

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
        content: Text('Tickets gerados com sucesso! Edição de participantes bloqueada.'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Carrega comprovante associado à pessoa individualmente
  Future<void> _anexarComprovantePessoa(VProfileModel pessoa) async {
    final String barId = (widget.item.bar_id ?? widget.item.hqb_id ?? '').toString();
    final String openDate = (widget.item.bar_open_date ?? '').toString();

    final payload = {
      'pfl_id': pessoa.pfl_id,
      'barId': barId,
      'openDate': openDate,
      'hld_id': widget.hldId,
    };

    await _paymentService.selecionarAnexoEEnviar(
      context: context,
      payload: payload,
    );

    if (mounted) {
      _carregarTickets();
    }
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
            const Icon(Icons.receipt_long, color: Colors.teal),
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
                        color: Colors.grey.shade200,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'Erro ao carregar a imagem do comprovante.',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CABEÇALHO (Visível sempre: Nome, Data, Status, Editar e Expandir)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.indigo.shade100,
                      child: const Icon(Icons.person, color: Colors.indigo),
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
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 13, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                dateStr,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(status),
                    const SizedBox(width: 4),

                    IconButton(
                      icon: const Icon(Icons.edit, size: 20, color: Colors.indigo),
                      tooltip: 'Editar Registro',
                      onPressed: () {
                        final tickets = _ticketController.ticketNotifier.value;
                        final bool temComprovante = tickets.any((t) {
                          final String? path = t.tkt_paiment_path;
                          return path != null && path.trim().isNotEmpty;
                        });
                        widget.onEditBar(temComprovante);
                      },
                    ),

                    // Botão para expandir / recolher
                    IconButton(
                      icon: Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 24,
                        color: Colors.grey.shade700,
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

                // PIX (Visível sempre na visualização retrátil)
                if (pix.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.pix, size: 18, color: Colors.teal),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'PIX: $pix',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
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

                // CONTEÚDO EXPANSÍVEL (Tickets, Total e Divisão dos Gastos)
                if (_isExpanded) ...[
                  const Divider(height: 20),

                  ListenableBuilder(
                    listenable: _ticketController.ticketNotifier,
                    builder: (context, _) {
                      final List<dynamic> todosTickets = _ticketController.ticketNotifier.value;

                      // Separar os tickets normais de gastos dos tickets gerados para divisão (tit_pdt_id == '44')
                      final ticketsGastos = todosTickets.where((t) {
                        final items = t.ticketsItems ?? [];
                        return items.any((item) => item.tit_pdt_id?.toString() != '44');
                      }).toList();

                      final ticketsDivisao = todosTickets.where((t) {
                        final items = t.ticketsItems ?? [];
                        return items.any((item) => item.tit_pdt_id?.toString() == '44');
                      }).toList();

                      // Cálculo do total de gastos ignorando itens da divisão (tit_pdt_id == '44')
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
                                  Icon(Icons.confirmation_number_outlined,
                                      size: 18, color: Colors.indigo.shade700),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Tickets / Itens (${ticketsGastos.length})',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.indigo.shade900,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.indigo,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: _abrirDialogAdicionarTicket,
                                icon: const Icon(Icons.add_circle_outline, size: 16),
                                label: const Text('+ Ticket', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          if (ticketsGastos.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Text(
                                'Nenhum ticket/item adicionado.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey.shade600,
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
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.grey.shade300),
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
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green.shade800,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),

                                                IconButton(
                                                  constraints: const BoxConstraints(),
                                                  padding: const EdgeInsets.all(4),
                                                  icon: Icon(
                                                    temComprovante ? Icons.receipt_long : Icons.attach_file,
                                                    size: 17,
                                                    color: temComprovante ? Colors.teal : Colors.grey.shade600,
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
                                                    Icons.edit,
                                                    size: 17,
                                                    color: temComprovante ? Colors.grey.shade400 : Colors.indigo,
                                                  ),
                                                  tooltip: temComprovante
                                                      ? 'Não é possível editar ou apagar um ticket com comprovante'
                                                      : 'Editar Ticket/Item',
                                                  onPressed: temComprovante
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
                                color: Colors.indigo.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.indigo.shade100),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Gastos:',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                  Text(
                                    NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(totalGastos),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // SECÇÃO: DIVISÃO DOS GASTOS
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.people_outline, size: 18, color: Colors.indigo.shade700),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Divisão dos Gastos (${ticketsDivisao.isNotEmpty ? ticketsDivisao.length : _participantesDivisao.length})',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Colors.indigo.shade900,
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Desabilita seleção/edição se já foram gerados tickets no BD
                                      TextButton.icon(
                                        style: TextButton.styleFrom(
                                          foregroundColor: jaGerouTickets ? Colors.grey : Colors.indigo,
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: jaGerouTickets ? null : _abrirDialogSelecionarParticipantes,
                                        icon: const Icon(Icons.person_add_alt_1, size: 16),
                                        label: Text(
                                          _participantesDivisao.isEmpty && ticketsDivisao.isEmpty ? 'Selecionar' : 'Editar',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // Caso já existam tickets com tit_pdt_id == '44' salvos no BD, exibimos eles aqui
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
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 12,
                                                backgroundColor: Colors.indigo.shade100,
                                                child: Text(
                                                  nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                                                  style: const TextStyle(fontSize: 11, color: Colors.indigo),
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
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green.shade800,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                              ],
                                              IconButton(
                                                constraints: const BoxConstraints(),
                                                padding: const EdgeInsets.all(4),
                                                icon: Icon(
                                                  temComprovante ? Icons.receipt_long : Icons.attach_file,
                                                  size: 18,
                                                  color: temComprovante ? Colors.teal : Colors.grey.shade600,
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
                                    Text(
                                      'Nenhum participante adicionado à divisão.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey.shade600,
                                      ),
                                    )
                                  else ...[
                                    // Lista de pessoas selecionadas manualmente antes de gerar os tickets
                                    Column(
                                      children: _participantesDivisao.map((p) {
                                        return Container(
                                          margin: const EdgeInsets.symmetric(vertical: 3),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 12,
                                                backgroundColor: Colors.indigo.shade100,
                                                child: Text(
                                                  p.pfl_full_name.isNotEmpty ? p.pfl_full_name[0].toUpperCase() : '?',
                                                  style: const TextStyle(fontSize: 11, color: Colors.indigo),
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
                                                icon: const Icon(Icons.attach_file, size: 18, color: Colors.teal),
                                                tooltip: 'Carregar Comprovante',
                                                onPressed: () => _anexarComprovantePessoa(p),
                                              ),
                                              const SizedBox(width: 4),
                                              IconButton(
                                                constraints: const BoxConstraints(),
                                                padding: const EdgeInsets.all(4),
                                                icon: Icon(
                                                  Icons.close,
                                                  size: 18,
                                                  color: jaGerouTickets ? Colors.grey : Colors.red.shade400,
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
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green.shade800,
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

  Widget _buildStatusChip(String status) {
    Color color;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'pago':
      case 'concluido':
      case 'aprovado':
        color = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case 'cancelado':
      case 'rejeitado':
        color = Colors.red.shade100;
        textColor = Colors.red.shade800;
        break;
      default:
        color = Colors.amber.shade100;
        textColor = Colors.amber.shade900;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ==========================================
// DIALOG DE SELEÇÃO MÚLTIPLA DE PESSOAS
// ==========================================
class _SelectMultipleProfilesDialog extends StatefulWidget {
  final List<VProfileModel> profiles;
  final List<VProfileModel> selectedProfiles;
  final Function(List<VProfileModel> selected) onConfirm;

  const _SelectMultipleProfilesDialog({
    required this.profiles,
    required this.selectedProfiles,
    required this.onConfirm,
  });

  @override
  State<_SelectMultipleProfilesDialog> createState() => _SelectMultipleProfilesDialogState();
}

class _SelectMultipleProfilesDialogState extends State<_SelectMultipleProfilesDialog> {
  late final Set<VProfileModel> _tempSelected;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tempSelected = Set<VProfileModel>.from(widget.selectedProfiles);
  }

  void _toggleSelectAll(bool? selectAll, List<VProfileModel> filtered) {
    setState(() {
      if (selectAll == true) {
        _tempSelected.addAll(filtered);
      } else {
        _tempSelected.removeAll(filtered);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredProfiles = widget.profiles.where((p) {
      return p.pfl_full_name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final isAllSelected = filteredProfiles.isNotEmpty &&
        filteredProfiles.every((p) => _tempSelected.contains(p));

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.group_add_outlined, color: Colors.indigo.shade700),
          const SizedBox(width: 8),
          const Text(
            'Divisão de Gastos',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Pesquisar pessoa...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_tempSelected.length} selecionado(s)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () => _toggleSelectAll(!isAllSelected, filteredProfiles),
                  child: Text(
                    isAllSelected ? 'Desmarcar todos' : 'Selecionar todos',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(height: 1),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: filteredProfiles.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Nenhum participante encontrado.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredProfiles.length,
                      itemBuilder: (context, index) {
                        final profile = filteredProfiles[index];
                        final isSelected = _tempSelected.contains(profile);

                        return CheckboxListTile(
                          dense: true,
                          activeColor: Colors.indigo,
                          title: Text(
                            profile.pfl_full_name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          value: isSelected,
                          onChanged: (bool? checked) {
                            setState(() {
                              if (checked == true) {
                                _tempSelected.add(profile);
                              } else {
                                _tempSelected.remove(profile);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            widget.onConfirm(_tempSelected.toList());
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Confirmar'),
        ),
      ],
    );
  }
}

// ==========================================
// DIALOG DE ADICIONAR REGISTRO HEADQUARTERS BAR
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
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dataController = TextEditingController();
  final TextEditingController _pixController = TextEditingController();
  DateTime? _selectedDate;
  VProfileModel? _selectedProfile;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _dataController.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
  }

  @override
  void dispose() {
    _dataController.dispose();
    _pixController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dataController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Adicionar Registro',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _dataController,
                readOnly: true,
                onTap: () => _selecionarData(context),
                decoration: const InputDecoration(
                  labelText: 'Data',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe a data';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<List<VProfileModel>?>(
                valueListenable: widget.bdProfileController.profilesNotifier,
                builder: (context, profiles, _) {
                  final activeProfiles = profiles ?? [];

                  return DropdownButtonFormField<VProfileModel?>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Pagará para...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    hint: const Text('Selecione a pessoa'),
                    value: _selectedProfile,
                    items: activeProfiles.map(
                      (p) => DropdownMenuItem<VProfileModel?>(
                        value: p,
                        child: Text(
                          p.pfl_full_name,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ).toList(),
                    validator: (value) {
                      if (value == null) {
                        return 'Selecione quem receberá';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _selectedProfile = value;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pixController,
                decoration: const InputDecoration(
                  labelText: 'PIX',
                  hintText: 'Informe a chave PIX...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pix),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o PIX';
                  }
                  return null;
                },
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
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (_formKey.currentState!.validate() && _selectedDate != null) {
              widget.onConfirm(
                _selectedDate!,
                _selectedProfile,
                _pixController.text.trim(),
              );
              Navigator.of(context).pop();
            }
          },
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Confirmar'),
        ),
      ],
    );
  }
}

// ==========================================
// DIALOG DE EDITAR / APAGAR REGISTRO HEADQUARTERS BAR
// ==========================================
class _EditPitchingInDialog extends StatefulWidget {
  final dynamic item;
  final bool hasReceipt;
  final Function(DateTime data, String pix) onSave;
  final VoidCallback onDelete;

  const _EditPitchingInDialog({
    required this.item,
    this.hasReceipt = false,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<_EditPitchingInDialog> createState() => _EditPitchingInDialogState();
}

class _EditPitchingInDialogState extends State<_EditPitchingInDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dataController = TextEditingController();
  final TextEditingController _pixController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.item.bar_open_date != null) {
      _selectedDate = DateTime.tryParse(widget.item.bar_open_date.toString()) ?? DateTime.now();
    } else {
      _selectedDate = DateTime.now();
    }
    _dataController.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
    _pixController.text = widget.item.bar_desc ?? '';
  }

  @override
  void dispose() {
    _dataController.dispose();
    _pixController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData(BuildContext context) async {
    if (widget.hasReceipt) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dataController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _confirmarExclusao() {
    if (widget.hasReceipt) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Deseja realmente apagar este registro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
              widget.onDelete();
            },
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String profileName = widget.item.open_profile_name ?? 'Registro';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Editar Registro',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            profileName,
            style: TextStyle(
              fontSize: 13,
              color: Colors.indigo.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _dataController,
                readOnly: true,
                enabled: !widget.hasReceipt,
                onTap: widget.hasReceipt ? null : () => _selecionarData(context),
                decoration: InputDecoration(
                  labelText: 'Data',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.calendar_today),
                  helperText: widget.hasReceipt
                      ? 'A data não pode ser alterada pois já existe comprovativo anexado.'
                      : null,
                  helperMaxLines: 2,
                  helperStyle: TextStyle(
                    color: Colors.orange.shade900,
                    fontSize: 11,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe a data';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pixController,
                decoration: const InputDecoration(
                  labelText: 'PIX',
                  hintText: 'Informe a chave PIX...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pix),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o PIX';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Tooltip(
              message: widget.hasReceipt
                  ? 'Não é possível apagar um registro que possui comprovativo anexado'
                  : '',
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: widget.hasReceipt ? Colors.grey : Colors.red,
                ),
                onPressed: widget.hasReceipt ? null : _confirmarExclusao,
                icon: const Icon(Icons.delete_outline, size: 20),
                label: const Text('Apagar'),
              ),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate() && _selectedDate != null) {
                      widget.onSave(
                        _selectedDate!,
                        _pixController.text.trim(),
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Salvar'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ==========================================
// DIALOG DE ADICIONAR TICKET & ITEM
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
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _qtdController = TextEditingController(text: '1');
  
  ProductsModel? _selectedProduct;

  @override
  void initState() {
    super.initState();
    widget.productsController.loadProductsFiltered(
      widget.hldId.toString(),
      '7',
    );
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
      title: const Row(
        children: [
          Icon(Icons.confirmation_number_outlined, color: Colors.indigo),
          SizedBox(width: 8),
          Text(
            'Novo Ticket / Item',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListenableBuilder(
                listenable: Listenable.merge([
                  widget.productsController.loadingNotifier,
                  widget.productsController.errorNotifier,
                  widget.productsController.productsFilteredNotifier,
                ]),
                builder: (context, _) {
                  final isLoading = widget.productsController.loadingNotifier.value;
                  final errorMsg = widget.productsController.errorNotifier.value;
                  final produtos = widget.productsController.productsFilteredNotifier.value;

                  if (isLoading) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (errorMsg != null && errorMsg.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        errorMsg,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    );
                  }

                  return DropdownButtonFormField<ProductsModel>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Selecione o Produto',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.shopping_bag_outlined),
                    ),
                    value: _selectedProduct,
                    hint: const Text('Escolha um item'),
                    items: produtos.map((p) {
                      return DropdownMenuItem<ProductsModel>(
                        value: p,
                        child: Text(
                          '${p.pdt_name} - R\$ ${p.pdt_value_member.toString()}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    validator: (value) => value == null ? 'Selecione um produto' : null,
                    onChanged: (product) {
                      setState(() {
                        _selectedProduct = product;
                        if (product != null) {
                          _valorController.text = product.pdt_value_member.toString();
                        }
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtdController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Qtd',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.format_list_numbered),
                      ),
                      validator: (value) {
                        if (value == null || int.tryParse(value) == null || int.parse(value) <= 0) {
                          return 'Inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _valorController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Valor Unit. (R\$)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: (value) {
                        if (value == null || double.tryParse(value.replaceAll(',', '.')) == null) {
                          return 'Informe o valor';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
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
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (_formKey.currentState!.validate() && _selectedProduct != null) {
              final double valor = double.parse(_valorController.text.trim().replaceAll(',', '.'));
              final int qtd = int.parse(_qtdController.text.trim());

              widget.onConfirm(
                _selectedProduct!.pdt_id,
                valor,
                qtd,
              );
              Navigator.of(context).pop();
            }
          },
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Adicionar'),
        ),
      ],
    );
  }
}

// ==========================================
// DIALOG DE EDITAR / APAGAR TICKET & ITEM
// ==========================================
class _EditTicketItemDialog extends StatefulWidget {
  final dynamic ticketItem;
  final Function(String descricao, double valor, int quantidade) onSave;
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
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descController;
  late final TextEditingController _valorController;
  late final TextEditingController _qtdController;

  @override
  void initState() {
    super.initState();
    final item = widget.ticketItem;
    _descController = TextEditingController(text: (item.pdt_name ?? item.tit_pdt_id ?? item.description ?? '').toString());
    _valorController = TextEditingController(text: (item.tit_unit_value ?? item.tit_value ?? item.amount ?? '0').toString());
    _qtdController = TextEditingController(text: (item.tit_quantities ?? item.qtd ?? '1').toString());
  }

  @override
  void dispose() {
    _descController.dispose();
    _valorController.dispose();
    _qtdController.dispose();
    super.dispose();
  }

  void _confirmarExclusao() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Deseja realmente apagar este ticket/item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
              widget.onDelete();
            },
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Editar Ticket / Item',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _descController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Descrição / Produto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label_outline),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtdController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Qtd',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.format_list_numbered),
                      ),
                      validator: (value) {
                        if (value == null || int.tryParse(value) == null || int.parse(value) <= 0) {
                          return 'Inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _valorController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Valor Unit. (R\$)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: (value) {
                        if (value == null || double.tryParse(value.replaceAll(',', '.')) == null) {
                          return 'Informe o valor';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: _confirmarExclusao,
              icon: const Icon(Icons.delete_outline, size: 20),
              label: const Text('Apagar'),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final double valor = double.parse(_valorController.text.trim().replaceAll(',', '.'));
                      final int qtd = int.parse(_qtdController.text.trim());

                      widget.onSave(
                        _descController.text.trim(),
                        valor,
                        qtd,
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Salvar'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}