import 'package:flutter/material.dart';
import 'package:originais/services/general_service.dart';
import 'package:originais/view/default_appbar.dart';
import 'package:originais/controllers/monthly_payments_controller.dart';
import 'package:originais/models/mensalidades_model.dart';
import 'package:originais/view/default_snackbar.dart'; 

class MonthlyPayments extends StatefulWidget {
  final String? hldId;
  const MonthlyPayments({
    super.key,
    this.hldId
  });

  @override
  State<MonthlyPayments> createState() => _MonthlyPaymentsState();
}

class _MonthlyPaymentsState extends State<MonthlyPayments> {
  final GeneralService generalService = GeneralService();
  late final BdMonthlyPaymentsController bdMonthlyPaymentsController;

  final String _searchQuery = '';
  String _filtroStatus = 'Todos';

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

    bdMonthlyPaymentsController =
        getItbdMonthlyPaymentsController<BdMonthlyPaymentsController>();

     // Inicializa o ouvinte em tempo real do banco de dados
    bdMonthlyPaymentsController.initRealtime( widget.hldId.toString() );

    DefaultSnackbar.attachErrorListener(
      context,
      bdMonthlyPaymentsController.errorNotifier
    );
    
    DefaultSnackbar.attachSuccessListener(
      context,
      bdMonthlyPaymentsController.successNotifier
    );
  }

  // ==========================================
  @override
  void dispose() {
    // Desvincular listener de erro para evitar vazamento de memória
    bdMonthlyPaymentsController.errorNotifier.removeListener(_onErrorChanged);
    bdMonthlyPaymentsController.disposeRealtime();
    super.dispose();
  }

  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DefaultAppbar(title: 'Monthly Payments'),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          bdMonthlyPaymentsController.loadingNotifier,
          bdMonthlyPaymentsController.errorNotifier,
          bdMonthlyPaymentsController.monthlyPaymentsNotifier,
        ]),
        builder: (context, _) {
          final isLoading = bdMonthlyPaymentsController.loadingNotifier.value;
          final errorMessage = bdMonthlyPaymentsController.errorNotifier.value;
          final lista = bdMonthlyPaymentsController.monthlyPaymentsNotifier.value;

          return Stack(
            children: [
              // 1. Estado de Erro sem dados prévios
              if (errorMessage != null && errorMessage.isNotEmpty && lista.isEmpty)
                _buildErrorState(errorMessage)
              // 2. Estado Sem Dados
              else if (lista.isEmpty && !isLoading)
                const Center(child: Text('Nenhuma mensalidade encontrada.'))
              // 3. Carregamento Inicial
              else if (lista.isEmpty && isLoading)
                const Center(child: CircularProgressIndicator())
              // 4. Conteúdo Principal
              else
                _buildTabContent(lista),

              // Overlay de carregamento enquanto o banco de dados está processando
              if (isLoading && lista.isNotEmpty)
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
                                'Processando...',
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
  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            errorMessage,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              bdMonthlyPaymentsController.initRealtime(
                widget.hldId.toString()
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  Widget _buildTabContent(List<MensalidadesModel> lista) {
    // 1. Extrai os meses/anos únicos
    final listaMesAno = lista
        .map((m) => '${m.month.toString().padLeft(2, '0')}/${m.year}')
        .toSet()
        .toList();

    final now = DateTime.now();
    final mesAnoAtual =
        '${now.month.toString().padLeft(2, '0')}/${now.year}';
    final indexAtual = listaMesAno.indexOf(mesAnoAtual);
    final int initialIndex = indexAtual != -1 ? indexAtual : 0;

    return DefaultTabController(
      length: listaMesAno.length,
      initialIndex: initialIndex,
      child: Builder(
        builder: (tabContext) {
          return Column(
            children: [
              // Linha com Abas e Filtro
              Row(
                children: [
                  Expanded(
                    child: TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      tabs: listaMesAno
                          .map((mesAno) => Tab(text: 'Ref: $mesAno'))
                          .toList(),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.filter_alt_outlined,
                      color: _filtroStatus == 'Todos'
                          ? Colors.grey
                          : Colors.green,
                    ),
                    tooltip: 'Filtrar status',
                    initialValue: _filtroStatus,
                    onSelected: (status) =>
                        setState(() => _filtroStatus = status),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'Todos',
                        child: Text('Todos'),
                      ),
                      const PopupMenuItem(
                        value: 'Pagas',
                        child: Text('Pagas'),
                      ),
                      const PopupMenuItem(
                        value: 'Pendentes',
                        child: Text('Pendentes'),
                      ),
                    ],
                  ),
                ],
              ),

              // Conteúdo das Listas
              Expanded(
                child: TabBarView(
                  children: listaMesAno.map((mesAnoRef) {
                    final listaFiltrada = lista.where((m) {
                      final refAtual =
                          '${m.month.toString().padLeft(2, '0')}/${m.year}';
                      if (refAtual != mesAnoRef) return false;

                      final nomeMatch = m.pfl_full_name
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase());
                      final isPago = m.tkt_paiment_path.isNotEmpty;

                      if (_filtroStatus == 'Pagas') {
                        return nomeMatch && isPago;
                      }
                      if (_filtroStatus == 'Pendentes') {
                        return nomeMatch && !isPago;
                      }
                      return nomeMatch;
                    }).toList();

                    if (listaFiltrada.isEmpty) {
                      return const Center(
                        child: Text('Nenhum registro para este filtro.'),
                      );
                    }

                    return Column(
                      children: [
                        _buildBalancete(listaFiltrada),
                        Expanded(
                          child: ListView.builder(
                            itemCount: listaFiltrada.length,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            itemBuilder: (context, index) {
                              return _buildMensalidadeCard(
                                listaFiltrada[index],
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),

              // Mensagem no Rodapé da Página
              AnimatedBuilder(
                animation: DefaultTabController.of(tabContext),
                builder: (context, child) {
                  final controller = DefaultTabController.of(tabContext);
                  final abaSelecionada = listaMesAno[controller.index];
                  final isAbaAtual = abaSelecionada == mesAnoAtual;

                  if (isAbaAtual) return const SizedBox.shrink();

                  return Container(
                    width: double.infinity,
                    color: Colors.amber.shade900.withValues(alpha: 0.8),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
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
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  Widget _buildBalancete(List<MensalidadesModel> lista) {
    final int totalPessoas = lista.length;
    final int quantasPagaram =
        lista.where((m) => m.tkt_paiment_path.isNotEmpty).length;

    final double totalValorPago = lista.fold<double>(0.0, (soma, m) {
      if (m.month.isNotEmpty) {
        final double valor = double.tryParse(m.tit_value.toString()) ?? 0.0;
        return soma + valor;
      }
      return soma;
    });

    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                'Total Pessoas',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                '$totalPessoas',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          Container(height: 24, width: 1, color: Colors.grey.shade400),
          Column(
            children: [
              const Text(
                'Pagaram',
                style: TextStyle(fontSize: 11, color: Colors.green),
              ),
              const SizedBox(height: 2),
              Text(
                '$quantasPagaram',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          Container(height: 24, width: 1, color: Colors.grey.shade400),
          Column(
            children: [
              const Text(
                'Total Pago',
                style: TextStyle(fontSize: 11, color: Colors.green),
              ),
              const SizedBox(height: 2),
              Text(
                generalService.currencyMoneyBr(totalValorPago.toString()),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  Widget _buildMensalidadeCard(MensalidadesModel mensalidade) {
    final bool temComprovante = mensalidade.tkt_paiment_path.isNotEmpty;
    final bool isPago = temComprovante;

    final now = DateTime.now();
    final int mesRef = int.tryParse(mensalidade.month.toString()) ?? 0;
    final int anoRef = int.tryParse(mensalidade.year.toString()) ?? 0;
    final bool isMesAnoAtual = (mesRef == now.month) && (anoRef == now.year);

    double porcPorc = double.parse(mensalidade.pas_monthly_percent) / 100.0;
    double porcValor = double.parse(mensalidade.vpg_valor_desconto) * porcPorc;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.indigo.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
          Icons.calendar_month,
          color: isPago ? Colors.greenAccent : Colors.orangeAccent,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                mensalidade.pfl_full_name.isNotEmpty
                    ? mensalidade.pfl_full_name
                    : 'Sócio / Membro',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusBadge(isPago),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            'Ref: ${mensalidade.month.toString().padLeft(2, '0')}/${mensalidade.year} • '
            'Valor Base: ${generalService.currencyMoneyBr(mensalidade.vpg_valor_normal.toString())} • ${mensalidade.vpg_desc}',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ),
        children: [
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.all(12.0),
            color: Colors.black12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detalhes da Mensalidade:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Desconto até dia: ${mensalidade.vpg_dia_valor_desconto.toString()} • '
                            'Valor: ${generalService.currencyMoneyBr(mensalidade.vpg_valor_desconto.toString())}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Porcentagem: ${mensalidade.pas_monthly_percent.toString()}%  • '
                            'Valor: ${generalService.currencyMoneyBr(porcValor.toString())}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      generalService.currencyMoneyBr(
                        mensalidade.tit_value.toString(),
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (temComprovante)
                      OutlinedButton.icon(
                        onPressed: () => _mostrarComprovante(
                          context,
                          mensalidade.tkt_paiment_path,
                        ),
                        icon: const Icon(Icons.image_search, size: 16),
                        label: const Text('Ver Comprovante'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orangeAccent,
                          side: const BorderSide(color: Colors.orangeAccent),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    if (!isPago && isMesAnoAtual)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                        ),
                        onPressed: () {
                          debugPrint(
                            'Ir para pagamento do perfil: ${mensalidade.pfl_full_name}',
                          );
                        },
                        icon: const Icon(Icons.payment, size: 16),
                        label: const Text(
                          'Pagar Agora',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  Widget _buildStatusBadge(bool isPago) {
    String label = isPago ? 'PAGO' : 'PENDENTE';
    Color color = isPago ? Colors.greenAccent : Colors.orangeAccent;
    Color bgColor =
        (isPago ? Colors.green : Colors.orange).withValues(alpha: 0.15);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // ==========================================
  void _mostrarComprovante(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Comprovante de Pagamento',
          style: TextStyle(fontSize: 16),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Text(
                        'Erro ao carregar imagem do comprovante.',
                        style: TextStyle(color: Colors.red, fontSize: 12),
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}