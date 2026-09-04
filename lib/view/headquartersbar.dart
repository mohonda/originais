import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:originais/controllers/bd_headquartersbar_controller.dart';
import 'package:originais/services/general_service.dart';
import 'package:originais/models/custom_app_bar.dart';
import 'package:originais/view/custom_month_calendar.dart';
import 'package:originais/view/headquartersbar_opened.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:originais/controllers/bd_profile_controller.dart';
import 'package:originais/controllers/products_controller.dart';
import 'package:originais/controllers/ticketController.dart';

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

  @override
  void initState() {
    super.initState();
    initValues();

    pflId = bdProfileController.pessoaSelecionadaNotifier.value?.pfl_id ?? '';
    hldId = bdProfileController.pessoaSelecionadaNotifier.value?.hld_id ?? '';

    // 🟢 1. Escuta alterações no Notifier do Controller (Realtime + Carga inicial)
    bdHeadquartersBarController.headquartersBarNotifier.addListener(_onHeadquartersBarChanged);

    // 🟢 2. Carga inicial e inicialização do canal em Tempo Real
    _carregarDadosIniciais();
  }

  @override
  void dispose() {
    // 🟢 Remove o ouvinte para evitar vazamento de memória
    bdHeadquartersBarController.headquartersBarNotifier.removeListener(_onHeadquartersBarChanged);
    bdHeadquartersBarController.disposeRealtime();

    bar_desc.dispose();
    super.dispose();
  }

  void initValues() {
    initializeDateFormatting('pt_BR', null).then((_) {
      if (mounted) {
        setState(() {
          _isLocaleInitialized = true;
        });
      }
    });
  }

  Future<void> _carregarDadosIniciais() async {
    await bdHeadquartersBarController.loadHeadquartersBar(hldId);
    bdHeadquartersBarController.initRealtime(hldId);
  }

  // 🟢 3. Atualiza os dias abertos do calendário sempre que o controller mudar
  void _onHeadquartersBarChanged() {
    final barrasAbertas = bdHeadquartersBarController.headquartersBarNotifier.value;

    List<DateTime> datas = barrasAbertas.map((bar) {
      return DateTime.parse(bar.bar_open_date.toString());
    }).toList();

    if (mounted) {
      setState(() {
        _openDays = datas;
      });
    }
  }

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
      body: Padding(
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
                  // 🟢 CALENDÁRIO ATUALIZADO EM TEMPO REAL
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
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              openHeadquartersBar();
                            }
                          },
                          icon: const Icon(Icons.save),
                          label: const Text('Open'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
    );
  }

  void openHeadquartersBar() async {
    String openDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final now = DateTime.now();

    // CALCULA O DIA OPERACIONAL
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

    bool isJaAberto = _openDays.any(
      (d) =>
          d.year == _selectedDate.year &&
          d.month == _selectedDate.month &&
          d.day == _selectedDate.day,
    );

    if (!isJaAberto && !isReadOnly) {
      await bdHeadquartersBarController.openHeadquartersBar(
        pflId,
        hldId,
        openDate,
        bar_desc.text,
      );
    }

    await productsController.loadProdutos(hldId);
    await ticketController.loadTicketStatus(hldId);
    await ticketController.loadTickets(openDate, hldId);

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HeadquartersBarOpened(
            openDate: openDate,
            hld_id: hldId,
            isReadOnly: isReadOnly,
          ),
        ),
      );
    }
  }
}
