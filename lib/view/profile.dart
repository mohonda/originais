import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:originais/controllers/bd_profile_controller.dart';
import 'package:originais/models/vprofile_model.dart';
import 'package:originais/models/custom_app_bar.dart';
import 'package:originais/view/profile_update_password.dart';
import 'package:originais/controllers/ProfileImageService.dart';
import 'package:originais/view/ProfileMonthlyPayment.dart';
import 'package:originais/view/ProfileHeadquartersBar.dart'; 
import 'package:originais/view/profileExecutiveCommittee.dart'; 
import 'package:originais/view/profileSanctions.dart'; 
import 'package:originais/view/profileJourneyRiding.dart'; 
import 'package:originais/view/profileAssociateStatus.dart'; 

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final bdProfileController = getItBdProfileController<BdProfileController>();

  final idController = TextEditingController();
  final fullNameController = TextEditingController();
  final nickNameController = TextEditingController();
  final urlController = TextEditingController();
  final bioController = TextEditingController();
  final updatedAtController = TextEditingController();
  String hld_id = '';

  bool isUpdate = false;

  final paymentService = ProfileImageService();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    idController.dispose();
    fullNameController.dispose();
    nickNameController.dispose();
    urlController.dispose();
    bioController.dispose();
    updatedAtController.dispose();
    super.dispose();
  }

  void onFieldChanged() {
    if ((fullNameController.text ==
            bdProfileController
                .pessoaSelecionadaNotifier
                .value
                ?.pfl_full_name) &&
        (nickNameController.text ==
            bdProfileController
                .pessoaSelecionadaNotifier
                .value
                ?.pfl_nick_name) &&
        (urlController.text ==
            bdProfileController
                .pessoaSelecionadaNotifier
                .value
                ?.pfl_avatar_url) &&
        (bioController.text ==
            bdProfileController.pessoaSelecionadaNotifier.value?.pfl_bio)) {
      bdProfileController.changedNotifier(false);
    } else {
      bdProfileController.changedNotifier(true);
    }
  }

  void initValues() {
    idController.text =
        bdProfileController.pessoaSelecionadaNotifier.value?.pfl_id ?? "";
    hld_id = bdProfileController.pessoaSelecionadaNotifier.value?.hld_id ?? '';
    fullNameController.text =
        bdProfileController.pessoaSelecionadaNotifier.value?.pfl_full_name ??
        "";
    nickNameController.text =
        bdProfileController.pessoaSelecionadaNotifier.value?.pfl_nick_name ??
        "";
    urlController.text =
        bdProfileController.pessoaSelecionadaNotifier.value?.pfl_avatar_url ??
        "";
    bioController.text =
        bdProfileController.pessoaSelecionadaNotifier.value?.pfl_bio ?? "";
    updatedAtController.text =
        bdProfileController.pessoaSelecionadaNotifier.value?.pfl_updated_at ??
        "";

    bdProfileController.changedNotifier(false);
  }

  void updateProfile() async {
    isUpdate = true;

    try {
      await bdProfileController.updateProfile(
        idController.text,
        hld_id,
        fullNameController.text,
        nickNameController.text,
        urlController.text,
        bioController.text,
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
        context.pop();
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
        context.pop();
      }
      await bdProfileController.fetchProfilesById(idController.text, hld_id);
      isUpdate = false;
    }
  }

  // 🟢 Helper com a cor de fundo perfeitamente idêntica à superfície do Card
  Widget _buildTabSection({
    required String labelText,
    required Widget child,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double extraVerticalSpace = 24.0;
        final double minHeight = constraints.maxHeight - extraVerticalSpace;

        // Cor exata da superfície do tema (casada com o Card)
        final cardBgColor = Theme.of(context).colorScheme.surface;
        final labelTextColor = Theme.of(context).colorScheme.onSurface;

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    minHeight: minHeight > 0 ? minHeight : 0,
                  ),
                  margin: const EdgeInsets.only(top: 8.0),
                  padding: const EdgeInsets.fromLTRB(12.0, 16.0, 12.0, 12.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: child,
                ),
                Positioned(
                  left: 12.0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    color: cardBgColor, // 🟢 Fundo idêntico sem efeito de caixa
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
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 7,
      child: Scaffold(
        appBar: CustomFloatingAppBar(
          title: 'Profile - ${fullNameController.text}',
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          child: Card(
            elevation: 4,
            surfaceTintColor: Colors.transparent, // 🟢 Desativa a tinta M3 que alterava a cor do Card
            color: Theme.of(context).colorScheme.surface, // 🟢 Garante sincronia total de cor
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
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
                      fontWeight: FontWeight.normal,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal
                    ),
                    tabs: [
                      Tab(
                        height: 38,
                        icon: Icon(Icons.person, size: 16),
                        text: 'Profile',
                        iconMargin: EdgeInsets.only(bottom: 2),
                      ),
                      Tab(
                        height: 38,
                        icon: Icon(Icons.calendar_month, size: 16),
                        text: 'Monthly',
                        iconMargin: EdgeInsets.only(bottom: 2),
                      ),
                      Tab(
                        height: 38,
                        icon: Icon(Icons.sports_bar, size: 16),
                        text: 'Bar',
                        iconMargin: EdgeInsets.only(bottom: 2),
                      ),
                      Tab(
                        height: 38,
                        icon: Icon(Icons.manage_accounts, size: 16),
                        text: 'Exec. Committee',
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
                        icon: Icon(Icons.motorcycle_sharp, size: 16),
                        text: 'Journey Riding',
                        iconMargin: EdgeInsets.only(bottom: 2),
                      ),
                      Tab(
                        height: 38,
                        icon: Icon(Icons.badge_outlined, size: 16),
                        text: 'Associate Status',
                        iconMargin: EdgeInsets.only(bottom: 2),
                      ),
                    ],
                  ),

                  // 2. CONTEÚDO DAS ABAS
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildTabSection(
                          labelText: 'Profile Information',
                          child: _buildProfileForm(),
                        ),
                        _buildTabSection(
                          labelText: 'Monthly Payments',
                          child: const ProfileMonthlyPayment(),
                        ),
                        _buildTabSection(
                          labelText: 'Headquarters Bar',
                          child: ProfileHeadquartersBar(
                            pflId: idController.text,
                            hldId: hld_id,
                          ),
                        ),
                        _buildTabSection(
                          labelText: 'Executive Committee',
                          child: ProfileExecutiveCommittee(),
                        ),
                        _buildTabSection(
                          labelText: 'Sanctions',
                          child: ProfileSanctions(),
                        ),
                        _buildTabSection(
                          labelText: 'Journey of the Riding',
                          child: ProfileJourneyRiding(
                            pflId: idController.text,
                            hldId: hld_id,
                          ),
                        ),
                        _buildTabSection(
                          labelText: 'Associate Status',
                          child: ProfileAssociateStatus(),
                        ),
                      ],
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

  // Form de Profile
  Widget _buildProfileForm() {
    return ValueListenableBuilder<bool>(
      valueListenable: bdProfileController.loadingNotifier,
      builder: (context, isLoading, child) {
        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return ValueListenableBuilder<String?>(
          valueListenable: bdProfileController.errorNotifier,
          builder: (context, errorMessage, child) {
            if (errorMessage != null) {
              return Center(
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              );
            }

            return ValueListenableBuilder<VProfileModel?>(
              valueListenable: bdProfileController.pessoaSelecionadaNotifier,
              builder: (context, profile, child) {
                if (profile == null) {
                  return const Center(child: Text('Nenhum dado encontrado.'));
                }
                initValues();

                const double distance = 12.0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LINHA 1: ID e Updated At
                    Row(
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
                            controller: updatedAtController,
                            enabled: false,
                            decoration: const InputDecoration(
                              labelText: 'Updated at:',
                              prefixIcon: Icon(Icons.punch_clock),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: distance),

                    // LINHA 2: Nome
                    TextFormField(
                      controller: fullNameController,
                      onChanged: (_) => onFieldChanged(),
                      decoration: const InputDecoration(
                        labelText: 'Name:',
                        prefixIcon: Icon(Icons.verified_user),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, informe o nome.';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: distance),

                    // LINHA 3: Form Esquerda + Avatar Direita
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: nickNameController,
                                onChanged: (_) => onFieldChanged(),
                                decoration: const InputDecoration(
                                  labelText: 'Nick name:',
                                  prefixIcon: Icon(Icons.verified_user),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: distance),
                              TextFormField(
                                controller: bioController,
                                onChanged: (_) => onFieldChanged(),
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'BIO:',
                                  prefixIcon: Icon(Icons.biotech),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: distance),
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () async {
                              await paymentService.selecionarAnexoEEnviar(
                                context: context,
                                payload: {
                                  'pfl_id': idController.text,
                                  'hld_id': hld_id,
                                },
                                isDocumentoOuComprovanteLocal: false,
                              );
                            },
                            child: Container(
                              height: 155,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              child: urlController.text.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        urlController.text,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                                  Icons.broken_image,
                                                  size: 48,
                                                ),
                                      ),
                                    )
                                  : const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_a_photo,
                                          size: 40,
                                          color: Colors.black54,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Toque para\nalterar foto',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: distance * 2),

                    // Botões de Ação
                    ValueListenableBuilder<bool>(
                      valueListenable: bdProfileController.isChangedNotifier,
                      builder: (context, isChanged, child) {
                        final canSubmit = isChanged && !isLoading;

                        return Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ProfileUpdatePassword(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.lock_reset),
                                label: const Text('Update Password'),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
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
                                onPressed: canSubmit ? updateProfile : null,
                                icon: isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.save),
                                label: Text(
                                  isLoading ? 'Salvando...' : 'Salvar',
                                ),
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
                        );
                      },
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
}