import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gorouter_exemplo/models/vprofile_model.dart';
import 'package:gorouter_exemplo/services/general_service.dart';
import 'package:gorouter_exemplo/controllers/bd_journeyriding_controller.dart';
import 'package:gorouter_exemplo/models/custom_app_bar.dart';
import 'package:gorouter_exemplo/models/vprofile_journeyriding_mode.dart';

class AssociatesDetails extends StatefulWidget {
  final VProfileModel itemAtual;
  
  const AssociatesDetails({super.key, required this.itemAtual});

  // ==========================================
  @override
  State<AssociatesDetails> createState() => AssociatesDetailsState();
}

class AssociatesDetailsState extends State<AssociatesDetails> {
  final bdJourneyRidingController =
      getItBdJourneyRidingController<BdJourneyRidingController>();

  final generalService = getItGeneralService<GeneralService>();

  final idController = TextEditingController();
  final hldController = TextEditingController();
  final fullNameController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  final ValueNotifier<bool> isObscurePassword1 = ValueNotifier<bool>(true);
  final ValueNotifier<bool> isObscurePassword2 = ValueNotifier<bool>(true);

  // ==========================================
  @override
  void initState() {
    idController.text = widget.itemAtual.pfl_id.toString();
    fullNameController.text = widget.itemAtual.pfl_full_name.toString();
    hldController.text = widget.itemAtual.hld_name.toString();

    super.initState();
  }

  // ==========================================
  @override
  Widget build(BuildContext context) {
    const double distance = 16.0;

    return Scaffold(
      appBar: CustomFloatingAppBar(title: fullNameController.text),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. TOP FIXO (ID e Holding)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: idController,
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: 'ID:',
                            prefixIcon: Icon(Icons.key),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: distance),
                      Expanded(
                        child: TextFormField(
                          controller: hldController,
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: 'Holding:',
                            prefixIcon: Icon(Icons.verified_user),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: distance),

                  // 2. MEIO ROLÁVEL (Apenas as tabelas rolam)
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: distance),
                          journeyRidingTable(),
                          const SizedBox(height: distance),
                          associateStatusTable(),
                          const SizedBox(height: distance),
                          sanctionTable(),
                          const SizedBox(height: distance),
                          executiveCommitteeTable(),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: distance),

