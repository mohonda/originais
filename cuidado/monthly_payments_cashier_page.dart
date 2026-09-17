import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:originais/view/monthly_payments_form_layout.dart';

class MonthlyPaymentsCashierPage extends StatefulWidget {
  const MonthlyPaymentsCashierPage({super.key});

  @override
  State<MonthlyPaymentsCashierPage> createState() => _MonthlyPaymentsCashierPageState();
}

class _MonthlyPaymentsCashierPageState extends State<MonthlyPaymentsCashierPage> {
  final _formKey = GlobalKey<MonthlyPaymentsFormLayoutState>();

  final idConfirmacaoCtrl = TextEditingController();
  final nameConfirmacaoCtrl = TextEditingController();
  final dateConfirmacaoCtrl = TextEditingController();
  DateTime? _selectedCashierDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = _formKey.currentState;
      if (state != null) {
        final payment = state.bdMonthlyPaymentsController.monthlyPaymentsIndividual.value;
        idConfirmacaoCtrl.text = state.bdMonthlyPaymentsController.idConfirmacao;
        nameConfirmacaoCtrl.text = state.bdMonthlyPaymentsController.nameConfirmacao;

        String tdata = payment?.mes_data_confirmacao.toString() ?? "";
        dateConfirmacaoCtrl.text = (tdata.length < 2)
            ? state.generalService.formatarDataBr(DateTime.now().toString())
            : state.generalService.formatarDataBr(tdata);
      }
    });
  }

  @override
  void dispose() {
    idConfirmacaoCtrl.dispose();
    nameConfirmacaoCtrl.dispose();
    dateConfirmacaoCtrl.dispose();
    super.dispose();
  }

  // 🟢 Seletor de Data para o Caixa
  Future<void> _selectCashierDate(BuildContext context) async {
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2026, 8, 1),
      lastDate: DateTime(2028),
    );
    if (selected != null && selected != _selectedCashierDate) {
      setState(() {
        _selectedCashierDate = selected;
        dateConfirmacaoCtrl.text =
            "${selected.day.toString().padLeft(2, '0')}/${selected.month.toString().padLeft(2, '0')}/${selected.year}";
      });
    }
  }

  // 🟢 Confirmação de Caixa
  void _confirmarCaixa() {
    final state = _formKey.currentState!;
    try {
      state.bdMonthlyPaymentsController.updatePaymentsCashier(
        state.idController.text,
        state.myreferencia.text.split('/')[0],
        state.myreferencia.text.split('/')[1],
        state.valor.text,
        state.datapagamento.text,
        state.formaPagamentoSelecionada.value ?? "",
        idConfirmacaoCtrl.text,
        dateConfirmacaoCtrl.text,
      );
      _showSnackBar('Dados atualizados com sucesso!', Colors.green);
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      _showSnackBar('Error dados não atualizados!', Colors.redAccent);
    }
  }

  // 🟢 Cancelamento no Caixa com Modal de Confirmação
  void _cancelarPagamento(BuildContext context) {
    final state = _formKey.currentState!;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Profile Payment?'),
        content: const Text('Data Profile Payment will be lost!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            child: const Text('Confirmar'),
            onPressed: () {
              Navigator.pop(dialogContext);
              try {
                state.bdMonthlyPaymentsController.cancelPaymentsCashier(
                  state.idController.text,
                  state.myreferencia.text.split('/')[0],
                  state.myreferencia.text.split('/')[1],
                  idConfirmacaoCtrl.text,
                  dateConfirmacaoCtrl.text,
                );
                _showSnackBar('Dados atualizados com sucesso!', Colors.green);
                if (mounted) {
                  context.pop();
                }
              } catch (e) {
                _showSnackBar('Error dados não atualizados!', Colors.redAccent);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MonthlyPaymentsFormLayout(
      key: _formKey,
      title: 'Cashier',
      allowImageUpload: false,
      extraFields: Column(
        children: [
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: idConfirmacaoCtrl,
                  enabled: false,
                  textAlign: TextAlign.end,
                  style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Cashier ID:',
                    labelStyle: const TextStyle(color: Colors.blue),
                    prefixIcon: const Icon(Icons.attach_money_sharp, color: Colors.blue),
                    disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue.shade200, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: nameConfirmacaoCtrl,
                  enabled: false,
                  textAlign: TextAlign.end,
                  style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Cashier Name:',
                    labelStyle: const TextStyle(color: Colors.blue),
                    prefixIcon: const Icon(Icons.attach_money_sharp, color: Colors.blue),
                    disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue.shade200, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 🟢 Campo Data com Seletor Ativo
              Expanded(
                child: TextFormField(
                  controller: dateConfirmacaoCtrl,
                  readOnly: true,
                  onTap: () => _selectCashierDate(context),
                  textAlign: TextAlign.end,
                  style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Cashier Date:',
                    floatingLabelStyle: const TextStyle(color: Colors.blue),
                    labelStyle: const TextStyle(color: Colors.blue),
                    prefixIcon: const Icon(Icons.calendar_month, color: Colors.blue),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue.shade200, width: 2),
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue.shade200, width: 2),
                    ),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Informe a data' : null,
                ),
              ),
            ],
          ),
        ],
      ),
      // 🟢 Três botões de ação restaurados
      actionButtons: Row(
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
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                final state = _formKey.currentState!;
                if (state.formKey.currentState!.validate()) {
                  _cancelarPagamento(context);
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Cashier Cancel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                final state = _formKey.currentState!;
                if (state.formKey.currentState!.validate()) {
                  _confirmarCaixa();
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Cashier Confirm'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}