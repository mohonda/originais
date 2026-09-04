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

    pflId =
        bdProfileController.pessoaSelecionadaNotifier.value?.pfl_id ?? '';
    hldId =
        bdProfileController.pessoaSelecionadaNotifier.value?.hld_id ?? '';

    _carregarDiasAbertos();

    bdHeadquartersBarController.initRealtime( hldId );
  }

  @override
  void dispose() {
    bar_desc.dispose();

    bdHeadquartersBarController.disposeRealtime();

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

  Future<void> _carregarDiasAbertos() async {
    try {
      // 1. Busque os registros no banco (ajuste conforme seu controller)
      // Aqui estou assumindo que loadHeadquartersBar retorna a lista ou atualiza um Notifier
      await bdHeadquartersBarController.loadHeadquartersBar(hldId);
      final barrasAbertas =
          bdHeadquartersBarController.headquartersBarNotifier.value;

      /* 
       * 2. Transforme a lista do banco em uma Lista de DateTime
       * Substitua 'barrasAbertas' pela sua lista real e 'bar_date' pela propriedade da sua data.
       */
      List<DateTime> datas = barrasAbertas.map((bar) {
        // Se a data vier como String (ex: '2023-10-25'), faça o parse:
        return DateTime.parse(bar.bar_open_date.toString());
        // return bar.bar_open_date;
      }).toList();

      // 3. Atualize a tela com os dias encontrados
      if (mounted) {
        setState(() {
          _openDays = datas;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar dias abertos: $e');
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
                  // 🟢 1. O CALENDÁRIO OCUPA 100% DO ESPAÇO RESTANTE
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

                  // 🟢 2. BOTÕES FIXADOS NO RODAPÉ DO CARD
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
                    // validator: (value) => value == null || value.trim().isEmpty
                    //     ? 'Provide the description!!!'
                    //     : null,
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

    // 🟢 1. CALCULA O DIA OPERACIONAL (TURNO ATUAL)
    // Se estiver entre 00:00:00 e 06:00:00, o turno pertence ao dia civil de ONTEM.
    late DateTime hojeOperacional;
    if (now.hour < 6 || (now.hour == 6 && now.minute == 0)) {
      final ontem = now.subtract(const Duration(days: 1));
      hojeOperacional = DateTime(ontem.year, ontem.month, ontem.day);
    } else {
      // Das 06:00:01 em diante, já é o dia civil de HOJE.
      hojeOperacional = DateTime(now.year, now.month, now.day);
    }

    // 🟢 2. PREPARA A DATA SELECIONADA NO CALENDÁRIO (SEM HORÁRIO)
    final dataSelecionada = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    // 🟢 3. DEFINE SE É SOMENTE LEITURA
    // Fica como leitura apenas se a data selecionada for ANTERIOR ao dia operacional atual.
    final bool isReadOnly = dataSelecionada.isBefore(hojeOperacional);

    // Exemplo de comportamento prático:
    // - Se for 03:00 AM do dia 04/09: `hojeOperacional` é 03/09.
    //   -> Selecionar 03/09 = Edição liberada (`isReadOnly = false`).
    //   -> Selecionar 02/09 = Somente Leitura (`isReadOnly = true`).

    // - Se for 08:00 AM do dia 04/09: `hojeOperacional` é 04/09.
    //   -> Selecionar 04/09 = Edição liberada (`isReadOnly = false`).
    //   -> Selecionar 03/09 = Somente Leitura (`isReadOnly = true`).

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
