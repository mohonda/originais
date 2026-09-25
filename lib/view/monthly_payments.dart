import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:originais/services/general_service.dart';
import 'package:originais/view/default_appbar.dart';
import 'package:originais/controllers/monthly_payments_controller.dart';
import 'package:originais/controllers/payment_value_controller.dart';
import 'package:originais/controllers/profile_controller.dart';
import 'package:originais/controllers/ticket_controller.dart';
import 'package:originais/models/mensalidades_model.dart';
import 'package:originais/models/vprofile_model.dart';
import 'package:originais/view/default_snackbar.dart';

// Estrutura auxiliar para pré-visualização das mensalidades a serem geradas
class _PendingGenerationItem {
  final VProfileModel profile;
  final DateTime monthDate;

  _PendingGenerationItem({
    required this.profile,
    required this.monthDate,
  });
}

// Função auxiliar global para filtrar sócios sem mensalidade no mês selecionado
List<VProfileModel> _getPendingProfilesForSelectedMonth(
  List<VProfileModel>? profiles,
  List<MensalidadesModel> existingPayments,
  String? month,
  String? year,
) {
  final activeProfiles =
      profiles?.where((item) => item.as_ismonthlypayment == 'true').toList() ?? [];

  if (month == null || year == null || month.isEmpty || year.isEmpty) {
    return activeProfiles;
  }

  final int targetMonth = int.tryParse(month) ?? 0;
  final int targetYear = int.tryParse(year) ?? 0;

  final paymentsInMonth = existingPayments.where((m) {
    final mMonth = int.tryParse(m.month.toString()) ?? 0;
    final mYear = int.tryParse(m.year.toString()) ?? 0;
    return mMonth == targetMonth && mYear == targetYear;
  }).toList();

  final existingProfileIds =
      paymentsInMonth.map((m) => m.tkt_pfl_id.toString()).toSet();
  final existingProfileNames = paymentsInMonth
      .map((m) => m.pfl_full_name.trim().toLowerCase())
      .toSet();

  return activeProfiles.where((item) {
    final idMatch = existingProfileIds.contains(item.pfl_id.toString());
    final nameMatch =
        existingProfileNames.contains(item.pfl_full_name.trim().toLowerCase());
    return !idMatch && !nameMatch;
  }).toList();
}

// Helper para calcular o intervalo de meses entre Início e Fim
List<DateTime> _getMonthsInRange(
  String startMonth,
  String startYear,
  String endMonth,
  String endYear,
) {
  final start = DateTime(int.parse(startYear), int.parse(startMonth), 1);
  final end = DateTime(int.parse(endYear), int.parse(endMonth), 1);

  if (start.isAfter(end)) return [];

  final List<DateTime> months = [];
  DateTime current = start;
  while (!current.isAfter(end)) {
    months.add(current);
    current = DateTime(current.year, current.month + 1, 1);
  }
  return months;
}

// Helper para montar os itens pendentes a gerar considerando o período e a pessoa selecionada
List<_PendingGenerationItem> _getPendingItemsToGenerate(
  List<VProfileModel>? profiles,
  List<MensalidadesModel> existingPayments,
  VProfileModel? selectedProfile,
  String? mStart,
  String? yStart,
  String? mEnd,
  String? yEnd,
) {
  if (mStart == null || yStart == null || mEnd == null || yEnd == null) {
    return [];
  }

  final months = _getMonthsInRange(mStart, yStart, mEnd, yEnd);
  final List<_PendingGenerationItem> itemsToGenerate = [];

  for (final monthDate in months) {
    final monthStr = monthDate.month.toString().padLeft(2, '0');
    final yearStr = monthDate.year.toString();

    final pendingForMonth = _getPendingProfilesForSelectedMonth(
      profiles,
      existingPayments,
      monthStr,
      yearStr,
    );

    for (final profile in pendingForMonth) {
      if (selectedProfile == null || profile.pfl_id == selectedProfile.pfl_id) {
        itemsToGenerate.add(_PendingGenerationItem(
          profile: profile,
          monthDate: monthDate,
        ));
      }
    }
  }

  return itemsToGenerate;
}

class MonthlyPayments extends StatefulWidget {
  final String? hldId;
  const MonthlyPayments({
    super.key,
    this.hldId,
  });

  @override
  State<MonthlyPayments> createState() => _MonthlyPaymentsState();
}

