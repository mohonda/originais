import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:originais/models/profile_model.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:originais/models/custom_app_bar.dart';
import 'package:originais/services/general_service.dart';
import 'package:originais/controllers/bd_payment_value_controller.dart';
import 'package:originais/models/payment_value.dart';
import 'package:originais/controllers/bd_profile_controller.dart';
import 'package:originais/models/vprofile_model.dart';
import 'package:originais/controllers/bd_monthlypayments_controller.dart';
import 'package:originais/controllers/bd_vmensalidades_distinct_controller.dart';

class MonthlyGenerationDetails extends StatefulWidget {
  const MonthlyGenerationDetails({super.key});

  // ==========================================
  @override
  State<MonthlyGenerationDetails> createState() =>
      MonthlyGenerationDetailsState();
}

class MonthlyGenerationDetailsState extends State<MonthlyGenerationDetails> {
  final bdPaymentValueController =
      getItBdPaymentValueController<BdPaymentValueController>();

  final bdProfileController = getItBdProfileController<BdProfileController>();

  final bdMonthlyPaymentsController = getItbdMonthlyPaymentsController<BdMonthlyPaymentsController>();

  final bdVMensalidadesDistinctController =
    getItBdVMensalidadesDistinctController<BdVMensalidadesDistinctController>();

  final generalService = getItGeneralService<GeneralService>();

  final myreferencia = TextEditingController();
  final hldController = TextEditingController();
  final fullNameController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  final datapagamento = TextEditingController();
  String? formaPagamentoSelecionada;

  final ScrollController profilesScrollController = ScrollController();

  final hldValueNotifier = ValueNotifier<String?>(null);
  final vpgValueNotifier = ValueNotifier<String?>(null);
  final mValueNotifier = ValueNotifier<String?>(null);
  final yValueNotifier = ValueNotifier<String?>(null);
  List<VProfileModel> filteredList = [];

  // ==========================================
  MonthlyGenerationDetailsState();

  // ==========================================
  @override
  void initState() {
    initializeDateFormatting('pt', 'BR');
    
    hldValueNotifier.value = '1';

    super.initState();
  }

  // ==========================================
  @override
  void dispose() {
    profilesScrollController.dispose();

    super.dispose();
  }

  // ==========================================
  @override
  Widget build(BuildContext context) {
    const double distance = 16.0;

    return Scaffold(
      appBar: const CustomFloatingAppBar(title: 'Monthly Generation Details'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 16.0,
            ),
            child: SizedBox.expand(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // 1. CAMPO DE DATA (Mês/Ano)
                            TextFormField(
                              controller: myreferencia,
                              readOnly: true,
                              onTap: () => _exibirSeletorMesAno(context),
                              textAlign: TextAlign.start,
                              decoration: const InputDecoration(
                                labelText: 'Ref.: Mês/Ano',
                                prefixIcon: Icon(Icons.calendar_today),
                                border: OutlineInputBorder(),
                              ),
                              // Validação do campo
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Selecione o Mês/Ano de referência';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: distance),

                            // 2. DROPDOWN
                            paymentValueDropDown(),

                            const SizedBox(height: distance),

                            // 3. EXPANDED APENAS NA TABELA:
                            // Ocupa exatamente o espaço restante da tela sem estourar os limites
                            Expanded(child: profilesTable()),

                            const SizedBox(height: distance),

                            // 4. BOTÕES NO RODAPÉ
                            _buildButtons(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  Widget paymentValueDropDown() {
    return ListenableBuilder(
      listenable: bdPaymentValueController.bdPaymentValueNotifier,
      builder: (context, child) {
        final listaFormas =
            bdPaymentValueController.bdPaymentValueNotifier.value;

        return DropdownButtonFormField2<String>(
          isExpanded: true,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            border: OutlineInputBorder(),
            // Add more decoration..
          ),
          
          hint: const Text(
            'Select the Payment Value',
            style: TextStyle(fontSize: 14),
          ),
          items: listaFormas
              .map(
                (item) => DropdownItem<String>(
                  value: item.vpg_id,
                  child: Text(
                    '${item.vpg_desc} valor de: ${generalService.currencyMoneyBr(item.vpg_valor_normal)} até dia ${item.vpg_dia_valor_normal}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              )
              .toList(),
          valueListenable: vpgValueNotifier,
          validator: (value) {
            if (value == null) {
              return 'Please select the Payment Value.';
            }
            return null;
          },
          onChanged: (value) {
            vpgValueNotifier.value = value;
          },
          iconStyleData: const IconStyleData(
            icon: Icon(Icons.arrow_drop_down, color: Colors.white70),
          ),
          dropdownStyleData: DropdownStyleData(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.grey.shade900,
            ),
          ),
          menuItemStyleData: const MenuItemStyleData(
            useDecorationHorizontalPadding: true,
          ),
        );
      },
    );
  }

  // ==========================================
  Widget profilesTable() {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Associate Status',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.all(12),
      ),
      child: ValueListenableBuilder<List<VProfileModel>?>(
        valueListenable: bdProfileController.profilesNotifier,
        builder: (context, historyList, child) {
          filteredList =
              historyList
                  ?.where((item) => item.as_ismonthlypayment == 'true')
                  .toList() ??
              [];

          final bool temItens = filteredList.isNotEmpty;

          if (!temItens) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                'Nenhum registro encontrado.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return Scrollbar(
            controller: profilesScrollController,
            thumbVisibility: true,
            child: ListView.builder(
              controller: profilesScrollController,
              shrinkWrap: true,
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final item = filteredList[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.pfl_full_name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Porcentagem da Mensalidade: ${item.pas_monthly_percent}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
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
    );
  }

  // ==========================================
  Widget _buildButtons() {
    const double distance = 16.0;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Cancelar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.indigo,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: distance),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                insertMonthlyGeneration();
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('Generate monthly'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  void _exibirSeletorMesAno(BuildContext context) async {
    final now = DateTime.now();

    // Define o limite inferior como o dia 1 do mês atual
    final DateTime currentMonthStart = DateTime(now.year, now.month, 1);

    final DateTime? selectedDate = await showMonthPicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: currentMonthStart,
      lastDate: DateTime(2028),
      monthPickerDialogSettings: const MonthPickerDialogSettings(
        dialogSettings: PickerDialogSettings(locale: Locale('pt', 'BR')),
      ),
    );

    if (selectedDate != null) {
      mValueNotifier.value = selectedDate.month.toString().padLeft(2, '0');
      yValueNotifier.value = selectedDate.year.toString();

      setState(() {
        myreferencia.text = '${mValueNotifier.value}/${yValueNotifier.value}';
      });
    }
  }

  // ==========================================
  void insertMonthlyGeneration() async {
    try {
      final List<Map<String, dynamic>> dadosParaInserir = filteredList.map((item) {
      return {
        'mes_mes_referencia': mValueNotifier.value,
        'mes_ano_referencia': yValueNotifier.value,
        'mes_pfl_id': item.pfl_id,
        'mes_hld_id': item.hld_id,
        'mes_vpg_id': vpgValueNotifier.value,
        'mes_vpg_hld_id': item.hld_id,
        'mes_monthly_percent':item.pas_monthly_percent
        };
      }).toList();

      await bdMonthlyPaymentsController.insertMonthlyGeneration(dadosParaInserir);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error dados não atualizados!'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dados atualizados com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      await bdVMensalidadesDistinctController.loadMensalidadesDistincts();
      if (mounted) {
        context.pop();
      }
    }
  }
}
