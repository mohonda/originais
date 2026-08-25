import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gorouter_exemplo/controllers/bd_monthlypayments_controller.dart';
import 'package:gorouter_exemplo/controllers/bd_formapagamento_controller.dart';
import 'package:gorouter_exemplo/models/custom_app_bar.dart';
import 'package:gorouter_exemplo/services/general_service.dart';

class MonthlyPaymentsCashier extends StatefulWidget {
  const MonthlyPaymentsCashier({super.key});

  @override
  State<MonthlyPaymentsCashier> createState() => MonthlyPaymentsCashierState();
}

class MonthlyPaymentsCashierState extends State<MonthlyPaymentsCashier> {
  final GeneralService generalService = GeneralService();

  final bdMonthlyPaymentsController =
      getItbdMonthlyPaymentsController<BdMonthlyPaymentsController>();

  final bdFormaPagamentoController =
      getItBdFormaPagamentoController<BdFormaPagamentoController>();

  final _formKey = GlobalKey<FormState>();

  // Controllers
  final idController = TextEditingController();
  final fullNameController = TextEditingController();
  final myreferencia = TextEditingController();
  final valor = TextEditingController();
  final datapagamento = TextEditingController();
  final comprovantepag = TextEditingController();
  String? formaPagamentoSelecionada = "";
  final dataconfirmacao = TextEditingController();
  final idconfirmacao = TextEditingController();
  final nameConfirmacao = TextEditingController();

  // ==========================================
  @override
  void initState() {
    initValues();

    super.initState();
  }

  // ==========================================
  @override
  void dispose() {
    // 1. Liberação de memória para evitar Memory Leaks
    idController.dispose();
    fullNameController.dispose();
    myreferencia.dispose();
    valor.dispose();
    datapagamento.dispose();
    comprovantepag.dispose();
    dataconfirmacao.dispose();
    idconfirmacao.dispose();
    nameConfirmacao.dispose();

    super.dispose();
  }

  // ==========================================
  void initValues() {
    bdFormaPagamentoController.loadFormaPagamento();

    final payment = bdMonthlyPaymentsController.monthlyPaymentsIndividual.value;

    idController.text = payment?.mes_pfl_id ?? "";
    fullNameController.text = payment?.pfl_full_name ?? "";

    final mes = payment?.mes_mes_referencia.toString().padLeft(2, '0') ?? "";
    final ano = payment?.mes_ano_referencia ?? "";
    myreferencia.text = (mes.isNotEmpty && ano.isNotEmpty) ? '$mes/$ano' : "";

    String tdata = payment?.mes_data_pagamento.toString() ?? "";
    if (tdata.length < 2) {
      datapagamento.text = generalService.formatarDataBr(
        DateTime.now().toString(),
      );
    } else {
      datapagamento.text = generalService.formatarDataBr(tdata);
    }

    String rawValor = payment?.mes_valor.toString() ?? "0.00";
    if (rawValor.length < 2) rawValor = "0.00";

    if (rawValor == "0.00" || rawValor == "0") {
      final int diaAtual = DateTime.now().day;
      final String diaDescontoStr =
          payment?.vpg_valor_desconto.toString() ?? "0";
      final int diaLimiteDesconto = int.tryParse(diaDescontoStr) ?? 0;
      if (diaLimiteDesconto > 0 && diaAtual <= diaLimiteDesconto) {
        rawValor = payment?.vpg_valor_desconto.toString() ?? "0.00";
      } else {
        rawValor = payment?.vpg_valor_normal.toString() ?? "0.00";
      }
    }

    String formattedValor = generalService.currencyMoneyBr(rawValor);
    valor.text = formattedValor.replaceAll("R\$ ", "").trim();

    comprovantepag.text = payment?.mes_comprovante_pag.toString() ?? "";

    formaPagamentoSelecionada = payment?.mes_fpg_id.toString() ?? "";

    tdata = payment?.mes_data_confirmacao.toString() ?? "";
    if (tdata.length < 2) {
      dataconfirmacao.text = generalService.formatarDataBr(
        DateTime.now().toString(),
      );
    } else {
      dataconfirmacao.text = generalService.formatarDataBr(tdata);
    }

    idconfirmacao.text = bdMonthlyPaymentsController.idConfirmacao;

    nameConfirmacao.text = bdMonthlyPaymentsController.nameConfirmacao;
  }

