import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:originais/controllers/headquarters_bar_controller.dart';
import 'package:originais/services/general_service.dart';
import 'package:originais/models/custom_app_bar.dart';
import 'package:originais/view/custom_month_calendar.dart';
import 'package:originais/view/headquartersbar_opened.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:originais/controllers/profile_controller.dart';
import 'package:originais/controllers/products_controller.dart';
import 'package:originais/controllers/ticket_controller.dart';

class HeadquartersBar extends StatefulWidget {
  const HeadquartersBar({super.key});

  @override
  State<HeadquartersBar> createState() => HeadquartersBarState();
}

class HeadquartersBarState extends State<HeadquartersBar> {
  final GeneralService generalService = GeneralService();

  final bdHeadquartersBarController =
      getItBdHeadquartersBarController<BdHeadquartersBarController>();

  final bdProfileController = getItBdProfileController<BdProfileController>();
  final productsController = getItProductsController<ProductsController>();
  final ticketController = getItTicketController<TicketController>();

  final _formKey = GlobalKey<FormState>();
  final bar_desc = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  List<DateTime> _openDays = [];
  bool _isLocaleInitialized = false;

  late String pflId = '';
  late String hldId = '';

  final String typeSales = '1';

  // ==========================================
  @override
  void initState() {
    super.initState();
    initValues();

    pflId = bdProfileController.pessoaSelecionadaNotifier.value?.pfl_id ?? '';
    hldId = bdProfileController.pessoaSelecionadaNotifier.value?.hld_id ?? '';

    // Escuta alterações nos notificadores de dados e erros
    bdHeadquartersBarController.headquartersBarNotifier
        .addListener(_onHeadquartersBarChanged);
    bdHeadquartersBarController.errorNotifier.addListener(_onErrorChanged);
    productsController.errorNotifier.addListener(_onErrorChanged);
    ticketController.errorNotifier.addListener(_onErrorChanged);

    _carregarDadosIniciais();
  }

  // ==========================================
  @override
  void dispose() {
    bdHeadquartersBarController.headquartersBarNotifier
        .removeListener(_onHeadquartersBarChanged);

    bdHeadquartersBarController.errorNotifier
      .removeListener(_onErrorChanged);

    productsController.errorNotifier
      .removeListener(_onErrorChanged);
    ticketController.errorNotifier
      .removeListener(_onErrorChanged);

    bdHeadquartersBarController.disposeRealtime();
    bar_desc.dispose();
    super.dispose();
  }