class _MonthlyPaymentsState extends State<MonthlyPayments> {
  final GeneralService generalService = GeneralService();
  late final BdMonthlyPaymentsController bdMonthlyPaymentsController;
  late final BdPaymentValueController bdPaymentValueController;
  late final BdProfileController bdProfileController;
  late final TicketController ticketController;

  final String _searchQuery = '';
  String _filtroStatus = 'Todos';

  // ==========================================
  void _onErrorChanged() {
    final error = bdMonthlyPaymentsController.errorNotifier.value;

    if (error != null && error.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $error'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ==========================================
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
    ticketController =
        getItTicketController<TicketController>();

    bdMonthlyPaymentsController.initRealtime(widget.hldId.toString());

    DefaultSnackbar.attachErrorListener(
      context,
      bdMonthlyPaymentsController.errorNotifier,
    );

    DefaultSnackbar.attachSuccessListener(
      context,
      bdMonthlyPaymentsController.successNotifier,
    );
  }

  void loadData() {
    bdMonthlyPaymentsController.loadCurrentMonthlyPayment();
  }

  // ==========================================
  @override
  void dispose() {
    bdMonthlyPaymentsController.errorNotifier.removeListener(_onErrorChanged);
    bdMonthlyPaymentsController.disposeRealtime();
    super.dispose();
  }

  // ==========================================
  void _abrirDialogGerarMensalidades({String? initialMonth, String? initialYear}) async {
    await bdPaymentValueController.loadPaymentValue();
    await bdProfileController.loadProfiles('1');

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AddMonthlyGenerationDialog(
        hldId: widget.hldId.toString(),
        bdPaymentValueController: bdPaymentValueController,
        bdProfileController: bdProfileController,
        bdMonthlyPaymentsController: bdMonthlyPaymentsController,
        generalService: generalService,
        initialMonth: initialMonth,
        initialYear: initialYear,
      ),
    );
  }

