import 'package:gorouter_exemplo/models/ticketModel.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:gorouter_exemplo/controllers/bd_headquartersbar_controller.dart';
import 'package:gorouter_exemplo/services/general_service.dart';
import 'package:gorouter_exemplo/models/custom_app_bar.dart';
import 'package:gorouter_exemplo/view/custom_month_calendar.dart';
import 'package:gorouter_exemplo/view/headquartersbar_opened.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gorouter_exemplo/controllers/bd_profile_controller.dart';
import 'package:gorouter_exemplo/controllers/products_controller.dart';
import 'package:gorouter_exemplo/controllers/ticketController.dart';
import 'package:gorouter_exemplo/models/ticketModel.dart';

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

  @override
  void initState() {
    super.initState();
    initValues();
    
    _carregarDiasAbertos();
  }

  @override
  void dispose() {
    bar_desc.dispose();

    super.dispose();
  }

  void initValues() {
    // bdHeadquartersBarController.loadHeadquartersBar('1', '1');

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
      String hld_id = bdProfileController.pessoaSelecionadaNotifier.value?.hld_id ?? '1';
      
      // 1. Busque os registros no banco (ajuste conforme seu controller)
      // Aqui estou assumindo que loadHeadquartersBar retorna a lista ou atualiza um Notifier
      await bdHeadquartersBarController.loadHeadquartersBar(hld_id);
      final barrasAbertas = bdHeadquartersBarController.headquartersBarNotifier.value;
          debugPrint(barrasAbertas.length.toString());
      
      /* 
       * 2. Transforme a lista do banco em uma Lista de DateTime
       * Substitua 'barrasAbertas' pela sua lista real e 'bar_date' pela propriedade da sua data.
       */
      List<DateTime> datas = barrasAbertas.map((bar) {
         // Se a data vier como String (ex: '2023-10-25'), faça o parse:
         return DateTime.parse( bar.bar_open_date.toString() ); 
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
        body: Center(
          child: CircularProgressIndicator(),
        ),
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
    String pfl_id = bdProfileController.pessoaSelecionadaNotifier.value?.pfl_id ?? '';
    String hld_id = bdProfileController.pessoaSelecionadaNotifier.value?.hld_id ?? '';
    String openDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

    bool isJaAberto = _openDays.any((d) => 
          d.year == _selectedDate.year &&
          d.month == _selectedDate.month &&
          d.day == _selectedDate.day);

    if ( !isJaAberto ) {
      await bdHeadquartersBarController.openHeadquartersBar(
        pfl_id,
        hld_id,
        openDate,
        bar_desc.text,
      );
    }
    await productsController.loadProdutos(hld_id);
    await ticketController.loadTicketStatus(hld_id);
    await ticketController.loadTickets(openDate, hld_id);

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HeadquartersBarOpened(
            openDate: openDate,
            hld_id: hld_id )
        ),
      );
    }
  }
}
