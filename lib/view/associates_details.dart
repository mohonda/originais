import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:originais/models/vprofile_model.dart';
import 'package:originais/services/general_service.dart';
import 'package:originais/models/custom_app_bar.dart';
import 'package:originais/controllers/bd_vprofile_associatestatus_controller.dart';
import 'package:originais/controllers/bd_vprofiles_sanctions_controller.dart';
import 'package:originais/controllers/bd_vexecutive_committee_termofoffice_members_controller.dart';
import 'package:originais/view/associatesExecutiveCommitteeSection.dart';
import 'package:originais/view/associatesAssociateStatusSection.dart';
import 'package:originais/view/associatesSanctionsSection.dart';
import 'package:originais/view/associatesJourneyRidingSection.dart';

class AssociatesDetails extends StatefulWidget {
  final VProfileModel itemAtual;

  const AssociatesDetails({super.key, required this.itemAtual});

  @override
  State<AssociatesDetails> createState() => AssociatesDetailsState();
}

class AssociatesDetailsState extends State<AssociatesDetails> {
  final bdVProfileAssociateStatusController =
      getItBdVProfileAssociateStatusController<
        BdVProfileAssociateStatusController
      >();

  final bdVProfilesSanctionsController =
      getItBdVProfilesSanctionsController<BdVProfilesSanctionsController>();

  final bdVExecutiveCommitteeTermOfOfficeMembersController =
      getItBdVExecutiveCommitteeTermOfOfficeMembersController<
        BdVExecutiveCommitteeTermOfOfficeMembersController
      >();

  final generalService = getItGeneralService<GeneralService>();

  final idController = TextEditingController();
  final hldController = TextEditingController();
  final fullNameController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    idController.text = widget.itemAtual.pfl_id.toString();
    fullNameController.text = widget.itemAtual.pfl_full_name.toString();
    hldController.text = widget.itemAtual.hld_name.toString();
  }

  @override
  void dispose() {
    idController.dispose();
    hldController.dispose();
    fullNameController.dispose();
    super.dispose();
  }

  // 🟢 Helper otimizado: Borda fixa, scroll restrito ao conteúdo interno
  Widget _buildTabSection({
    required String labelText,
    required Widget child,
  }) {
    final cardBgColor = Theme.of(context).colorScheme.surface;
    final labelTextColor = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: 8.0,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5.0),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12.0, 16.0, 12.0, 12.0),
                  child: child,
                ),
              ),
            ),
          ),
          Positioned(
            left: 12.0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              color: cardBgColor,
              child: Text(
                labelText,
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w100,
                  color: labelTextColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: CustomFloatingAppBar(
          title: 'Associates - ${fullNameController.text}',
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          child: Card(
            elevation: 4,
            surfaceTintColor: Colors.transparent, // 🟢 Desativa a tinta M3
            color: Theme.of(context).colorScheme.surface, // 🟢 Sincronia total de cor
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. NAVEGAÇÃO EM ABAS
                    const TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      padding: EdgeInsets.zero, 
                      labelPadding: EdgeInsets.symmetric(horizontal: 6.0),
                      indicatorPadding: EdgeInsets.zero,
                      dividerColor: Colors.transparent,
                      indicatorColor: Colors.indigo,
                      labelColor: Colors.indigo,
                      unselectedLabelColor: Colors.grey,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w100,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w100
                      ),
                      tabs: [
                        Tab(
                          height: 38,
                          icon: Icon(Icons.explore_outlined, size: 16),
                          text: 'Journey of the Riding',
                          iconMargin: EdgeInsets.only(bottom: 2),
                        ),
                        Tab(
                          height: 38,
                          icon: Icon(Icons.badge_outlined, size: 16),
                          text: 'Status',
                          iconMargin: EdgeInsets.only(bottom: 2),
                        ),
                        Tab(
                          height: 38,
                          icon: Icon(Icons.gavel_outlined, size: 16),
                          text: 'Sanctions',
                          iconMargin: EdgeInsets.only(bottom: 2),
                        ),
                        Tab(
                          height: 38,
                          icon: Icon(Icons.groups_outlined, size: 16),
                          text: 'Executive Committee',
                          iconMargin: EdgeInsets.only(bottom: 2),
                        ),
                      ],
                    ),

                    // 2. CONTEÚDO DAS ABAS
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildTabSection(
                            labelText: 'Journey of the Riding',
                            child: AssociatesJourneyRidingSection(
                              itemAtual: widget.itemAtual,
                            ),
                          ),
                          _buildTabSection(
                            labelText: 'Associate Status',
                            child: AssociatesAssociateStatusSection(
                              itemAtual: widget.itemAtual,
                            ),
                          ),
                          _buildTabSection(
                            labelText: 'Sanctions',
                            child: AssociatesSanctionsSection(
                              itemAtual: widget.itemAtual,
                            ),
                          ),
                          _buildTabSection(
                            labelText: 'Executive Committee',
                            child: AssociatesExecutiveCommitteeSection(
                              itemAtual: widget.itemAtual,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 24),

                    // 3. RODAPÉ FIXO (Informações de ID/Holding + Botão)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final bool isSmallScreen = constraints.maxWidth < 480;

                        final chipsWidget = Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Chip(
                              avatar: const Icon(
                                Icons.key,
                                size: 14,
                                color: Colors.indigo,
                              ),
                              label: Text(
                                'ID: ${idController.text}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              backgroundColor: Colors.indigo.withValues(
                                alpha: 0.08,
                              ),
                              side: BorderSide.none,
                            ),
                            Chip(
                              avatar: const Icon(
                                Icons.verified_user,
                                size: 14,
                                color: Colors.indigo,
                              ),
                              label: Text(
                                hldController.text,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              backgroundColor: Colors.indigo.withValues(
                                alpha: 0.08,
                              ),
                              side: BorderSide.none,
                            ),
                          ],
                        );

                        final buttonWidget = ElevatedButton.icon(
                          onPressed: context.pop,
                          icon: const Icon(Icons.arrow_back, size: 18),
                          label: const Text('Voltar / Sair'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );

                        if (isSmallScreen) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              chipsWidget,
                              const SizedBox(height: 12),
                              buttonWidget,
                            ],
                          );
                        }

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: chipsWidget),
                            const SizedBox(width: 12),
                            buttonWidget,
                          ],
                        );
                      },
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
}