  // ==========================================
  void _onErrorChanged() {
    final error = bdHeadquartersBarController.errorNotifier.value ??
        productsController.errorNotifier.value ??
        ticketController.errorNotifier.value;

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
  void initValues() {
    initializeDateFormatting('pt_BR', null).then((_) {
      if (mounted) {
        setState(() {
          _isLocaleInitialized = true;
        });
      }
    });
  }

  // ==========================================
  Future<void> _carregarDadosIniciais() async {
    await bdHeadquartersBarController.loadHeadquartersBar(hldId, typeSales);
    bdHeadquartersBarController.initRealtime(hldId, typeSales);
  }

  // ==========================================
  void _onHeadquartersBarChanged() {
    final barrasAbertas =
        bdHeadquartersBarController.headquartersBarNotifier.value;

    List<DateTime> datas = barrasAbertas.map((bar) {
      return DateTime.parse(bar.bar_open_date.toString());
    }).toList();

    if (mounted) {
      setState(() {
        _openDays = datas;
      });
    }
  }

  // ==========================================
  @override
  Widget build(BuildContext context) {
    const double distance = 16.0;

    if (!_isLocaleInitialized) {
      return const Scaffold(
        appBar: CustomFloatingAppBar(title: 'Headquarters Bar'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: const CustomFloatingAppBar(title: 'Headquarters Bar'),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          bdHeadquartersBarController.loadingNotifier,
          productsController.loadingNotifier,
          ticketController.loadingNotifier,
        ]),
        builder: (context, _) {
          final bool isLoading =
              bdHeadquartersBarController.loadingNotifier.value ||
                  productsController.loadingNotifier.value ||
                  ticketController.loadingNotifier.value;

          if (isLoading && _openDays.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Expanded(
                            child: CustomMonthCalendar(
                              initialDate: _selectedDate,
                              openDays: _openDays,
                              minDate: DateTime(2026, 9, 1),
                              maxDate: DateTime.now(),
                              onlySelectPastOpenDays: true,
                              onDateSelected: (date) {
                                setState(() {
                                  _selectedDate = date;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: distance),
                          TextFormField(
                            controller: bar_desc,
                            keyboardType: TextInputType.text,
                            maxLength: 50,
                            textAlign: TextAlign.start,
                            enabled: !isLoading,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Description:',
                              prefixIcon: Icon(Icons.info),
                              border: OutlineInputBorder(),
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: distance),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: isLoading
                                      ? null
                                      : () async {
                                          if (_formKey.currentState!
                                              .validate()) {
                                            openHeadquartersBar();
                                          }
                                        },
                                  icon: isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.save),
                                  label: Text(
                                      isLoading ? 'Processando...' : 'Open'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigo,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
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
              ),

              if (isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.2),
                    child: Center(
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 24.0, vertical: 16.0),
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

  // ==========================================
  void openHeadquartersBar() async {
    String openDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final now = DateTime.now();

    late DateTime hojeOperacional;
    if (now.hour < 6 || (now.hour == 6 && now.minute == 0)) {
      final ontem = now.subtract(const Duration(days: 1));
      hojeOperacional = DateTime(ontem.year, ontem.month, ontem.day);
    } else {
      hojeOperacional = DateTime(now.year, now.month, now.day);
    }

    final dataSelecionada = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    final bool isReadOnly = dataSelecionada.isBefore(hojeOperacional);

    final barrasAbertas =
        bdHeadquartersBarController.headquartersBarNotifier.value;

    dynamic barExistente = barrasAbertas.cast<dynamic>().firstWhere(
      (b) {
        final bDate = DateTime.parse(b.bar_open_date.toString());
        return bDate.year == _selectedDate.year &&
            bDate.month == _selectedDate.month &&
            bDate.day == _selectedDate.day;
      },
      orElse: () => null,
    );

    dynamic barId = barExistente?.bar_id ?? barExistente?.barId;

    if (barExistente == null && !isReadOnly) {
      final newBarId = await bdHeadquartersBarController.openHeadquartersBar(
        pflId,
        hldId,
        openDate,
        bar_desc.text,
        typeSales,
      );

      if (newBarId == '-1') {
        return;
      }

      await bdHeadquartersBarController.loadHeadquartersBar(hldId, typeSales);

      final barrasAtualizadas =
          bdHeadquartersBarController.headquartersBarNotifier.value;
      barExistente = barrasAtualizadas.cast<dynamic>().firstWhere(
        (b) {
          final bDate = DateTime.parse(b.bar_open_date.toString());
          return bDate.year == _selectedDate.year &&
              bDate.month == _selectedDate.month &&
              bDate.day == _selectedDate.day;
        },
        orElse: () => null,
      );

      barId = barExistente?.bar_id ?? barExistente?.barId ?? newBarId;
    }

    if (barId == null || barId.toString() == '-1') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível carregar os dados deste Bar.'),
            backgroundColor: Colors.deepOrange,
          ),
        );
      }
      return;
    }

    // Carregamento assíncrono dos módulos secundários
    await productsController.loadProdutos(hldId);
    await ticketController.loadTicketStatus(hldId);
    await ticketController.loadTickets(barId, openDate, hldId);

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HeadquartersBarOpened(
            barId: barId,
            openDate: openDate,
            hld_id: hldId,
            isReadOnly: isReadOnly,
          ),
        ),
      );
      if (mounted) {
        setState(() {
          _selectedDate = DateTime.now();
        });
      }
    }
  }

}