import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:foundation/core.dart';
import 'package:originais/models/profile_model.dart';

import 'package:image_picker/image_picker.dart';
import 'package:originais/services/BaseImageUploadService.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'package:originais/models/custom_app_bar.dart';

import 'package:originais/controllers/products_controller.dart';
import 'package:originais/models/products_model.dart';

import 'package:originais/controllers/bd_profile_controller.dart';
import 'package:originais/models/vprofile_model.dart';

import 'package:originais/controllers/ticketController.dart';
import 'package:originais/models/ticketModel.dart';

import 'package:originais/services/general_service.dart';
import 'dart:io';

import 'package:originais/services/general_service.dart';
import 'package:originais/services/BaseImageUploadService.dart';
import 'package:originais/controllers/TicketReceiptImageService.dart';

class HeadquartersBarOpened extends StatefulWidget {
  String openDate;
  String hld_id;
  final bool isReadOnly;

  HeadquartersBarOpened({
    super.key,
    required this.openDate,
    required this.hld_id,
    this.isReadOnly = false,
  });

  @override
  State<HeadquartersBarOpened> createState() => HeadquartersBarOpenedState();
}

class HeadquartersBarOpenedState extends State<HeadquartersBarOpened> {
  final _formKey = GlobalKey<FormState>();

  final ImagePicker _picker = ImagePicker();

  final generalService = getItGeneralService<GeneralService>();

  final productsController = getItProductsController<ProductsController>();
  late List<ProductsModel> _catalogoProdutos = [];

  final bdProfileController = getItBdProfileController<BdProfileController>();
  late List<VProfileModel> _clientesCadastrados = [];

  final ticketController = getItTicketController<TicketController>();
  late List<TicketStatusModel> ticketStatusList = [];

  final loadingNotifier = ValueNotifier<bool>(false);
  final errorNotifier = ValueNotifier<String?>(null);

  late final TicketReceiptImageService paymentService;
  // ==========================================
  @override
  void initState() {
    super.initState();

    _catalogoProdutos = productsController.productsNotifier.value;

    final tmpProfiles = bdProfileController.profilesNotifier.value;
    _clientesCadastrados = tmpProfiles
        .where((c) => c.as_ismonthlypayment == 'true')
        .toList();

    ticketStatusList = ticketController.ticketStatusNotifier.value;

    ticketController.loadTickets(widget.openDate, widget.hld_id);

    paymentService = TicketReceiptImageService(
      loadingNotifier: loadingNotifier,
      errorNotifier: errorNotifier,
    );
  }

  // ---------------------------------------------------------------------------
  @override
  void dispose() {
    super.dispose();
  }

  // ==========================================
  String id_ticketStatusList(String name) {
    final tmp = ticketStatusList
        .where((c) => c.tst_name == name)
        .firstOrNull
        ?.tst_id;
    return tmp.toString();
  }

  // 3. DIÁLOGO DE PAGAMENTO DA MESA
  // ---------------------------------------------------------------------------
  void _mostrarDialogFecharComPagamento(TicketsModel mesa) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final bool temFoto = mesa.tkt_paiment_path != null;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text('Pagamento: ${mesa.tkt_table_number}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total a pagar: ${generalService.currencyMoneyBr(mesa.totalConsumo.toString())}\n\n'
                    'Comprovante/Foto confirma seu pagamento!!!',
                  ),
                  const SizedBox(height: 16),

