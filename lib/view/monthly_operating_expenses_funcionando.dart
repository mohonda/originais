import 'package:flutter/material.dart';
import 'package:originais/view/default_appbar.dart';
import 'package:originais/services/general_service.dart';
import 'package:originais/controllers/ticket_controller.dart';
import 'package:originais/controllers/headquarters_bar_controller.dart';
import 'package:originais/view/default_snackbar.dart';
import 'package:originais/controllers/products_controller.dart'; 
import 'package:originais/models/ticket_model.dart'; 

class MonthlyOperatingExpenses extends StatefulWidget {
  final String? pflId;
  final String? hldId;
  final String? tssId;
  
  const MonthlyOperatingExpenses({
    super.key,
    this.pflId,
    this.hldId,
    this.tssId,
  });

  @override
  State<MonthlyOperatingExpenses> createState() => MonthlyOperatingExpensesState();
}

class MonthlyOperatingExpensesState extends State<MonthlyOperatingExpenses> {
  late final TicketController ticketController;
  late final BdHeadquartersBarController barController;
  late final ProductsController productsController;
  final gService = GeneralService();

  // Mapeia os tickets carregados por ID da barra
  final Map<String, List<dynamic>> _ticketsByBar = {};

  @override
  void initState() {
    super.initState();
    ticketController = TicketController();
    barController = BdHeadquartersBarController();
    productsController = ProductsController();
    
    _loadData();
    
    DefaultSnackbar.attachErrorListener(context, barController.errorNotifier);
    DefaultSnackbar.attachSuccessListener(context, barController.successNotifier);
  }