  // ==========================================
  @override
  Widget build(BuildContext context) {
    const double distance = 16.0;

    void selecionarEEnviarFoto() {
      final payment =
          bdMonthlyPaymentsController.monthlyPaymentsIndividual.value;
      final mes = payment?.mes_mes_referencia.toString().padLeft(2, '0') ?? "";
      final ano = payment?.mes_ano_referencia ?? "";
      bdMonthlyPaymentsController.selecionarEEnviarFoto(
        idController.text,
        mes,
        ano,
      );
    }

    return Scaffold(
      appBar: CustomFloatingAppBar(
        title: 'Cashier - ${fullNameController.text}'
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                // Desconta o padding externo de 16 (topo 16 + base 16 = 32)
                minHeight: constraints.maxHeight - 32.0,
              ),
              child: IntrinsicHeight(
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- LINHA 1: ID e Referência ---
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: idController,
                                  enabled: false,
                                  textAlign: TextAlign.end,
                                  decoration: const InputDecoration(
                                    labelText: 'ID:',
                                    prefixIcon: Icon(Icons.key),
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: distance),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  controller: myreferencia,
                                  enabled: false,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    color: Colors.deepOrange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Ref.: Mês/Ano',
                                    floatingLabelStyle: const TextStyle(
                                      color: Colors.blue,
                                    ),
                                    labelStyle: const TextStyle(
                                      color: Colors.blue,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.calendar_today,
                                      color: Colors.blue,
                                    ),
                                    disabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.blue.shade200,
                                        width: 2,
                                      ),
                                    ),
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: distance),