                  // 📸 Botão para capturar ou escolher a foto do comprovante
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        // 🟢 Chama o menu de opções
                        // _escolherMetodoAnexo();
                        final tst_id = id_ticketStatusList(
                          'Ticket closed (Paid)',
                        );
                        await paymentService.selecionarAnexoEEnviar(
                          context: context,
                          payload: {
                            'tkt_id': mesa.tkt_id,
                            'pfl_id': mesa.tkt_pfl_id,
                            'tkt_tst_id': tst_id,
                            'openDate': widget.openDate,
                            'hld_id': widget.hld_id,
                          },
                        );
                        if (context.mounted && errorNotifier.value == null) {
                          Navigator.of(
                            context,
                          ).pop(); // Fecha o Dialog da comanda
                        }
                      },
                      icon: Icon(Icons.add_a_photo, color: Colors.orangeAccent),
                      label: Text(
                        'Anexar Comprovante / Foto',
                        style: TextStyle(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.indigoAccent),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                // ElevatedButton(
                //   onPressed: () {
                //     setState(() {
                //       // mesa.status = StatusMesa.fechadaComPagamento;
                //       mesa.tkt_tst_id = id_ticketStatusList(
                //         'Ticket closed (Paid)',
                //       );
                //     });
                //     Navigator.pop(dialogContext);
                //   },
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Colors.green,
                //     foregroundColor: Colors.white,
                //   ),
                //   child: const Text('Confirmar Pagamento'),
                // ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 🟢 DIÁLOGO DE VER COMPROVANTE ANEXADO
  void _mostrarComprovante(TicketsModel mesa) {
    final String? imageUrl = mesa.tkt_paiment_path;
    final bool temComprovante = imageUrl != null && imageUrl.trim().isNotEmpty;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Proof of payment: ${mesa.tkt_table_number} - ${mesa.pfl_full_name}',
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (temComprovante)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 1.0, // Zoom mínimo (tamanho original)
                      maxScale: 4.0,
                      child: Container(
                        width: double
                            .infinity, // 🟢 Centraliza a imagem no meio da largura do Dialog
                        alignment: Alignment.center,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    color: Colors.red,
                                    size: 48,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Erro ao carregar imagem do Supabase.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  // GERENCIAR AÇÕES DE FECHAMENTO/DELEÇÃO DA MESA (ÍCONE DE FECHAR)
  // ---------------------------------------------------------------------------
  Future<void> _mostrarDialogAcaoMesa(TicketsModel mesa) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        final isAberta =
            mesa.tkt_tst_id == id_ticketStatusList('Ticket opened');

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                isAberta ? Icons.warning_amber_rounded : Icons.settings,
                color: isAberta ? Colors.orange : Colors.indigoAccent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${mesa.tkt_table_number} (${mesa.tkt_client_name})',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isAberta) ...[
                const Text(
                  'Escolha a forma de encerramento da mesa:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Valor total: ${generalService.currencyMoneyBr(mesa.totalConsumo.toString())}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Text(
                  mesa.tkt_tst_id == id_ticketStatusList('Ticket closed (Paid)')
                      ? 'Esta mesa está Fechada COM Pagamento.'
                      : 'Esta mesa está Fechada SEM Pagamento.',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            if (isAberta) ...[
              OutlinedButton(
                onPressed: () {
                  final tktTstId = id_ticketStatusList(
                    'Ticket closed without payment',
                  );
                  ticketController.closeTicketsWithoutPayment(
                    mesa.tkt_id.toString(),
                    tktTstId,
                    widget.openDate,
                    widget.hld_id,
                  );
                  Navigator.pop(dialogContext);
                },
                style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
                child: const Text('Fechar s/ Pagamento'),
              ),
              if (mesa.totalConsumo > 0.01) ...[
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _mostrarDialogFecharComPagamento(mesa);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Fechar c/ Pagamento'),
                ),
              ],
            ] else if (mesa.tkt_tst_id ==
                id_ticketStatusList('Ticket closed without payment')) ...[
              OutlinedButton(
                onPressed: () {
                  final tktTstId = id_ticketStatusList('Ticket opened');
                  ticketController.closeTicketsWithoutPayment(
                    mesa.tkt_id.toString(),
                    tktTstId,
                    widget.openDate,
                    widget.hld_id,
                  );
                  Navigator.pop(dialogContext);
                },
                child: const Text('Reabrir Mesa'),
              ),
            ],
          ],
        );
      },
    );
  }

  // POPUP PARA LANÇAR ITENS NA MESA
  // ---------------------------------------------------------------------------
  Future<void> _mostrarDialogLancarItem(TicketsModel mesa) async {
    // if (mesa.status != StatusMesa.aberta) {
    if (mesa.tkt_tst_id != id_ticketStatusList('Ticket opened')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reabra a mesa para lançar novos itens!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String categoriaSelecionada = 'Bebidas';
    ProductsModel? produtoSelecionado;
    int quantidade = 1;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final produtosFiltrados = _catalogoProdutos
                .where((p) => p.cpdt_desc == categoriaSelecionada)
                .toList();

            double precoCalculado = 0.0;
            if (produtosFiltrados.isNotEmpty) {
              if (produtoSelecionado == null ||
                  produtoSelecionado!.cpdt_desc != categoriaSelecionada) {
                produtoSelecionado = produtosFiltrados.first;
              }
              precoCalculado = mesa.tkt_has_discount
                  ? double.parse(produtoSelecionado!.pdt_value_member)
                  : double.parse(produtoSelecionado!.pdt_value_visitant);
            } else {
              produtoSelecionado = null;
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  const Icon(Icons.add_shopping_cart, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lançar Item - ${mesa.tkt_table_number}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 340,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selecione a Categoria:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'Bebidas',
                          label: Text('Bebidas'),
                          icon: Icon(Icons.local_bar_outlined),
                        ),
                        ButtonSegment(
                          value: 'Drinks',
                          label: Text('Drinks'),
                          icon: Icon(Icons.local_cafe_outlined),
                        ),
                        ButtonSegment(
                          value: 'Porções',
                          label: Text('Porções'),
                          icon: Icon(Icons.restaurant_outlined),
                        ),
                      ],
                      selected: {categoriaSelecionada},
                      onSelectionChanged: (Set<String> newSelection) {
                        setDialogState(() {
                          categoriaSelecionada = newSelection.first;
                          produtoSelecionado = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (produtosFiltrados.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          'Nenhum produto cadastrado nesta categoria.',
                          style: TextStyle(color: Colors.orangeAccent),
                        ),
                      )
                    else
                      DropdownButtonFormField<ProductsModel>(
                        initialValue: produtoSelecionado,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Produto',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.fastfood_outlined),
                        ),
                        items: produtosFiltrados.map((prod) {
                          return DropdownMenuItem<ProductsModel>(
                            value: prod,
                            child: Text(
                              mesa.tkt_has_discount
                                  ? '${prod.pdt_name} (${generalService.currencyMoneyBr(prod.pdt_value_member)})'
                                  : '${prod.pdt_name} (${generalService.currencyMoneyBr(prod.pdt_value_visitant)})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            produtoSelecionado = value;
                          });
                        },
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Quantidade:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              color: Colors.redAccent,
                              onPressed: quantidade > 1
                                  ? () => setDialogState(() => quantidade--)
                                  : null,
                            ),
                            Text(
                              '$quantidade',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              color: Colors.greenAccent,
                              onPressed: () =>
                                  setDialogState(() => quantidade++),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          mesa.tkt_has_discount
                              ? 'Subtotal (com desconto):'
                              : 'Subtotal:',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          generalService.currencyMoneyBr(
                            (precoCalculado * quantidade).toString(),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.greenAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton.icon(
                  onPressed: produtoSelecionado == null
                      ? null
                      : () async {
                          if (produtoSelecionado != null) {
                            // setState(() {
                            final indexExistente = mesa.ticketsItems.indexWhere(
                              (p) => p.pdt_name == produtoSelecionado!.pdt_name,
                            );

                            if (indexExistente >= 0) {
                              await ticketController.updateTicketsItems(
                                mesa.ticketsItems[indexExistente].tit_id
                                    .toString(),
                                mesa
                                        .ticketsItems[indexExistente]
                                        .tit_quantities +
                                    quantidade,
                                widget.openDate,
                                widget.hld_id,
                              );
                            } else {
                              final ticketsItems2Controller = TicketsItemsModel(
                                tit_hld_id: widget.hld_id,
                                tit_tkt_id: mesa.tkt_id.toString(),
                                tit_pdt_id: produtoSelecionado!.pdt_id,
                                tit_quantities: quantidade,
                                tit_unit_value: precoCalculado,
                                tit_value: quantidade * precoCalculado,
                              );

                              await ticketController.insertTicketsItems(
                                ticketsItems2Controller,
                                widget.openDate,
                                widget.hld_id,
                              );
                            }
                            Navigator.pop(dialogContext);
                            _mostrarResumoMesa(mesa);
                          }
                        },
                  icon: const Icon(Icons.check),
                  label: const Text('Confirmar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // POPUP DE RESUMO DA MESA (COM OVERLAY DE LOADING ESTÁVEL)
  // ---------------------------------------------------------------------------
  Future<void> _mostrarResumoMesa(TicketsModel mesa) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return ValueListenableBuilder<bool>(
          valueListenable: ticketController.loadingNotifier,
          builder: (context, isLoading, _) {
            return ValueListenableBuilder<List<TicketsModel>>(
              valueListenable: ticketController.ticketNotifier,
              builder: (context, listaMesasAtualizada, _) {
                final mesaAtual = listaMesasAtualizada.firstWhere(
                  (m) => m.tkt_id == mesa.tkt_id,
                  orElse: () => mesa,
                );

                final bool isFechadaPaga =
                    mesaAtual.tkt_tst_id ==
                    id_ticketStatusList('Ticket closed (Paid)');
                final bool isFechadaSemPag =
                    mesaAtual.tkt_tst_id ==
                    id_ticketStatusList('Ticket closed without payment');
                final bool isFechada = isFechadaPaga || isFechadaSemPag;
                final bool temConsumo = mesaAtual.totalConsumo > 0.01;

                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  titlePadding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.table_bar,
                              color: isFechadaPaga
                                  ? Colors.green
                                  : (isFechadaSemPag
                                        ? Colors.grey
                                        : (mesaAtual.tkt_has_discount
                                              ? Colors.amber
                                              : Colors.indigoAccent)),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                mesaAtual.tkt_table_number,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isFechada
                                      ? Colors.white54
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isFechada && !widget.isReadOnly && temConsumo) ...[
                        ElevatedButton.icon(
                          onPressed: isLoading
                              ? null
                              : () {
                                  Navigator.pop(dialogContext);
                                  _mostrarDialogFecharComPagamento(mesaAtual);
                                },
                          icon: const Icon(Icons.attach_money, size: 16),
                          label: const Text('Fechar e Pagar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),

                  content: SizedBox(
                    width: 360,
                    child: Stack(
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.person_outline,
                                  size: 16,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    mesaAtual.tkt_client_name.toString(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isFechada
                                          ? Colors.white54
                                          : Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 220),
                              child: mesaAtual.ticketsItems.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 24.0,
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Nenhum item consumido ainda.',
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      shrinkWrap: true,
                                      itemCount: mesaAtual.ticketsItems.length,
                                      separatorBuilder: (_, _) =>
                                          const Divider(height: 1),
                                      itemBuilder: (context, idx) {
                                        final item =
                                            mesaAtual.ticketsItems[idx];
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4.0,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.pdt_name.toString(),
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: isFechada
                                                            ? Colors.white38
                                                            : Colors.white,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      '${generalService.currencyMoneyBr(item.tit_value.toString())} (${generalService.currencyMoneyBr(item.tit_unit_value.toString())} un.)',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.white54,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (!isFechada &&
                                                  !widget.isReadOnly) ...[
                                                IconButton(
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                  icon: Icon(
                                                    item.tit_quantities > 1
                                                        ? Icons
                                                              .remove_circle_outline
                                                        : Icons.delete_outline,
                                                    color: Colors.redAccent,
                                                    size: 20,
                                                  ),
                                                  onPressed: isLoading
                                                      ? null
                                                      : () async {
                                                          if (item.tit_quantities >
                                                              1) {
                                                            await ticketController
                                                                .updateTicketsItems(
                                                                  item.tit_id
                                                                      .toString(),
                                                                  item.tit_quantities -
                                                                      1,
                                                                  widget
                                                                      .openDate,
                                                                  widget.hld_id,
                                                                );
                                                          } else {
                                                            await ticketController
                                                                .deleteTicketsItems(
                                                                  item.tit_id
                                                                      .toString(),
                                                                  widget
                                                                      .openDate,
                                                                  widget.hld_id,
                                                                );
                                                          }
                                                        },
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8.0,
                                                      ),
                                                  child: Text(
                                                    '${item.tit_quantities}',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                  icon: const Icon(
                                                    Icons.add_circle_outline,
                                                    color: Colors.greenAccent,
                                                    size: 20,
                                                  ),
                                                  onPressed: isLoading
                                                      ? null
                                                      : () async {
                                                          await ticketController
                                                              .updateTicketsItems(
                                                                item.tit_id
                                                                    .toString(),
                                                                item.tit_quantities +
                                                                    1,
                                                                widget.openDate,
                                                                widget.hld_id,
                                                              );
                                                        },
                                                ),
                                              ] else ...[
                                                Text(
                                                  '${item.tit_quantities}',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.white54,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Parcial:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  generalService.currencyMoneyBr(
                                    mesaAtual.totalConsumo.toString(),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.greenAccent,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),

                        if (isLoading)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.indigoAccent,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Fechar'),
                    ),
                    if (!isFechada && !widget.isReadOnly)
                      ElevatedButton.icon(
                        onPressed: isLoading
                            ? null
                            : () {
                                Navigator.pop(dialogContext);
                                _mostrarDialogLancarItem(mesaAtual);
                              },
                        icon: const Icon(Icons.add_shopping_cart, size: 16),
                        label: const Text('Lançar Item'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    if (isFechada)
                      ElevatedButton.icon(
                        onPressed: isLoading
                            ? null
                            : () {
                                Navigator.pop(dialogContext);
                                _mostrarComprovante(mesaAtual);
                              },
                        icon: const Icon(Icons.add_shopping_cart, size: 16),
                        label: const Text('Ver Comprovante'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // DIÁLOGO PARA ADICIONAR NOVA MESA
  // ---------------------------------------------------------------------------
  Future<void> _mostrarDialogAdicionarMesa() async {
    final nomeClienteController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();

    bool isClienteCadastrado = true;
    final clienteSelecionado = ValueNotifier<VProfileModel?>(null);

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final listaMesasAtuais = ticketController.ticketNotifier.value;

            final idsClientesComMesaAberta = listaMesasAtuais
                .where(
                  (m) =>
                      m.tkt_tst_id == id_ticketStatusList('Ticket opened') &&
                      m.tkt_pfl_id != null &&
                      m.tkt_pfl_id.toString().isNotEmpty,
                )
                .map((m) => m.tkt_pfl_id.toString())
                .toSet();

            final clientesDisponIVEIS = _clientesCadastrados
                .where(
                  (c) =>
                      !idsClientesComMesaAberta.contains(c.pfl_id.toString()),
                )
                .toList();

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.table_restaurant, color: Colors.indigo),
                  SizedBox(width: 8),
                  Text('Open Ticket'),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: dialogFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tipo de Atendimento:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('Cadastrado'),
                            icon: Icon(Icons.badge_outlined),
                          ),
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('Avulso'),
                            icon: Icon(Icons.person_outline),
                          ),
                        ],
                        selected: {isClienteCadastrado},
                        onSelectionChanged: (Set<bool> newSelection) {
                          setDialogState(() {
                            isClienteCadastrado = newSelection.first;
                            clienteSelecionado.value = null;
                            nomeClienteController.clear();
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      if (isClienteCadastrado) ...[
                        if (clientesDisponIVEIS.isEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Todos os clientes cadastrados já estão com mesa aberta.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orangeAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          DropdownButtonFormField2<VProfileModel>(
                            valueListenable: clienteSelecionado,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Selecionar Cliente Cadastrado',
                              prefixIcon: Icon(Icons.star, color: Colors.amber),
                              border: OutlineInputBorder(),
                              helperText:
                                  '⭐ Cliente possui tabela de preço diferenciada',
                            ),
                            items: clientesDisponIVEIS.map((cliente) {
                              return DropdownItem<VProfileModel>(
                                value: cliente,
                                child: Text(
                                  cliente.pfl_full_name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setDialogState(() {
                                clienteSelecionado.value = value;
                              });
                            },
                            validator: (value) {
                              if (isClienteCadastrado && value == null) {
                                return 'Selecione um cliente cadastrado!';
                              }
                              return null;
                            },
                          ),
                        ],
                      ] else ...[
                        TextFormField(
                          controller: nomeClienteController,
                          autofocus: true,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Nome do Cliente Avulso',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (!isClienteCadastrado &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Informe o nome do cliente avulso!';
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),

                ValueListenableBuilder<bool>(
                  valueListenable: ticketController.loadingNotifier,
                  builder: (context, isLoading, _) {
                    return ElevatedButton.icon(
                      onPressed:
                          (isLoading ||
                              (isClienteCadastrado &&
                                  clientesDisponIVEIS.isEmpty))
                          ? null
                          : () async {
                              if (dialogFormKey.currentState!.validate()) {
                                final String nomeFinal = isClienteCadastrado
                                    ? clienteSelecionado.value?.pfl_full_name ??
                                          ''
                                    : nomeClienteController.text.toString();

                                final String? idClienteFinal =
                                    isClienteCadastrado
                                    ? clienteSelecionado.value?.pfl_id
                                          .toString()
                                    : null;

                                final tickets = TicketsModel(
                                  tkt_hld_id: widget.hld_id,
                                  tkt_bar_open_date: widget.openDate,
                                  tkt_table_number: '',
                                  tkt_client_name: nomeFinal,
                                  tkt_pfl_id: idClienteFinal,
                                  tkt_has_discount: isClienteCadastrado,
                                  tkt_tst_id: id_ticketStatusList(
                                    'Ticket opened',
                                  ),
                                );

                                // Envia para o Supabase e atualiza o ticketNotifier
                                await ticketController.openTicketsFunction(
                                  tickets,
                                  widget.openDate,
                                  widget.hld_id,
                                );

                                // Fecha o diálogo se ainda estiver montado
                                if (context.mounted) {
                                  Navigator.pop(dialogContext);
                                }
                              }
                            },
                      icon: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(isLoading ? 'Abrindo...' : 'Adicionar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 🟢 WIDGET DO PAINEL DE TOTAIS DE VENDAS
  // ---------------------------------------------------------------------------
  Widget _buildDashboardVendas() {
    return ValueListenableBuilder<List<TicketsModel>>(
      valueListenable: ticketController.ticketNotifier,
      builder: (context, listaMesas, _) {
        final int totalMesas = listaMesas.length;

        final double totalVendasGeral = listaMesas.fold<double>(
          0.0,
          (soma, mesa) => soma + mesa.totalConsumo,
        );

        final double totalVendasCadastrados = listaMesas
            .where((mesa) => mesa.tkt_has_discount)
            .fold<double>(0.0, (soma, mesa) => soma + mesa.totalConsumo);

        final double totalVendasAvulsos = listaMesas
            .where((mesa) => !mesa.tkt_has_discount)
            .fold<double>(0.0, (soma, mesa) => soma + mesa.totalConsumo);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.indigo.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.indigo.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text(
                    'Total de Mesas',
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$totalMesas',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.greenAccent,
                    ),
                  ),
                ],
              ),
              Container(height: 24, width: 1, color: Colors.white24),

              Column(
                children: [
                  const Text(
                    'Total de Vendas',
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    generalService.currencyMoneyBr(totalVendasGeral.toString()),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.greenAccent,
                    ),
                  ),
                ],
              ),
              Container(height: 24, width: 1, color: Colors.white24),

              Column(
                children: [
                  const Text(
                    'Membros ⭐',
                    style: TextStyle(fontSize: 11, color: Colors.amber),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    generalService.currencyMoneyBr(
                      totalVendasCadastrados.toString(),
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
              Container(height: 24, width: 1, color: Colors.white24),

              Column(
                children: [
                  const Text(
                    'Visitas 👤',
                    style: TextStyle(fontSize: 11, color: Colors.indigoAccent),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    generalService.currencyMoneyBr(
                      totalVendasAvulsos.toString(),
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.indigoAccent,
                    ),
                  ),
                ],
              ),

              if (!widget.isReadOnly) ...[
                Container(height: 24, width: 1, color: Colors.white24),
                Column(
                  children: [
                    SizedBox(
                      width: 45,
                      height: 35,
                      child: FloatingActionButton(
                        heroTag: 'addItemCardFab',
                        elevation: 2,
                        onPressed: () {
                          _mostrarDialogAdicionarMesa();
                        },
                        child: const Icon(Icons.add, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    const double distance = 16.0;

    return Scaffold(
      appBar: CustomFloatingAppBar(
        title:
            'Headquarters Bar - ${generalService.formatarDataBr(widget.openDate)}',
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  if (widget.isReadOnly)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      color: Colors.amber.shade900.withValues(alpha: 0.8),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_clock, color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Modo de Consulta (Somente Leitura)',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  _buildDashboardVendas(),
                  const SizedBox(height: distance),

                  Expanded(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: ticketController.loadingNotifier,
                      builder: (context, isLoading, _) {
                        return ValueListenableBuilder<List<TicketsModel>>(
                          valueListenable: ticketController.ticketNotifier,
                          builder: (context, listaMesas, _) {
                            if (isLoading && listaMesas.isEmpty) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final idAberto = id_ticketStatusList(
                              'Ticket opened',
                            );

                            final mesasOrdenadas =
                                List<TicketsModel>.from(listaMesas)..sort((
                                  a,
                                  b,
                                ) {
                                  final aAberta = a.tkt_tst_id == idAberto;
                                  final bAberta = b.tkt_tst_id == idAberto;

                                  // 1. Coloca mesas abertas primeiro e fechadas depois
                                  if (aAberta && !bAberta) return -1;
                                  if (!aAberta && bAberta) return 1;

                                  // 2. Ordenação secundária (por número/identificador da mesa)
                                  return (a.tkt_table_number ?? '').compareTo(
                                    b.tkt_table_number ?? '',
                                  );
                                });

                            return InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Tables',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.only(
                                  left: 8.0,
                                  right: 8.0,
                                  top: 30.0,
                                ),
                              ),
                              child: SizedBox.expand(
                                child: mesasOrdenadas.isEmpty
                                    ? const Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.table_bar_outlined,
                                              size: 48,
                                              color: Colors.white38,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Nenhuma mesa adicionada.',
                                              style: TextStyle(
                                                color: Colors.white54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : GridView.builder(
                                        gridDelegate:
                                            const SliverGridDelegateWithMaxCrossAxisExtent(
                                              maxCrossAxisExtent: 180,
                                              childAspectRatio: 1.40,
                                              crossAxisSpacing: 10,
                                              mainAxisSpacing: 10,
                                            ),
                                        itemCount: mesasOrdenadas.length,
                                        itemBuilder: (context, index) {
                                          final mesa = mesasOrdenadas[index];
                                          final bool isFechadaPaga =
                                              mesa.tkt_tst_id ==
                                              id_ticketStatusList(
                                                'Ticket closed (Paid)',
                                              );
                                          final bool isFechadaSemPag =
                                              mesa.tkt_tst_id ==
                                              id_ticketStatusList(
                                                'Ticket closed without payment',
                                              );
                                          final bool isFechada =
                                              isFechadaPaga || isFechadaSemPag;

                                          // Cores dinâmicas para estado da mesa
                                          Color cardColor = Colors.indigo
                                              .withValues(alpha: 0.15);
                                          Color borderColor =
                                              Colors.indigoAccent;

                                          if (isFechadaPaga) {
                                            cardColor = Colors.green.withValues(
                                              alpha: 0.08,
                                            );
                                            borderColor = Colors.green
                                                .withValues(alpha: 0.4);
                                          } else if (isFechadaSemPag) {
                                            cardColor = Colors.grey.withValues(
                                              alpha: 0.08,
                                            );
                                            borderColor = Colors.grey
                                                .withValues(alpha: 0.3);
                                          } else if (mesa.tkt_has_discount) {
                                            cardColor = Colors.amber.withValues(
                                              alpha: 0.12,
                                            );
                                            borderColor = Colors.amber;
                                          }

                                          return InkWell(
                                            onTap: () =>
                                                _mostrarResumoMesa(mesa),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            child: Card(
                                              elevation: isFechada ? 0 : 2,
                                              color: cardColor,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                side: BorderSide(
                                                  color: borderColor,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  6.0,
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    // Topo
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          mesa.tkt_table_number,
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 12,
                                                            color: isFechada
                                                                ? Colors.white38
                                                                : Colors.white,
                                                          ),
                                                        ),
                                                        if (!widget
                                                            .isReadOnly) ...[
                                                          GestureDetector(
                                                            onTap: () =>
                                                                _mostrarDialogAcaoMesa(
                                                                  mesa,
                                                                ),
                                                            child: Icon(
                                                              Icons.close,
                                                              size: 18,
                                                              color: isFechada
                                                                  ? Colors
                                                                        .white38
                                                                  : Colors
                                                                        .redAccent,
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),

                                                    // Nome do Cliente
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          isFechadaPaga
                                                              ? Icons.task_alt
                                                              : (isFechadaSemPag
                                                                    ? Icons
                                                                          .block
                                                                    : (mesa.tkt_has_discount
                                                                          ? Icons.star
                                                                          : Icons.person_outline)),
                                                          size: 12,
                                                          color: isFechadaPaga
                                                              ? Colors
                                                                    .greenAccent
                                                              : (isFechadaSemPag
                                                                    ? Colors
                                                                          .white38
                                                                    : (mesa.tkt_has_discount
                                                                          ? Colors.amber
                                                                          : Colors.indigoAccent)),
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            (mesa.tkt_client_name !=
                                                                        null &&
                                                                    mesa
                                                                        .tkt_client_name!
                                                                        .isNotEmpty &&
                                                                    mesa.tkt_client_name !=
                                                                        'null')
                                                                ? mesa.tkt_client_name
                                                                      .toString()
                                                                : mesa.pfl_full_name
                                                                      .toString(),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 13,
                                                              color: isFechada
                                                                  ? Colors
                                                                        .white38
                                                                  : (mesa.tkt_has_discount
                                                                        ? Colors
                                                                              .amber[200]
                                                                        : Colors
                                                                              .white),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),

                                                    // Rodapé
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Flexible(
                                                          child: FittedBox(
                                                            fit: BoxFit
                                                                .scaleDown,
                                                            alignment: Alignment
                                                                .centerLeft,
                                                            child: Text(
                                                              generalService
                                                                  .currencyMoneyBr(
                                                                    mesa.totalConsumo
                                                                        .toString(),
                                                                  ),
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    isFechadaPaga
                                                                    ? Colors
                                                                          .greenAccent
                                                                          .withValues(
                                                                            alpha:
                                                                                0.7,
                                                                          )
                                                                    : (isFechadaSemPag
                                                                          ? Colors.redAccent.withValues(
                                                                              alpha: 0.6,
                                                                            )
                                                                          : Colors.greenAccent),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        if (isFechadaPaga)
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 4,
                                                                  vertical: 2,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color: Colors
                                                                  .green
                                                                  .withValues(
                                                                    alpha: 0.2,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    4,
                                                                  ),
                                                            ),
                                                            child: const Text(
                                                              'PAGO',
                                                              style: TextStyle(
                                                                fontSize: 8,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .greenAccent,
                                                              ),
                                                            ),
                                                          )
                                                        else if (isFechadaSemPag)
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 4,
                                                                  vertical: 2,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color: Colors.red
                                                                  .withValues(
                                                                    alpha: 0.15,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    4,
                                                                  ),
                                                            ),
                                                            child: const Text(
                                                              'S/ PAG.',
                                                              style: TextStyle(
                                                                fontSize: 8,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .redAccent,
                                                              ),
                                                            ),
                                                          )
                                                        else if (mesa
                                                            .tkt_has_discount)
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 4,
                                                                  vertical: 2,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color: Colors
                                                                  .amber
                                                                  .withValues(
                                                                    alpha: 0.2,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    4,
                                                                  ),
                                                            ),
                                                            child: const Text(
                                                              'Associated',
                                                              style: TextStyle(
                                                                fontSize: 8,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .amber,
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: distance),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Cancelar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.indigo,
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
}