  Future<void> _loadData() async {
    _ticketsByBar.clear();

    await barController.loadHeadquartersBar(
      widget.hldId.toString(), 
      widget.tssId.toString(),
    );
   
    await productsController.loadProductsFiltered(
      widget.hldId.toString(), 
      '8',
    );

    // Carrega os tickets de cada barra antes de renderizar a tela
    final itens = barController.headquartersBarNotifier.value;
    for (final barItem in itens) {
      final String barId = barItem.bar_id.toString();
      await ticketController.loadTicketsBarTypeSales(
        barId: barId,
        tssId: barItem.bar_tss_id,
        hldId: barItem.bar_hld_id,
      );
      _ticketsByBar[barId] = List.from(ticketController.ticketsBarTypeSalesNotifier.value);
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DefaultAppbar(title: 'Monthly Operating Expenses'),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          barController.loadingNotifier,
          barController.errorNotifier,
          barController.headquartersBarNotifier,
          productsController.productsFilteredNotifier,
        ]),
        builder: (context, _) {
          final isLoading = barController.loadingNotifier.value || ticketController.loadingNotifier.value;
          final errorMessage = barController.errorNotifier.value;
          final itens = barController.headquartersBarNotifier.value;

          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Stack(
                      children: [
                        (errorMessage != null && errorMessage.isNotEmpty && itens.isEmpty)
                            ? _buildErrorState(errorMessage)
                            : RefreshIndicator(
                                onRefresh: _loadData,
                                color: Colors.green,
                                child: (itens.isEmpty && !isLoading)
                                    ? _buildEmptyState()
                                    : _buildListView(itens, isLoading),
                              ),
                        Positioned(
                          bottom: 16.0,
                          right: 16.0,
                          child: FloatingActionButton(
                            heroTag: 'addExpenseFab',
                            elevation: 2,
                            backgroundColor: Colors.indigo,
                            onPressed: isLoading ? null : addExpenseDetails,
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: Center(
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(width: 16),
                              Text(
                                'Processando requisição...',
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

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(errorMessage, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<dynamic> itens, bool isLoading) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80.0),
      itemCount: itens.length,
      itemBuilder: (context, index) {
        return _buildExpenseCard(itens[index], isLoading);
      },
    );
  }

  Widget _buildExpenseCard(dynamic barItem, bool isLoading) {
    final List products = productsController.productsFilteredNotifier.value;
    final String barId = barItem.bar_id.toString();
    final List tickets = _ticketsByBar[barId] ?? [];

    // Soma do consumo total de todos os tickets da barra
    final double totalDespesas = tickets.fold<double>(0.0, (soma, tkt) {
      final val = tkt.totalConsumo ?? 0.0;
      return soma + (double.tryParse(val.toString()) ?? 0.0);
    });

    final String statusStr = barItem.tss_desc ?? 'Ativo';
    
    final partes = barItem.bar_open_date.split('-');
    final String ano = partes[0];
    final String mes = partes[1];

    final String descricaoOuRef = 'Ref.: ${mes}/${ano}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.indigo.withValues(alpha: 0.3), width: 1),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: const Icon(Icons.receipt_long, color: Colors.indigoAccent),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    descricaoOuRef,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    'Abertura: ${gService.formatarDataBr(barItem.bar_open_date)}',
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusBadge(gService.currencyMoneyBr(totalDespesas.toString())),
          ],
        ),
        // subtitle: Padding(
        //   padding: const EdgeInsets.only(top: 4.0),
        //   child: Text(
        //     'Abertura: ${barItem.bar_open_date ?? "-"}',
        //     style: const TextStyle(fontSize: 11, color: Colors.white70),
        //   ),
        // ),
        children: [
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.all(12.0),
            color: Colors.black12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Detalhes das Despesas:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
                    ),
                    Text(
                      '${tickets.length} despesa(s)',
                      style: const TextStyle(fontSize: 11, color: Colors.white54),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (tickets.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Nenhum item cadastrado nesta despesa.',
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.white54, fontSize: 12),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tickets.length,
                    separatorBuilder: (_, __) => const Divider(height: 12, color: Colors.white10),
                    itemBuilder: (context, subIndex) {
                      final tkt = tickets[subIndex];
                      final tktItems = tkt.ticketsItems as List?;
                      final item = (tktItems != null && tktItems.isNotEmpty) ? tktItems.first : null;

                      final String nomeSubItem = item?.pdt_name?.toString() ??
                          tkt.tkt_client_name?.toString() ??
                          'Item sem nome';

                      final String vencimento = tkt.tkt_bar_open_date ?? '-';
                      final rawVal = item?.tit_value ?? tkt.totalConsumo ?? 0.0;
                      final double valor = double.tryParse(rawVal.toString()) ?? 0.0;

                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nomeSubItem,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                                if (vencimento != '-')
                                  Text(
                                    'Deadline: ${gService.formatarDataBr(vencimento)}',
                                    style: const TextStyle(fontSize: 11, color: Colors.white54),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            gService.currencyMoneyBr(valor.toString()),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // BOTÃO EDITAR ITEM
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.lightBlueAccent),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Editar Item',
                            onPressed: isLoading
                                ? null
                                : () => editExpenseItem(tkt, item, barItem.bar_open_date?.toString(), barItem.bar_id),
                          ),
                          const SizedBox(width: 12),
                          // BOTÃO EXCLUIR ITEM
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.orangeAccent),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Excluir Item',
                            onPressed: isLoading ? null : () => deleteExpenseItem(tkt, item ),
                          ),
                        ],
                      );
                    },
                  ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      onPressed: isLoading ? null : () => deleteExpense(barId),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Excluir'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orangeAccent,
                        side: const BorderSide(color: Colors.orangeAccent),
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: isLoading ? null : () =>
                        addItemToExpenseTicket(barId, products, barItem.bar_open_date?.toString()),
                      icon: const Icon(Icons.add_shopping_cart, size: 16),
                      label: const Text(
                        'Incluir Item',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
// ==========================================
// EDITA A DATA E O VALOR DO ITEM
// ==========================================
Future<void> editExpenseItem(
  dynamic ticket,
  dynamic ticketItem,
  String? barOpenDate,
  String barId,
) async {
  final String itemName = ticketItem?.pdt_name?.toString() ??
      ticket.tkt_client_name?.toString() ??
      'Item Despesa';

  final String currentDate = ticket.tkt_bar_open_date ?? '';
  final double currentVal = double.tryParse(
        (ticketItem?.tit_value ?? ticket.totalConsumo ?? 0.0).toString(),
      ) ??
      0.0;

  final result = await _showEditExpenseItemDialog(
    context: context,
    itemName: itemName,
    currentDate: currentDate,
    currentValue: currentVal,
    barOpenDate: barOpenDate,
  );

  if (result != null && context.mounted) {
    final String updatedDate = result['dueDate'];
    final double updatedValue = result['value'];

    final String tktId = ticket.tkt_id.toString();
    final String titId = ticketItem?.tit_id?.toString() ?? '';

    // Atualiza os dados do ticket/item via controller
    if (titId.isNotEmpty) {
      await ticketController.updateTicketsItems_value(
        titId,
        1,
        updatedValue,
        barId,
        barOpenDate.toString(),
        widget.hldId.toString()
      );
    }

    await ticketController.updateTicketsDate(tktId,updatedDate);

    _loadData();
  }
}

// ==========================================
// EXCLUI UM ITEM INDIVIDUALMENTE
// ==========================================
Future<void> deleteExpenseItem(dynamic ticket, dynamic item) async {
  final bool? confirmar = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Excluir Item'),
        content: const Text('Tem certeza que deseja remover este item da despesa?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );

  if (confirmar == true && context.mounted) {
    final String tktId = ticket.tkt_id.toString();
    final String titId = item.tit_id.toString();
    await ticketController.deleteTit( titId );
    await ticketController.deleteTkt( tktId );
    _loadData();
  }
}

  // ==========================================
  // DIÁLOGO DE EDIÇÃO (DATA RESTRITA AO MÊS DA BARRA)
  // ==========================================
  Future<Map<String, dynamic>?> _showEditExpenseItemDialog({
    required BuildContext context,
    required String itemName,
    required String currentDate,
    required double currentValue,
    String? barOpenDate,
  }) {
    // Configuração dos limites de data (restrito ao mês da barra)
    final DateTime parsedBarDate = DateTime.tryParse(barOpenDate ?? '') ?? DateTime.now();
    final DateTime firstDate = DateTime(parsedBarDate.year, parsedBarDate.month, 1);
    final DateTime lastDate = DateTime(parsedBarDate.year, parsedBarDate.month + 1, 0);

    DateTime selectedDueDate = DateTime.tryParse(currentDate) ?? firstDate;
    if (selectedDueDate.isBefore(firstDate) || selectedDueDate.isAfter(lastDate)) {
      selectedDueDate = firstDate;
    }

    final TextEditingController valueController = TextEditingController(
      text: currentValue.toStringAsFixed(2).replaceAll('.', ','),
    );
    final formKey = GlobalKey<FormState>();

    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.edit_note, color: Colors.blueAccent),
                  SizedBox(width: 8),
                  Text('Editar Item', style: TextStyle(fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Item: $itemName',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      const Text('Data de Vencimento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDueDate,
                            firstDate: firstDate,
                            lastDate: lastDate,
                          );
                          if (picked != null) setState(() => selectedDueDate = picked);
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            suffixIcon: const Icon(Icons.calendar_today, size: 20),
                          ),
                          child: Text(
                            '${selectedDueDate.day.toString().padLeft(2, '0')}/${selectedDueDate.month.toString().padLeft(2, '0')}/${selectedDueDate.year}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Valor (R\$)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: valueController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: '0,00',
                          prefixText: 'R\$ ',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Informe o valor';
                          final parsedValue = double.tryParse(value.replaceAll(',', '.'));
                          if (parsedValue == null || parsedValue <= 0) return 'Informe um valor válido';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final double valor = double.parse(valueController.text.replaceAll(',', '.'));
                      final String dueDateFormatted =
                          '${selectedDueDate.year}-${selectedDueDate.month.toString().padLeft(2, '0')}-${selectedDueDate.day.toString().padLeft(2, '0')}';

                      Navigator.pop(context, {
                        'dueDate': dueDateFormatted,
                        'value': valor,
                      });
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    bool isAtivo = status.toLowerCase() == 'ativo' || status.toLowerCase() == 'pago';
    String label = status.toUpperCase();
    Color color = isAtivo ? Colors.greenAccent : Colors.orangeAccent;
    Color bgColor = (isAtivo ? Colors.green : Colors.orange).withValues(alpha: 0.15);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent),
      ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: const Center(child: Text('Nenhum item cadastrado.')),
          ),
        );
      },
    );
  }

  Future<void> addExpenseDetails() async {
    final itens = barController.headquartersBarNotifier.value;

    // 1. Coleta mês/ano de todas as barras já cadastradas no formato "YYYY-MM"
    final Set<String> registeredPeriods = {};
    for (final item in itens) {
      if (item.bar_open_date != null) {
        final parsed = DateTime.tryParse(item.bar_open_date.toString());
        if (parsed != null) {
          final yearMonth = '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}';
          registeredPeriods.add(yearMonth);
        }
      }
    }

    // 2. Abre o diálogo passando a lista de períodos bloqueados
    final result = await _showMonthYearPickerDialog(
      context: context,
      registeredPeriods: registeredPeriods,
    );

    if (result != null && context.mounted) {
      final int selectedMonth = result['month']!;
      final int selectedYear = result['year']!;

      final String dataParaBd = '$selectedYear-${selectedMonth.toString().padLeft(2, '0')}-01';
      
      await barController.openHeadquartersBar(
        widget.pflId.toString(),
        widget.hldId.toString(),
        dataParaBd,
        'Ref.: ${selectedMonth.toString().padLeft(2, '0')}/${selectedYear.toString()}',
        widget.tssId.toString(),
      );

      _loadData();
    }
  }

  Future<Map<String, int>?> _showMonthYearPickerDialog({
    required BuildContext context,
    required Set<String> registeredPeriods,
  }) {
    final DateTime now = DateTime.now();

    // Lista de anos disponíveis (Ano atual até +5 anos)
    final List<int> years = List.generate(6, (index) => now.year + index);

    // Função para verificar se o mês/ano está livre
    bool isPeriodAvailable(int year, int month) {
      final key = '$year-${month.toString().padLeft(2, '0')}';
      return !registeredPeriods.contains(key);
    }

    // Encontra o primeiro ano/mês válido para inicializar a tela
    int initialYear = now.year;
    int initialMonth = now.month;

    bool foundInitial = false;
    for (final y in years) {
      final startM = (y == now.year) ? now.month : 1;
      for (int m = startM; m <= 12; m++) {
        if (isPeriodAvailable(y, m)) {
          initialYear = y;
          initialMonth = m;
          foundInitial = true;
          break;
        }
      }
      if (foundInitial) break;
    }

    int currentYear = initialYear;
    int currentMonth = initialMonth;

    return showDialog<Map<String, int>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Filtra apenas os meses livres para o ano selecionado
            final int minMonth = (currentYear == now.year) ? now.month : 1;
            final List<int> availableMonths = [];

            for (int m = minMonth; m <= 12; m++) {
              if (isPeriodAvailable(currentYear, m)) {
                availableMonths.add(m);
              }
            }

            // Se o mês atual não estiver disponível na troca de ano, seleciona o primeiro disponível
            if (availableMonths.isNotEmpty && !availableMonths.contains(currentMonth)) {
              currentMonth = availableMonths.first;
            }

            return AlertDialog(
              title: const Text('Selecione o Período'),
              content: availableMonths.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        'Todos os meses deste ano já foram cadastrados.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.orangeAccent),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Mês', style: TextStyle(fontWeight: FontWeight.bold)),
                            DropdownButton<int>(
                              value: availableMonths.contains(currentMonth) ? currentMonth : null,
                              items: availableMonths.map((month) {
                                return DropdownMenuItem<int>(
                                  value: month,
                                  child: Text(month.toString().padLeft(2, '0')),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => currentMonth = value);
                                }
                              },
                            ),
                          ],
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Ano', style: TextStyle(fontWeight: FontWeight.bold)),
                            DropdownButton<int>(
                              value: currentYear,
                              items: years.map((year) {
                                return DropdownMenuItem<int>(
                                  value: year,
                                  child: Text(year.toString()),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    currentYear = value;
                                    // Recalcula o mês ao trocar de ano
                                    final newMin = (currentYear == now.year) ? now.month : 1;
                                    final newMonths = List.generate(13 - newMin, (i) => newMin + i)
                                        .where((m) => isPeriodAvailable(currentYear, m))
                                        .toList();
                                    if (newMonths.isNotEmpty) {
                                      currentMonth = newMonths.first;
                                    }
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: availableMonths.isEmpty
                      ? null
                      : () {
                          Navigator.pop(context, {
                            'month': currentMonth,
                            'year': currentYear,
                          });
                        },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> addItemToExpenseTicket(
    String barId,
    List<dynamic> availableItems,
    String? barOpenDate,
  ) async {
    // 1. Obtém os tickets/itens já cadastrados nesta barra
    final List tickets = _ticketsByBar[barId] ?? [];

    // 2. Extrai os IDs dos produtos que já possuem lançamento
    final Set<String> registeredPdtIds = {};
    for (final tkt in tickets) {
      final tktItems = tkt.ticketsItems as List?;
      if (tktItems != null) {
        for (final item in tktItems) {
          final String? pdtId = item.tit_pdt_id?.toString() ?? item.pdt_id?.toString();
          if (pdtId != null) {
            registeredPdtIds.add(pdtId);
          }
        }
      }
    }

    // 3. Filtra mantendo APENAS os itens que NÃO foram cadastrados ainda
    final unaddedItems = availableItems.where((product) {
      final String? pdtId = product.pdt_id?.toString();
      return pdtId != null && !registeredPdtIds.contains(pdtId);
    }).toList();

    // 4. Se todos os itens disponíveis já estiverem lançados, exibe aviso
    if (unaddedItems.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todos os itens disponíveis já foram cadastrados nesta despesa.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // 5. Exibe o diálogo com a lista filtrada de itens pendentes
    final result = await _showAddExpenseItemDialog(
      context: context,
      availableItems: unaddedItems,
      barOpenDate: barOpenDate,
    );

    if (result != null && context.mounted) {
      final selectedItem = result['item'];
      final String dueDate = result['dueDate'];
      final double value = result['value'];

      final ticketId = await ticketController.insertTickets(
        hldId: widget.hldId.toString(),
        openDate: dueDate,
        nTable: '-1',
        clienteName: selectedItem.pdt_name?.toString() ?? 'Item Despesa',
        pflId: widget.pflId.toString(),
        barId: barId,
      );

      final ticketsItems2Controller = TicketsItemsModel(
        tit_hld_id: widget.hldId.toString(),
        tit_tkt_id: ticketId.toString(),
        tit_pdt_id: selectedItem.pdt_id?.toString() ?? selectedItem.toString(),
        tit_quantities: 1,
        tit_unit_value: value,
        tit_value: value,
      );

      await ticketController.insertTicketsItems(
        ticketsItems2Controller,
        barId,
        dueDate,
        widget.hldId.toString(),
      );

      _loadData();
    }
  }

  Future<Map<String, dynamic>?> _showAddExpenseItemDialog({
    required BuildContext context,
    required List<dynamic> availableItems,
    String? barOpenDate,
  }) {
    dynamic selectedItem = availableItems.isNotEmpty ? availableItems.first : null;

    // Converte a data da barra (ex: "2026-09-01")
    final DateTime parsedBarDate = DateTime.tryParse(barOpenDate ?? '') ?? DateTime.now();

    // Limite: 1º dia do mês e último dia do mês
    final DateTime firstDate = DateTime(parsedBarDate.year, parsedBarDate.month, 1);
    final DateTime lastDate = DateTime(parsedBarDate.year, parsedBarDate.month + 1, 0);

    // Data inicial padrão definida para o primeiro dia do mês da barra
    DateTime selectedDueDate = firstDate;
    
    final TextEditingController valueController = TextEditingController(
      text: selectedItem != null ? selectedItem.pdt_value_member?.toString() ?? '' : '',
    );
    final formKey = GlobalKey<FormState>();

    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.add_shopping_cart, color: Colors.blueGrey),
                  SizedBox(width: 8),
                  Text('Adicionar Despesa', style: TextStyle(fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Item a pagar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<dynamic>(
                        value: selectedItem,
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: availableItems.map((item) {
                          final String itemDesc = '${item.pdt_name} / ${gService.currencyMoneyBr(item.pdt_value_member)}';
                          return DropdownMenuItem<dynamic>(value: item, child: Text(itemDesc, overflow: TextOverflow.ellipsis));
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedItem = value;
                              valueController.text = value.pdt_value_member?.toString() ?? '';
                            });
                          }
                        },
                        validator: (value) => value == null ? 'Selecione um item' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text('Data de Vencimento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDueDate,
                            firstDate: firstDate, // Bloqueia meses/anos anteriores
                            lastDate: lastDate,   // Bloqueia meses/anos posteriores
                          );
                          if (picked != null) setState(() => selectedDueDate = picked);
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            suffixIcon: const Icon(Icons.calendar_today, size: 20),
                          ),
                          child: Text(
                            '${selectedDueDate.day.toString().padLeft(2, '0')}/${selectedDueDate.month.toString().padLeft(2, '0')}/${selectedDueDate.year}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Valor (R\$)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: valueController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: '0,00',
                          prefixText: 'R\$ ',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Informe o valor';
                          final parsedValue = double.tryParse(value.replaceAll(',', '.'));
                          if (parsedValue == null || parsedValue <= 0) return 'Informe um valor válido';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final double valor = double.parse(valueController.text.replaceAll(',', '.'));
                      final String dueDateFormatted =
                          '${selectedDueDate.year}-${selectedDueDate.month.toString().padLeft(2, '0')}-${selectedDueDate.day.toString().padLeft(2, '0')}';
                      
                      Navigator.pop(context, {
                        'item': selectedItem,
                        'dueDate': dueDateFormatted,
                        'value': valor,
                      });
                    }
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> deleteExpense(String barId) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: const Text('Tem certeza que deseja apagar este item?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Excluir', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirmar == true && context.mounted) {
      await barController.deleteBar(barId);
      debugPrint(barId.toString());
      final error = barController.errorNotifier.value;
      if (context.mounted && (error == null || error.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item excluído com sucesso!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadData();
      }
    }
  }
}