                          // --- BLOCO PRINCIPAL: 4 Campos à Esquerda, Imagem à Direita ---
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // COLUNA DA ESQUERDA
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    children: [
                                      // --- LINHA 2: Nome Completo ---
                                      TextFormField(
                                        controller: fullNameController,
                                        enabled: false,
                                        textAlign: TextAlign.start,
                                        decoration: const InputDecoration(
                                          labelText: 'Nome:',
                                          prefixIcon: Icon(Icons.verified_user),
                                          border: OutlineInputBorder(),
                                        ),
                                      ),

                                      const SizedBox(height: distance),

                                      // 1. VALOR
                                      TextFormField(
                                        controller: valor,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.end,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        decoration: const InputDecoration(
                                          labelText: 'Valor (R\$):',
                                          prefixIcon: Icon(Icons.attach_money),
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: (value) =>
                                            value == null ||
                                                value.trim().isEmpty
                                            ? 'Informe o valor'
                                            : null,
                                      ),
                                      const SizedBox(height: distance),

                                      // 2. FORMA DE PAGAMENTO
                                      ListenableBuilder(
                                        listenable: bdFormaPagamentoController
                                            .formaPagamentoNotifier,
                                        builder: (context, child) {
                                          final listaFormas =
                                              bdFormaPagamentoController
                                                  .formaPagamentoNotifier
                                                  .value;

                                          if (listaFormas.isEmpty) {
                                            return const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            );
                                          }
                                          bool valorExisteNaLista = listaFormas
                                              .any(
                                                (forma) =>
                                                    forma.fpg_id.toString() ==
                                                    formaPagamentoSelecionada,
                                              );
                                          if (!valorExisteNaLista) {
                                            formaPagamentoSelecionada = null;
                                          }

                                          return DropdownButtonFormField<
                                            String
                                          >(
                                            initialValue:
                                                formaPagamentoSelecionada,
                                            decoration: const InputDecoration(
                                              labelText: 'Forma de Pagamento:',
                                              prefixIcon: Icon(Icons.payment),
                                              border: OutlineInputBorder(),
                                            ),
                                            hint: const Text('Selecione...'),
                                            items: listaFormas.map((forma) {
                                              return DropdownMenuItem<String>(
                                                value: forma.fpg_id.toString(),
                                                child: Text(
                                                  forma.fpg_descricao
                                                      .toString(),
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (String? newValue) {
                                              setState(() {
                                                formaPagamentoSelecionada =
                                                    newValue;
                                              });
                                            },
                                            validator: (value) =>
                                                value == null || value.isEmpty
                                                ? 'Selecione'
                                                : null,
                                          );
                                        },
                                      ),
                                      const SizedBox(height: distance),

                                      // 3. DATA DO PAGAMENTO
                                      TextFormField(
                                        controller: datapagamento,
                                        textAlign: TextAlign.end,
                                        decoration: const InputDecoration(
                                          labelText: 'Data Pagtº:',
                                          prefixIcon: Icon(
                                            Icons.calendar_month,
                                          ),
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: (datapagamento) =>
                                            datapagamento == null ||
                                                datapagamento.trim().isEmpty
                                            ? 'Informe a data'
                                            : null,
                                      ),
                                      const SizedBox(height: distance),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: distance),

                                // COLUNA DA DIREITA (Miniatura Gigante)
                                Expanded(
                                  flex: 1,
                                  child: SizedBox(
                                    height: 0,
                                    child: ValueListenableBuilder<bool>(
                                      valueListenable:
                                          bdMonthlyPaymentsController
                                              .loadingNotifier,
                                      builder: (context, isLoading, child) {
                                        if (isLoading) {
                                          return Container(
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.grey.shade400,
                                                width: 1,
                                              ),
                                            ),
                                            child: const Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  CircularProgressIndicator(),
                                                  SizedBox(height: 12),
                                                  Text(
                                                    'Enviando...',
                                                    style: TextStyle(
                                                      color: Colors.black54,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }

                                        return ValueListenableBuilder(
                                          valueListenable:
                                              bdMonthlyPaymentsController
                                                  .monthlyPaymentsIndividual,
                                          builder: (context, value, child) {
                                            final url =
                                                value?.mes_comprovante_pag ??
                                                "";

                                            return GestureDetector(
                                              child: Container(
                                                clipBehavior: Clip.antiAlias,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[200],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.grey.shade400,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: url.isNotEmpty
                                                    ? SingleChildScrollView(
                                                        physics:
                                                            const BouncingScrollPhysics(),
                                                        child: Image.network(
                                                          url,
                                                          fit: BoxFit.fitWidth,
                                                          loadingBuilder:
                                                              (
                                                                context,
                                                                child,
                                                                loadingProgress,
                                                              ) {
                                                                if (loadingProgress ==
                                                                    null) {
                                                                  return child;
                                                                }
                                                                return const Center(
                                                                  child: Padding(
                                                                    padding:
                                                                        EdgeInsets.all(
                                                                          24.0,
                                                                        ),
                                                                    child:
                                                                        CircularProgressIndicator(),
                                                                  ),
                                                                );
                                                              },
                                                          errorBuilder:
                                                              (
                                                                context,
                                                                error,
                                                                stackTrace,
                                                              ) => const Center(
                                                                child: Padding(
                                                                  padding:
                                                                      EdgeInsets.all(
                                                                        20.0,
                                                                      ),
                                                                  child: Icon(
                                                                    Icons
                                                                        .broken_image,
                                                                    size: 48,
                                                                    color: Colors
                                                                        .redAccent,
                                                                  ),
                                                                ),
                                                              ),
                                                        ),
                                                      )
                                                    : const Center(
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Icon(
                                                              Icons.add_a_photo,
                                                              size: 48,
                                                              color: Colors
                                                                  .black45,
                                                            ),
                                                            SizedBox(height: 8),
                                                            Text(
                                                              'Toque para\nadicionar',
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .black45,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: distance),
                          const Divider(),
                          const SizedBox(height: distance),

                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  controller: idconfirmacao,
                                  enabled: false,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    color: Colors.deepOrange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Cashier ID:',
                                    labelStyle: const TextStyle(
                                      color: Colors.blue,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.attach_money_sharp,
                                      color: Colors.blue,
                                    ),
                                    disabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.blue.shade200,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: distance),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  controller: nameConfirmacao,
                                  enabled: false,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    color: Colors.deepOrange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Cashier Name:',
                                    labelStyle: const TextStyle(
                                      color: Colors.blue,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.attach_money_sharp,
                                      color: Colors.blue,
                                    ),
                                    disabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.blue.shade200,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: distance),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  controller: dataconfirmacao,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    color: Colors.deepOrange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Cashier Date:',
                                    floatingLabelStyle: const TextStyle(
                                      color: Colors.blue,
                                    ),
                                    labelStyle: const TextStyle(
                                      color: Colors.blue,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.calendar_month,
                                      color: Colors.blue,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.blue.shade200,
                                        width: 2,
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.blue.shade200,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  validator: (dataconfirmacao) =>
                                      dataconfirmacao == null ||
                                          dataconfirmacao.trim().isEmpty
                                      ? 'Informe a data'
                                      : null,
                                ),
                              ),
                            ],
                          ),

                          // ---------------------------------------------------
                          // EMPURRA OS BOTÕES PARA O FINAL DA TELA
                          // ---------------------------------------------------
                          const Spacer(),
                          const SizedBox(height: distance),

                          // --- BOTÕES DE AÇÃO ---
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => context.pop(),
                                  icon: const Icon(Icons.arrow_back),
                                  label: const Text('Cancelar'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.indigo,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: distance),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    if (_formKey.currentState!.validate()) {
                                      cancelPaymentsCashier(context);
                                    }
                                  },
                                  icon: const Icon(Icons.save),
                                  label: const Text('Cashier Cancel'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepOrange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: distance),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    if (_formKey.currentState!.validate()) {
                                      updatePaymentsCashier();
                                    }
                                  },
                                  icon: const Icon(Icons.save),
                                  label: const Text('Cashier Confirm'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigo,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
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
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  void updatePaymentsProfile() async {
    try {
      bdMonthlyPaymentsController.updatePaymentsProfile(
        idController.text,
        myreferencia.text.split('/')[0],
        myreferencia.text.split('/')[1],
        valor.text,
        datapagamento.text,
        formaPagamentoSelecionada ?? "",
      );
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
    }
  }

  // ==========================================
  void updatePaymentsCashier() async {
    try {
      bdMonthlyPaymentsController.updatePaymentsCashier(
        idController.text,
        myreferencia.text.split('/')[0],
        myreferencia.text.split('/')[1],
        valor.text,
        datapagamento.text,
        formaPagamentoSelecionada ?? "",
        idconfirmacao.text,
        dataconfirmacao.text,
      );
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
    }
  }

  // ==========================================
  void cancelPaymentsCashier(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Profile Payment?'),
        content: const Text('Data Profile Payment will be lost!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            child: const Text('Confirmar'),
            onPressed: () {
              Navigator.pop(context);
              try {
                bdMonthlyPaymentsController.cancelPaymentsCashier(
                  idController.text,
                  myreferencia.text.split('/')[0],
                  myreferencia.text.split('/')[1],
                  idconfirmacao.text,
                  dataconfirmacao.text,
                );
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
              }
            },
          ),
        ],
      ),
    );
  }

}
