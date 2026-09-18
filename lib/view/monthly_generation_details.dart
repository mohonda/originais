import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:originais/models/custom_app_bar.dart';
import 'package:originais/services/general_service.dart';
import 'package:originais/controllers/payment_value_controller.dart';
import 'package:originais/controllers/profile_controller.dart';
import 'package:originais/models/vprofile_model.dart';
import 'package:originais/controllers/monthly_payments_controller.dart';
import 'package:originais/controllers/monthly_distinct_controller.dart';

class MonthlyGenerationDetails extends StatefulWidget {
  const MonthlyGenerationDetails({super.key});

  @override
  State<MonthlyGenerationDetails> createState() =>
      MonthlyGenerationDetailsState();
}

class MonthlyGenerationDetailsState extends State<MonthlyGenerationDetails> {
  final bdPaymentValueController =
      getItBdPaymentValueController<BdPaymentValueController>();

  final bdProfileController = getItBdProfileController<BdProfileController>();

  final bdMonthlyPaymentsController =
      getItbdMonthlyPaymentsController<BdMonthlyPaymentsController>();

  final bdVMensalidadesDistinctController =
      getItBdVMensalidadesDistinctController<
        BdVMensalidadesDistinctController
      >();

  final generalService = getItGeneralService<GeneralService>();

  final myreferencia = TextEditingController();
  final hldController = TextEditingController();
  final fullNameController = TextEditingController();
  final datapagamento = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  String? formaPagamentoSelecionada;

  final ScrollController profilesScrollController = ScrollController();

  final hldValueNotifier = ValueNotifier<String?>(null);
  final vpgValueNotifier = ValueNotifier<String?>(null);
  final mValueNotifier = ValueNotifier<String?>(null);
  final yValueNotifier = ValueNotifier<String?>(null);
  List<VProfileModel> filteredList = [];
  late List listaFormas = [];

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

    hldValueNotifier.value = '1';

    // Registrar o ouvinte de notificações de erro do controller
    bdMonthlyPaymentsController.errorNotifier.addListener(_onErrorChanged);
  }

  // ==========================================
  @override
  void dispose() {
    // Remover o listener para evitar vazamento de memória (memory leaks)
    bdMonthlyPaymentsController.errorNotifier.removeListener(_onErrorChanged);

    // Descarte de controllers e notifiers
    myreferencia.dispose();
    hldController.dispose();
    fullNameController.dispose();
    datapagamento.dispose();
    profilesScrollController.dispose();

    hldValueNotifier.dispose();
    vpgValueNotifier.dispose();
    mValueNotifier.dispose();
    yValueNotifier.dispose();

    super.dispose();
  }

  // ==========================================
  @override
  Widget build(BuildContext context) {
    const double distance = 16.0;

    return Scaffold(
      appBar: const CustomFloatingAppBar(title: 'Monthly Generation Details'),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          bdMonthlyPaymentsController.loadingNotifier,
          bdMonthlyPaymentsController.errorNotifier,
        ]),
        builder: (context, _) {
          final isLoading = bdMonthlyPaymentsController.loadingNotifier.value;

          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 12.0,
                ),
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
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // 1. CAMPO DE DATA (Mês/Ano)
                                TextFormField(
                                  controller: myreferencia,
                                  readOnly: true,
                                  enabled: !isLoading,
                                  onTap: () => _exibirSeletorMesAno(context),
                                  textAlign: TextAlign.start,
                                  decoration: const InputDecoration(
                                    labelText: 'Ref.: Mês/Ano',
                                    prefixIcon: Icon(Icons.calendar_today),
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Selecione o Mês/Ano de referência';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: distance),

                                // 2. DROPDOWN
                                paymentValueDropDown(isLoading),

                                const SizedBox(height: distance),

                                // 3. TABELA DE PERFIS
                                Expanded(child: profilesTable()),

                                const SizedBox(height: distance),

                                // 4. BOTÕES NO RODAPÉ
                                _buildButtons(isLoading),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Overlay de carregamento durante operações no banco de dados
              if (isLoading)
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
                                'Processando mensalidades...',
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
  Widget paymentValueDropDown(bool isLoading) {
    return ListenableBuilder(
      listenable: bdPaymentValueController.bdPaymentValueNotifier,
      builder: (context, child) {
        listaFormas = bdPaymentValueController.bdPaymentValueNotifier.value;

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
          onChanged: isLoading
              ? null
              : (value) {
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
  Widget _buildButtons(bool isLoading) {
    const double distance = 16.0;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : () => context.pop(),
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
            onPressed: isLoading
                ? null
                : () async {
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
      final produtoEncontrado = listaFormas.firstWhere(
        (fpg) => fpg.vpg_id == vpgValueNotifier.value,
      );

      String desc =
          'Valor de: ${generalService.currencyMoneyBr(produtoEncontrado.vpg_valor_normal)} até dia ${produtoEncontrado.vpg_dia_valor_normal}';
      DateTime tmpDT = DateTime(
        int.parse(yValueNotifier.value.toString()),
        int.parse(mValueNotifier.value.toString()),
      );
      final double tmpValor = double.parse(
        produtoEncontrado.vpg_valor_normal,
      );

      final List<Map<String, dynamic>> dadosParaInserir = filteredList.map((
        item,
      ) {
        double percentValue = double.parse(item.pas_monthly_percent.toString());
        percentValue = tmpValor * (percentValue / 100);

        return {
          'p_hld_id': item.hld_id,
          'p_pfl_id': item.pfl_id,
          'p_pfl_name': item.pfl_full_name,
          'p_date_start': tmpDT,
          'p_desc': '$desc consid. ${item.pas_monthly_percent}%',
          'p_tss_id': 2,
          'p_table_number': -1,
          'p_pdt_id': 33,
          'p_pdt_quant': 1,
          'p_valor': percentValue.toString(),
          'p_tkt_vpg_id': vpgValueNotifier.value.toString(),
          'p_tkt_pas_id': item.pas_id.toString(),
        };
      }).toList();

      await bdMonthlyPaymentsController.insertMonthlyGeneration(
        dadosParaInserir,
      );

      final currentError = bdMonthlyPaymentsController.errorNotifier.value;

      // Confirmação de sucesso e navegação apenas se não houver erros
      if (mounted && (currentError == null || currentError.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dados atualizados com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );

        await bdVMensalidadesDistinctController.loadMensalidadesDistincts();

        if (mounted) {
          context.pop();
        }
      }
    } catch (e) {
      // Erros genéricos de runtime são capturados aqui caso ocorram fora da Controller
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
    }
  }
}