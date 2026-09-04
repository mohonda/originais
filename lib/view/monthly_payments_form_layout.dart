import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:originais/controllers/bd_monthlypayments_controller.dart';
import 'package:originais/controllers/bd_formapagamento_controller.dart';
import 'package:originais/models/custom_app_bar.dart';
import 'package:originais/services/general_service.dart';

class MonthlyPaymentsFormLayout extends StatefulWidget {
  final String title;
  final bool readOnly;
  final bool allowImageUpload;
  final VoidCallback? onImageTap;
  final Widget? extraFields;
  final Widget actionButtons;

  const MonthlyPaymentsFormLayout({
    super.key,
    required this.title,
    required this.actionButtons,
    this.extraFields,
    this.readOnly = false,
    this.allowImageUpload = false,
    this.onImageTap,
  });

  @override
  State<MonthlyPaymentsFormLayout> createState() =>
      MonthlyPaymentsFormLayoutState();
}

class MonthlyPaymentsFormLayoutState extends State<MonthlyPaymentsFormLayout> {
  final GeneralService generalService = GeneralService();
  final bdMonthlyPaymentsController =
      getItbdMonthlyPaymentsController<BdMonthlyPaymentsController>();
  final bdFormaPagamentoController =
      getItBdFormaPagamentoController<BdFormaPagamentoController>();
  final formKey = GlobalKey<FormState>();

  // Controllers Compartilhados
  final idController = TextEditingController();
  final fullNameController = TextEditingController();
  final myreferencia = TextEditingController();
  final valor = TextEditingController();
  final datapagamento = TextEditingController();
  final comprovantepag = TextEditingController();
  final formaPagamentoSelecionada = ValueNotifier<String?>(null);