  // ==========================================
  void _confirmarExclusaoMensalidade(
    BuildContext context,
    MensalidadesModel mensalidade,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir Mensalidade'),
        content: Text(
          'Tem certeza que deseja excluir a mensalidade de ${mensalidade.pfl_full_name} '
          '(Ref: ${mensalidade.month.toString().padLeft(2, '0')}/${mensalidade.year})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ticketController.deleteTit(mensalidade.tit_id);
                await ticketController.deleteTkt(mensalidade.tkt_id);
                await ticketController.deleteBar(mensalidade.tkt_bar_id);
                loadData();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mensalidade excluída com sucesso!'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao excluir mensalidade: $e'),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  void _editarMensalidade(
    BuildContext context,
    MensalidadesModel mensalidade,
  ) {
    final valorController = TextEditingController(
      text: mensalidade.tit_unit_value.toString(),
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Editar - ${mensalidade.pfl_full_name}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: valorController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Valor Final (R\$)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o valor da mensalidade';
                  }
                  if (double.tryParse(value.replaceAll(',', '.')) == null) {
                    return 'Informe um valor válido';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(dialogContext);
              try {
                final String novoValorStr =
                    valorController.text.trim().replaceAll(',', '.');
                final double novoValorDouble = double.tryParse(novoValorStr) ?? 0.0;
                final int quantidadeInt = int.tryParse(
                  mensalidade.tit_quantities.toString()) ?? 1;
                
                await ticketController.updateTicketsItems_value(
                  mensalidade.tit_id,
                  quantidadeInt,
                  novoValorDouble,
                  mensalidade.tkt_bar_id,
                  mensalidade.tkt_bar_open_date,
                  mensalidade.tkt_hld_id
                );
                loadData();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mensalidade atualizada com sucesso!'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao atualizar mensalidade: $e'),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DefaultAppbar(title: 'Monthly Payments'),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addMonthlyPaymentsFab',
        elevation: 2,
        backgroundColor: Colors.indigo,
        onPressed: () => _abrirDialogGerarMensalidades(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          bdMonthlyPaymentsController.loadingNotifier,
          bdMonthlyPaymentsController.errorNotifier,
          bdMonthlyPaymentsController.monthlyPaymentsNotifier,
        ]),
        builder: (context, _) {
          final isLoading = bdMonthlyPaymentsController.loadingNotifier.value;
          final errorMessage = bdMonthlyPaymentsController.errorNotifier.value;
          final lista = bdMonthlyPaymentsController.monthlyPaymentsNotifier.value;

          return Stack(
            children: [
              if (errorMessage != null && errorMessage.isNotEmpty && lista.isEmpty)
                _buildErrorState(errorMessage)
              else if (lista.isEmpty && !isLoading)
                const Center(child: Text('Nenhuma mensalidade encontrada.'))
              else if (lista.isEmpty && isLoading)
                const Center(child: CircularProgressIndicator())
              else
                _buildTabContent(lista),

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

  // ==========================================
  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            errorMessage,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              bdMonthlyPaymentsController.initRealtime(
                widget.hldId.toString(),
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  Widget _buildTabContent(List<MensalidadesModel> lista) {
    final listaMesAno = lista
        .map((m) => '${m.month.toString().padLeft(2, '0')}/${m.year}')
        .toSet()
        .toList();

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
              Expanded(
                child: TabBarView(
                  children: listaMesAno.map((mesAnoRef) {
                    final listaFiltrada = lista.where((m) {
                      final refAtual =
                          '${m.month.toString().padLeft(2, '0')}/${m.year}';
                      if (refAtual != mesAnoRef) return false;

                      final nomeMatch = m.pfl_full_name
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase());
                      final isPago = m.tkt_paiment_path.isNotEmpty;

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
                        _buildBalancete(listaFiltrada, mesAnoRef),
                        Expanded(
                          child: ListView.builder(
                            itemCount: listaFiltrada.length,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
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
                      vertical: 8,
                      horizontal: 12,
                    ),
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
  }

  // ==========================================
  Widget _buildBalancete(List<MensalidadesModel> lista, String mesAnoRef) {
    final int totalPessoas = lista.length;
    final int quantasPagaram =
        lista.where((m) => m.tkt_paiment_path.isNotEmpty).length;

    final double totalValorPago = lista.fold<double>(0.0, (soma, m) {
      if (m.month.isNotEmpty) {
        final double valor = double.tryParse(m.tit_value.toString()) ?? 0.0;
        return soma + valor;
      }
      return soma;
    });

    final activeProfiles = bdProfileController.profilesNotifier.value
            ?.where((item) => item.as_ismonthlypayment == 'true')
            .toList() ??
        [];

    final partes = mesAnoRef.split('/');
    final int pendingCount = (activeProfiles.isNotEmpty && partes.length == 2)
        ? _getPendingProfilesForSelectedMonth(
            activeProfiles,
            bdMonthlyPaymentsController.monthlyPaymentsNotifier.value,
            partes[0],
            partes[1],
          ).length
        : 0;

    return Column(
      children: [
        Container(
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
        ),
        if (pendingCount > 0)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.shade900.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Existe(m) $pendingCount sócio(s) sem mensalidade gerada neste mês.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.amberAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    _abrirDialogGerarMensalidades(
                      initialMonth: partes[0],
                      initialYear: partes[1],
                    );
                  },
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text(
                    'Gerar Pendente(s)',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ==========================================
  Widget _buildMensalidadeCard(MensalidadesModel mensalidade) {
    final bool temComprovante = mensalidade.tkt_paiment_path.isNotEmpty;
    final bool isPago = temComprovante;

    final now = DateTime.now();
    final int mesRef = int.tryParse(mensalidade.month.toString()) ?? 0;
    final int anoRef = int.tryParse(mensalidade.year.toString()) ?? 0;
    final bool isMesAnoAtual = (mesRef == now.month) && (anoRef == now.year);

    double porcPorc = double.parse(mensalidade.pas_monthly_percent) / 100.0;
    double porcValor = double.parse(mensalidade.vpg_valor_desconto) * porcPorc;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.indigo.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
          Icons.calendar_month,
          color: isPago ? Colors.greenAccent : Colors.orangeAccent,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                mensalidade.pfl_full_name.isNotEmpty
                    ? mensalidade.pfl_full_name
                    : 'Sócio / Membro',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusBadge(isPago),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            'Ref: ${mensalidade.month.toString().padLeft(2, '0')}/${mensalidade.year} • '
            'Valor Base: ${generalService.currencyMoneyBr(mensalidade.vpg_valor_normal.toString())} • ${mensalidade.vpg_desc}',
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
                  'Detalhes da Mensalidade:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Desconto até dia: ${mensalidade.vpg_dia_valor_desconto.toString()} • '
                            'Valor: ${generalService.currencyMoneyBr(mensalidade.vpg_valor_desconto.toString())}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Porcentagem: ${mensalidade.pas_monthly_percent.toString()}%  • '
                            'Valor: ${generalService.currencyMoneyBr(porcValor.toString())}',
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
                        mensalidade.tit_unit_value.toString(),
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (temComprovante)
                      OutlinedButton.icon(
                        onPressed: () => _mostrarComprovante(
                          context,
                          mensalidade.tkt_paiment_path,
                        ),
                        icon: const Icon(Icons.image_search, size: 16),
                        label: const Text('Ver Comprovante'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orangeAccent,
                          side: const BorderSide(color: Colors.orangeAccent),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    Wrap(
                      spacing: 4,
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        IconButton(
                          tooltip: 'Editar Mensalidade',
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: Colors.blueAccent,
                          ),
                          onPressed: () => _editarMensalidade(
                            context,
                            mensalidade,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Excluir Mensalidade',
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _confirmarExclusaoMensalidade(
                            context,
                            mensalidade,
                          ),
                        ),
                        if (!isPago && isMesAnoAtual) ...[
                          const SizedBox(width: 4),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                            ),
                            onPressed: () {
                              debugPrint(
                                'Ir para pagamento do perfil: ${mensalidade.pfl_full_name}',
                              );
                            },
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
                      ],
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

  // ==========================================
  Widget _buildStatusBadge(bool isPago) {
    String label = isPago ? 'PAGO' : 'PENDENTE';
    Color color = isPago ? Colors.greenAccent : Colors.orangeAccent;
    Color bgColor =
        (isPago ? Colors.green : Colors.orange).withValues(alpha: 0.15);

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

  // ==========================================
  void _mostrarComprovante(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Comprovante de Pagamento',
          style: TextStyle(fontSize: 16),
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

// ==========================================
// DIALOG DE GERAR MENSALIDADE COM SUPORTE A PESSOA E PERÍODO (INÍCIO - FIM)
// ==========================================
class _AddMonthlyGenerationDialog extends StatefulWidget {
  final String hldId;
  final BdPaymentValueController bdPaymentValueController;
  final BdProfileController bdProfileController;
  final BdMonthlyPaymentsController bdMonthlyPaymentsController;
  final GeneralService generalService;
  final String? initialMonth;
  final String? initialYear;

  const _AddMonthlyGenerationDialog({
    required this.hldId,
    required this.bdPaymentValueController,
    required this.bdProfileController,
    required this.bdMonthlyPaymentsController,
    required this.generalService,
    this.initialMonth,
    this.initialYear,
  });

  @override
  State<_AddMonthlyGenerationDialog> createState() =>
      _AddMonthlyGenerationDialogState();
}

class _AddMonthlyGenerationDialogState
    extends State<_AddMonthlyGenerationDialog> {
  final _formKey = GlobalKey<FormState>();
  final startReferencia = TextEditingController();
  final endReferencia = TextEditingController();
  final profilesScrollController = ScrollController();

  final vpgValueNotifier = ValueNotifier<String?>(null);
  final selectedProfileNotifier = ValueNotifier<VProfileModel?>(null);

  final mStartNotifier = ValueNotifier<String?>(null);
  final yStartNotifier = ValueNotifier<String?>(null);
  final mEndNotifier = ValueNotifier<String?>(null);
  final yEndNotifier = ValueNotifier<String?>(null);

  List<_PendingGenerationItem> filteredItems = [];
  List listaFormas = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final mStr = widget.initialMonth ?? now.month.toString().padLeft(2, '0');
    final yStr = widget.initialYear ?? now.year.toString();

    mStartNotifier.value = mStr;
    yStartNotifier.value = yStr;
    startReferencia.text = '$mStr/$yStr';

    mEndNotifier.value = mStr;
    yEndNotifier.value = yStr;
    endReferencia.text = '$mStr/$yStr';
  }

  @override
  void dispose() {
    startReferencia.dispose();
    endReferencia.dispose();
    profilesScrollController.dispose();
    vpgValueNotifier.dispose();
    selectedProfileNotifier.dispose();
    mStartNotifier.dispose();
    yStartNotifier.dispose();
    mEndNotifier.dispose();
    yEndNotifier.dispose();
    super.dispose();
  }

  void _exibirSeletorMesAno({required bool isStart}) async {
    final now = DateTime.now();
    DateTime initialDate = now;

    if (isStart && mStartNotifier.value != null && yStartNotifier.value != null) {
      initialDate = DateTime(
        int.parse(yStartNotifier.value!),
        int.parse(mStartNotifier.value!),
      );
    } else if (!isStart && mEndNotifier.value != null && yEndNotifier.value != null) {
      initialDate = DateTime(
        int.parse(yEndNotifier.value!),
        int.parse(mEndNotifier.value!),
      );
    }

    final DateTime? selectedDate = await showMonthPicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 2, 1, 1),
      lastDate: DateTime(now.year + 5, 12, 31),
      monthPickerDialogSettings: const MonthPickerDialogSettings(
        dialogSettings: PickerDialogSettings(locale: Locale('pt', 'BR')),
      ),
    );

    if (selectedDate != null) {
      final mStr = selectedDate.month.toString().padLeft(2, '0');
      final yStr = selectedDate.year.toString();

      setState(() {
        if (isStart) {
          mStartNotifier.value = mStr;
          yStartNotifier.value = yStr;
          startReferencia.text = '$mStr/$yStr';

          // Garante que a data final seja no mínimo igual à inicial
          if (mEndNotifier.value == null || yEndNotifier.value == null) {
            mEndNotifier.value = mStr;
            yEndNotifier.value = yStr;
            endReferencia.text = '$mStr/$yStr';
          } else {
            final endDT = DateTime(
              int.parse(yEndNotifier.value!),
              int.parse(mEndNotifier.value!),
            );
            if (endDT.isBefore(selectedDate)) {
              mEndNotifier.value = mStr;
              yEndNotifier.value = yStr;
              endReferencia.text = '$mStr/$yStr';
            }
          }
        } else {
          mEndNotifier.value = mStr;
          yEndNotifier.value = yStr;
          endReferencia.text = '$mStr/$yStr';
        }
      });
    }
  }

  Future<void> _insertMonthlyGeneration() async {
    if (!_formKey.currentState!.validate()) return;

    if (filteredItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não há mensalidades pendentes para o período e pessoa selecionados.'),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final produtoEncontrado = listaFormas.firstWhere(
        (fpg) => fpg.vpg_id == vpgValueNotifier.value,
      );

      String desc =
          'Valor de: ${widget.generalService.currencyMoneyBr(produtoEncontrado.vpg_valor_normal)} até dia ${produtoEncontrado.vpg_dia_valor_normal}';
      final double tmpValor = double.parse(
        produtoEncontrado.vpg_valor_normal,
      );

      final List<Map<String, dynamic>> dadosParaInserir =
          filteredItems.map((item) {
        double percentValue =
            double.parse(item.profile.pas_monthly_percent.toString());
        percentValue = tmpValor * (percentValue / 100);

        return {
          'p_hld_id': item.profile.hld_id,
          'p_pfl_id': item.profile.pfl_id,
          'p_pfl_name': item.profile.pfl_full_name,
          'p_date_start': item.monthDate,
          'p_desc': '$desc consid. ${item.profile.pas_monthly_percent}%',
          'p_tss_id': 2,
          'p_table_number': -1,
          'p_pdt_id': 33,
          'p_pdt_quant': 1,
          'p_valor': percentValue.toString(),
          'p_tkt_vpg_id': vpgValueNotifier.value.toString(),
          'p_tkt_pas_id': item.profile.pas_id.toString(),
        };
      }).toList();

      await widget.bdMonthlyPaymentsController.insertMonthlyGeneration(
        dadosParaInserir,
      );

      final currentError =
          widget.bdMonthlyPaymentsController.errorNotifier.value;

      if (mounted && (currentError == null || currentError.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mensalidades geradas com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro no processamento: $e'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
          maxWidth: 600,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Gerar Mensalidades',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed:
                          _isSaving ? null : () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),
                
                // 1. Dropdown para seleção de Pessoa / Sócio
                ValueListenableBuilder<List<VProfileModel>?>(
                  valueListenable: widget.bdProfileController.profilesNotifier,
                  builder: (context, profiles, _) {
                    final activeProfiles = profiles
                            ?.where((item) => item.as_ismonthlypayment == 'true')
                            .toList() ??
                        [];

                    return DropdownButtonFormField<VProfileModel?>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Selecionar Pessoa / Sócio',
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text(
                        'Todas as Pessoas (Pendentes no período)',
                        style: TextStyle(fontSize: 14),
                      ),
                      items: [
                        const DropdownMenuItem<VProfileModel?>(
                          value: null,
                          child: Text(
                            'Todas as Pessoas (Pendentes no período)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...activeProfiles.map(
                          (p) => DropdownMenuItem<VProfileModel?>(
                            value: p,
                            child: Text(
                              p.pfl_full_name,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                      initialValue: selectedProfileNotifier.value,
                      onChanged: _isSaving
                          ? null
                          : (value) {
                              setState(() {
                                selectedProfileNotifier.value = value;
                              });
                            },
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 2. Seleção de Período: Início e Fim
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: startReferencia,
                        readOnly: true,
                        enabled: !_isSaving,
                        onTap: () => _exibirSeletorMesAno(isStart: true),
                        decoration: const InputDecoration(
                          labelText: 'Período Início',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Início obrigatório';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: endReferencia,
                        readOnly: true,
                        enabled: !_isSaving,
                        onTap: () => _exibirSeletorMesAno(isStart: false),
                        decoration: const InputDecoration(
                          labelText: 'Período Fim',
                          prefixIcon: Icon(Icons.event),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Fim obrigatório';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. Dropdown de Valor da Mensalidade
                ListenableBuilder(
                  listenable:
                      widget.bdPaymentValueController.bdPaymentValueNotifier,
                  builder: (context, _) {
                    listaFormas = widget
                        .bdPaymentValueController.bdPaymentValueNotifier.value;

                    return DropdownButtonFormField2<String>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text(
                        'Selecione o Valor da Mensalidade',
                        style: TextStyle(fontSize: 14),
                      ),
                      items: listaFormas
                          .map(
                            (item) => DropdownItem<String>(
                              value: item.vpg_id,
                              child: Text(
                                '${item.vpg_desc} valor de: ${widget.generalService.currencyMoneyBr(item.vpg_valor_normal)} até dia ${item.vpg_dia_valor_normal}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                      valueListenable: vpgValueNotifier,
                      validator: (value) {
                        if (value == null) {
                          return 'Selecione o valor da mensalidade.';
                        }
                        return null;
                      },
                      onChanged: _isSaving
                          ? null
                          : (value) {
                              vpgValueNotifier.value = value;
                            },
                      dropdownStyleData: DropdownStyleData(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.grey.shade900,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 4. Lista / Pré-visualização das Mensalidades a Gerar
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Mensalidades a Gerar',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(12),
                    ),
                    child: ValueListenableBuilder<List<VProfileModel>?>(
                      valueListenable: widget.bdProfileController.profilesNotifier,
                      builder: (context, profilesHistory, _) {
                        final existingPayments = widget
                            .bdMonthlyPaymentsController
                            .monthlyPaymentsNotifier
                            .value;

                        filteredItems = _getPendingItemsToGenerate(
                          profilesHistory,
                          existingPayments,
                          selectedProfileNotifier.value,
                          mStartNotifier.value,
                          yStartNotifier.value,
                          mEndNotifier.value,
                          yEndNotifier.value,
                        );

                        if (startReferencia.text.isEmpty || endReferencia.text.isEmpty) {
                          return const Center(
                            child: Text(
                              'Selecione o período para visualizar os itens pendentes.',
                              style: TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        if (filteredItems.isEmpty) {
                          return const Center(
                            child: Text(
                              'Todas as mensalidades já foram geradas para este período/pessoa.',
                              style: TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        return Scrollbar(
                          controller: profilesScrollController,
                          thumbVisibility: true,
                          child: ListView.builder(
                            controller: profilesScrollController,
                            itemCount: filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = filteredItems[index];
                              final refMonth = item.monthDate.month.toString().padLeft(2, '0');
                              final refYear = item.monthDate.year.toString();

                              return Card(
                                elevation: 1,
                                margin: const EdgeInsets.only(bottom: 6.0),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.profile.pfl_full_name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              'Ref: $refMonth/$refYear • Porcentagem: ${item.profile.pas_monthly_percent}%',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 5. Botões do Dialog
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _isSaving ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            _isSaving ? null : _insertMonthlyGeneration,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check),
                        label: Text(_isSaving ? 'Gerando...' : 'Confirmar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}