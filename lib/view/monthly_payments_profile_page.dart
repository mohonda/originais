import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:originais/view/monthly_payments_form_layout.dart';
import 'package:originais/controllers/MonthlyPaymentsImageService.dart';

class MonthlyPaymentsProfilePage extends StatefulWidget {
  const MonthlyPaymentsProfilePage({super.key});

  @override
  State<MonthlyPaymentsProfilePage> createState() => _MonthlyPaymentsProfilePageState();
}

class _MonthlyPaymentsProfilePageState extends State<MonthlyPaymentsProfilePage> {
  final _formKey = GlobalKey<MonthlyPaymentsFormLayoutState>();
  final monthlyPaymentsImageService = MonthlyPaymentsImageService();

  void _enviarFoto() {
    final state = _formKey.currentState!;
    final payment = state.bdMonthlyPaymentsController.monthlyPaymentsIndividual.value;
    monthlyPaymentsImageService.selecionarAnexoEEnviar(
      context: context,
      payload: {
        'pfl_id': state.idController.text,
        'hld_id': state.hld_id,
        'ano': payment?.mes_ano_referencia ?? "",
        'mes': payment?.mes_mes_referencia.toString().padLeft(2, '0') ?? "",
      },
    );
  }

  void _salvar() {
    final state = _formKey.currentState!;
    
    // 1. Validação padrão dos campos do formulário (valor, data, forma de pagtº)
    if (!state.formKey.currentState!.validate()) return;

    // 2. 🟢 Validação de Comprovante Obrigatório
    final payment = state.bdMonthlyPaymentsController.monthlyPaymentsIndividual.value;
    final comprovanteUrl = payment?.mes_comprovante_pag ?? state.comprovantepag.text;

    if (comprovanteUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('É obrigatório anexar o comprovante antes de salvar!'),
              ),
            ],
          ),
          backgroundColor: Colors.deepOrange,
          duration: Duration(seconds: 3),
        ),
      );
      return; // Interrompe o salvamento
    }

    // 3. Atualização no banco se a foto e os campos estiverem preenchidos
    try {
      state.bdMonthlyPaymentsController.updatePaymentsProfile(
        state.idController.text,
        state.myreferencia.text.split('/')[0],
        state.myreferencia.text.split('/')[1],
        state.valor.text,
        state.datapagamento.text,
        state.formaPagamentoSelecionada.value ?? "",
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pagamento salvo com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao salvar dados!'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MonthlyPaymentsFormLayout(
      key: _formKey,
      title: 'Payment',
      allowImageUpload: true,
      onImageTap: _enviarFoto,
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
              onPressed: _salvar,
              icon: const Icon(Icons.save),
              label: const Text('Salvar'),
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