  String hld_id = '';
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    initValues();
  }

  @override
  void dispose() {
    idController.dispose();
    fullNameController.dispose();
    myreferencia.dispose();
    valor.dispose();
    datapagamento.dispose();
    comprovantepag.dispose();
    formaPagamentoSelecionada.dispose();
    super.dispose();
  }

  void initValues() {
    bdFormaPagamentoController.loadFormaPagamento();
    final payment = bdMonthlyPaymentsController.monthlyPaymentsIndividual.value;

    idController.text = payment?.mes_pfl_id ?? "";
    hld_id = payment?.mes_hld_id ?? '';
    fullNameController.text = payment?.pfl_full_name ?? "";

    final mes = payment?.mes_mes_referencia.toString().padLeft(2, '0') ?? "";
    final ano = payment?.mes_ano_referencia ?? "";
    myreferencia.text = (mes.isNotEmpty && ano.isNotEmpty) ? '$mes/$ano' : "";

    String tdata = payment?.mes_data_pagamento.toString() ?? "";
    datapagamento.text = (tdata.length < 2)
        ? generalService.formatarDataBr(DateTime.now().toString())
        : generalService.formatarDataBr(tdata);

    String rawValor = payment?.mes_valor.toString() ?? "0.00";
    if (rawValor.length < 2) rawValor = "0.00";

    if (rawValor == "0.00" || rawValor == "0") {
      final int diaAtual = DateTime.now().day;

      // 🟢 Substitua 'vpg_dia_limite_desconto' pelo nome exato do campo do seu model que guarda o dia
      final String diaDescontoStr =
          payment?.vpg_dia_valor_desconto.toString() ?? "0";

      // Converte com segurança mesmo se vier como double ou string decimal
      final double? diaParsedDouble = double.tryParse(diaDescontoStr);
      final int diaLimiteDesconto = diaParsedDouble?.toInt() ?? 0;

      rawValor = (diaLimiteDesconto > 0 && diaAtual <= diaLimiteDesconto)
          ? (payment?.vpg_valor_desconto.toString() ?? "0.00")
          : (payment?.vpg_valor_normal.toString() ?? "0.00");
    }

    valor.text = generalService
        .currencyMoneyBr(rawValor)
        .replaceAll("R\$ ", "")
        .trim();
    comprovantepag.text = payment?.mes_comprovante_pag.toString() ?? "";
    formaPagamentoSelecionada.value = payment?.mes_fpg_id.toString() ?? "";
  }

  Future<void> selectDate(BuildContext context) async {
    if (widget.readOnly) return;
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2026, 8, 1),
      lastDate: DateTime(2028),
    );
    if (selected != null && selected != selectedDate) {
      setState(() {
        selectedDate = selected;
        datapagamento.text =
            "${selected.day.toString().padLeft(2, '0')}/${selected.month.toString().padLeft(2, '0')}/${selected.year}";
      });
    }
  }

  // 🟢 Modal com Suporte a Zoom (Pinch to zoom + Pan)
  void _openZoomDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double distance = 16.0;

    return Scaffold(
      appBar: CustomFloatingAppBar(
        title: '${widget.title} - ${fullNameController.text}',
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
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
                      key: formKey,
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

                          // --- BLOCO PRINCIPAL: Form à esquerda e Comprovante à direita ---
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Coluna da Esquerda (Campos)
                              Expanded(
                                flex: 2,
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: fullNameController,
                                      enabled: false,
                                      decoration: const InputDecoration(
                                        labelText: 'Nome:',
                                        prefixIcon: Icon(Icons.verified_user),
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                    const SizedBox(height: distance),
                                    TextFormField(
                                      controller: valor,
                                      enabled: !widget.readOnly,
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
                                      validator: (v) =>
                                          v == null || v.trim().isEmpty
                                          ? 'Informe o valor'
                                          : null,
                                    ),
                                    const SizedBox(height: distance),
                                    ListenableBuilder(
                                      listenable: bdFormaPagamentoController
                                          .formaPagamentoNotifier,
                                      builder: (context, child) {
                                        final listaFormas =
                                            bdFormaPagamentoController
                                                .formaPagamentoNotifier
                                                .value;
                                        if (listaFormas.isEmpty)
                                          return const Center(
                                            child: CircularProgressIndicator(),
                                          );

                                        bool valorExiste = listaFormas.any(
                                          (f) =>
                                              f.fpg_id.toString() ==
                                              formaPagamentoSelecionada.value,
                                        );
                                        if (!valorExiste)
                                          formaPagamentoSelecionada.value =
                                              null;

                                        return DropdownButtonFormField2<String>(
                                          valueListenable:
                                              formaPagamentoSelecionada,
                                          isExpanded: true,
                                          decoration: const InputDecoration(
                                            prefixIcon: Icon(Icons.payment),
                                            labelText: 'Forma de Pagamento:',
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  vertical: 16,
                                                  horizontal: 16,
                                                ),
                                            border: OutlineInputBorder(),
                                          ),
                                          hint: const Text('Selecione...'),
                                          items: listaFormas
                                              .map(
                                                (f) => DropdownItem<String>(
                                                  value: f.fpg_id.toString(),
                                                  child: Text(
                                                    f.fpg_descricao.toString(),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: widget.readOnly
                                              ? null
                                              : (val) =>
                                                    formaPagamentoSelecionada
                                                            .value =
                                                        val,
                                          validator: (val) =>
                                              val == null || val.isEmpty
                                              ? 'Selecione'
                                              : null,
                                        );
                                      },
                                    ),
                                    const SizedBox(height: distance),
                                    TextFormField(
                                      controller: datapagamento,
                                      enabled: !widget.readOnly,
                                      textAlign: TextAlign.end,
                                      readOnly: true,
                                      onTap: () => selectDate(context),
                                      decoration: const InputDecoration(
                                        labelText: 'Data Pagtº:',
                                        prefixIcon: Icon(Icons.calendar_month),
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (v) =>
                                          v == null || v.trim().isEmpty
                                          ? 'Informe a data'
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: distance),

                              // 🟢 Coluna da Direita (Comprovante com Altura Limitada)
                              Expanded(
                                flex: 1,
                                child: ValueListenableBuilder<bool>(
                                  valueListenable: bdMonthlyPaymentsController
                                      .loadingNotifier,
                                  builder: (context, isLoading, child) {
                                    if (isLoading) {
                                      return Container(
                                        height: 260,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }
                                    return ValueListenableBuilder(
                                      valueListenable:
                                          bdMonthlyPaymentsController
                                              .monthlyPaymentsIndividual,
                                      builder: (context, value, child) {
                                        final url =
                                            value?.mes_comprovante_pag ?? "";
                                        return Container(
                                          height:
                                              260, // 🟢 Altura fixa para evitar barra de rolagem desnecessária
                                          clipBehavior: Clip.antiAlias,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey.shade400,
                                            ),
                                          ),
                                          child: url.isNotEmpty
                                              ? Stack(
                                                  children: [
                                                    Positioned.fill(
                                                      child: Image.network(
                                                        url,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                    // 🟢 Botão para Abrir Zoom
                                                    Positioned(
                                                      top: 8,
                                                      right: 8,
                                                      child: CircleAvatar(
                                                        backgroundColor:
                                                            Colors.black54,
                                                        radius: 18,
                                                        child: IconButton(
                                                          padding:
                                                              EdgeInsets.zero,
                                                          icon: const Icon(
                                                            Icons.zoom_in,
                                                            color: Colors.white,
                                                            size: 20,
                                                          ),
                                                          onPressed: () =>
                                                              _openZoomDialog(
                                                                context,
                                                                url,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                    // 🟢 Botão para Alterar Foto (se permitido)
                                                    if (widget.allowImageUpload)
                                                      Positioned(
                                                        bottom: 8,
                                                        right: 8,
                                                        child: CircleAvatar(
                                                          backgroundColor:
                                                              Colors.indigo,
                                                          radius: 18,
                                                          child: IconButton(
                                                            padding:
                                                                EdgeInsets.zero,
                                                            icon: const Icon(
                                                              Icons.edit,
                                                              color:
                                                                  Colors.white,
                                                              size: 20,
                                                            ),
                                                            onPressed: widget
                                                                .onImageTap,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                )
                                              : GestureDetector(
                                                  onTap: widget.allowImageUpload
                                                      ? widget.onImageTap
                                                      : null,
                                                  child: Center(
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Icons.add_a_photo,
                                                          size: 44,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        Text(
                                                          widget.allowImageUpload
                                                              ? 'Toque para\nadicionar'
                                                              : 'Sem comprovante',
                                                          textAlign:
                                                              TextAlign.center,
                                                          style:
                                                              const TextStyle(
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
                            ],
                          ),

                          // INJEÇÃO DE CAMPOS EXTRAS
                          if (widget.extraFields != null) widget.extraFields!,

                          const Spacer(),
                          const SizedBox(height: distance),

                          // INJEÇÃO DOS BOTÕES DE AÇÃO
                          widget.actionButtons,
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
}