                  // 3. RODAPÉ FIXO (Botão Cancelar)
                  OutlinedButton.icon(
                    onPressed: context.pop,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Cancelar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  Widget journeyRidingTable() {
  return InputDecorator(
    decoration: const InputDecoration(
      labelText: 'Journey of the Riding',
      // prefixIcon: Icon(Icons.stars),
      border: OutlineInputBorder(),
      contentPadding: EdgeInsets.all(12),
    ),
    child: ValueListenableBuilder<List<VprofileJourneyridingMode>?>(
      valueListenable:
          bdJourneyRidingController.vProfileJourneyridingDetaisNotifier,
      builder: (context, historyList, child) {
        final bool temItens = historyList != null && historyList.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. ÁREA DOS CARDS / LISTA
            if (!temItens)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  'Nenhum registro encontrado.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: historyList.map((item) {
                        final String nome = item.jr_nome?.toString() ?? '-';
                        final String nivel = item.jr_level?.toString() ?? '-';
                        final String data = generalService.formatarDataBr(
                          item.uj_promotion_date.toString(),
                        );

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
                                // Informações do Nível
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nome,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Nível: $nivel - Data: $data',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // 2. BOTÃO DE EDITAR NO LADO DIREITO
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.orange,
                                  ),
                                  tooltip: 'Editar',
                                  onPressed: () {
                                    // Adicione a ação de editar este 'item'
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 4),

            // 3. BOTÃO DE ADICIONAR NO CANTO INFERIOR DIREITO
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  // Adicione a ação de criar um novo nível
                },
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text('Adicionar Nível'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
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
  Widget associateStatusTable() {
  return InputDecorator(
    decoration: const InputDecoration(
      labelText: 'Associate Status',
      // prefixIcon: Icon(Icons.stars),
      border: OutlineInputBorder(),
      contentPadding: EdgeInsets.all(12),
    ),
    child: ValueListenableBuilder<List<VprofileJourneyridingMode>?>(
      valueListenable:
          bdJourneyRidingController.vProfileJourneyridingDetaisNotifier,
      builder: (context, historyList, child) {
        final bool temItens = historyList != null && historyList.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. ÁREA DOS CARDS / LISTA
            if (!temItens)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  'Nenhum registro encontrado.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: historyList.map((item) {
                        final String nome = item.jr_nome?.toString() ?? '-';
                        final String nivel = item.jr_level?.toString() ?? '-';
                        final String data = generalService.formatarDataBr(
                          item.uj_promotion_date.toString(),
                        );

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
                                // Informações do Nível
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nome,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Nível: $nivel - Data: $data',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // 2. BOTÃO DE EDITAR NO LADO DIREITO
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.orange,
                                  ),
                                  tooltip: 'Editar',
                                  onPressed: () {
                                    // Adicione a ação de editar este 'item'
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 4),

            // 3. BOTÃO DE ADICIONAR NO CANTO INFERIOR DIREITO
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  // Adicione a ação de criar um novo nível
                },
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text('Adicionar Nível'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
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
  Widget sanctionTable() {
  return InputDecorator(
    decoration: const InputDecoration(
      labelText: 'Sanctions',
      // prefixIcon: Icon(Icons.stars),
      border: OutlineInputBorder(),
      contentPadding: EdgeInsets.all(12),
    ),
    child: ValueListenableBuilder<List<VprofileJourneyridingMode>?>(
      valueListenable:
          bdJourneyRidingController.vProfileJourneyridingDetaisNotifier,
      builder: (context, historyList, child) {
        final bool temItens = historyList != null && historyList.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. ÁREA DOS CARDS / LISTA
            if (!temItens)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  'Nenhum registro encontrado.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: historyList.map((item) {
                        final String nome = item.jr_nome?.toString() ?? '-';
                        final String nivel = item.jr_level?.toString() ?? '-';
                        final String data = generalService.formatarDataBr(
                          item.uj_promotion_date.toString(),
                        );

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
                                // Informações do Nível
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nome,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Nível: $nivel - Data: $data',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // 2. BOTÃO DE EDITAR NO LADO DIREITO
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.orange,
                                  ),
                                  tooltip: 'Editar',
                                  onPressed: () {
                                    // Adicione a ação de editar este 'item'
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 4),

            // 3. BOTÃO DE ADICIONAR NO CANTO INFERIOR DIREITO
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  // Adicione a ação de criar um novo nível
                },
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text('Adicionar Nível'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
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
  Widget executiveCommitteeTable() {
  return InputDecorator(
    decoration: const InputDecoration(
      labelText: 'Executive Commitee',
      // prefixIcon: Icon(Icons.stars),
      border: OutlineInputBorder(),
      contentPadding: EdgeInsets.all(12),
    ),
    child: ValueListenableBuilder<List<VprofileJourneyridingMode>?>(
      valueListenable:
          bdJourneyRidingController.vProfileJourneyridingDetaisNotifier,
      builder: (context, historyList, child) {
        final bool temItens = historyList != null && historyList.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. ÁREA DOS CARDS / LISTA
            if (!temItens)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  'Nenhum registro encontrado.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: historyList.map((item) {
                        final String nome = item.jr_nome?.toString() ?? '-';
                        final String nivel = item.jr_level?.toString() ?? '-';
                        final String data = generalService.formatarDataBr(
                          item.uj_promotion_date.toString(),
                        );

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
                                // Informações do Nível
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nome,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Nível: $nivel - Data: $data',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // 2. BOTÃO DE EDITAR NO LADO DIREITO
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.orange,
                                  ),
                                  tooltip: 'Editar',
                                  onPressed: () {
                                    // Adicione a ação de editar este 'item'
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 4),

            // 3. BOTÃO DE ADICIONAR NO CANTO INFERIOR DIREITO
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  // Adicione a ação de criar um novo nível
                },
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text('Adicionar Nível'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
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

}
