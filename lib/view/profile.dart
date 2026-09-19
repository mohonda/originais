import 'package:flutter/material.dart';
import 'package:originais/controllers/profile_controller.dart';
import 'package:originais/models/vprofile_model.dart';
import 'package:originais/models/custom_app_bar.dart';
import 'package:originais/view/profile_update_password.dart';
import 'package:originais/controllers/profile_image_service.dart';
import 'package:originais/view/profile_headquarters_bar.dart'; 
import 'package:originais/view/profile_executive_committee.dart'; 
import 'package:originais/view/profile_sanctions.dart'; 
import 'package:originais/view/profile_journey_riding.dart'; 
import 'package:originais/view/profile_associate_status.dart'; 

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

  final paymentService = ProfileImageService();

  // ==========================================
  @override
  void initState() {
    super.initState();

    bdProfileController.pessoaSelecionadaNotifier
      .addListener(_onProfileChanged);
    _onProfileChanged();
  }

  // ==========================================
  @override
  void dispose() {
    bdProfileController.pessoaSelecionadaNotifier.removeListener(_onProfileChanged);
    idController.dispose();
    fullNameController.dispose();
    nickNameController.dispose();
    urlController.dispose();
    bioController.dispose();
    updatedAtController.dispose();
    super.dispose();
  }

  // ==========================================
  void _onProfileChanged() {
    final profile = bdProfileController.pessoaSelecionadaNotifier.value;
    if (profile != null) {
      idController.text = profile.pfl_id;
      hld_id = profile.hld_id;
      fullNameController.text = profile.pfl_full_name;
      nickNameController.text = profile.pfl_nick_name;
      urlController.text = profile.pfl_avatar_url;
      bioController.text = profile.pfl_bio;
      updatedAtController.text = profile.pfl_updated_at;
      bdProfileController.changedNotifier(false);
    }
  }

  // ==========================================
  void onFieldChanged() {
    final currentProfile = bdProfileController.pessoaSelecionadaNotifier.value;
    if (currentProfile == null) return;

    final isSame = (fullNameController.text == (currentProfile.pfl_full_name)) &&
        (nickNameController.text == (currentProfile.pfl_nick_name)) &&
        (urlController.text == (currentProfile.pfl_avatar_url)) &&
        (bioController.text == (currentProfile.pfl_bio));

    bdProfileController.changedNotifier(!isSame);
  }

  // ==========================================
  Future<void> updateProfile() async {
    bdProfileController.errorNotifier.value = null;

    try {
      await bdProfileController.updateProfile(
        idController.text,
        hld_id,
        fullNameController.text,
        nickNameController.text,
        urlController.text,
        bioController.text,
      );

      await bdProfileController.fetchProfilesById(idController.text, hld_id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dados atualizados com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(bdProfileController.errorNotifier.value ?? 'Erro ao atualizar os dados!'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildTabSection({
    required String labelText,
    required Widget child,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double extraVerticalSpace = 24.0;
        final double minHeight = constraints.maxHeight - extraVerticalSpace;
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
          ),
        );
      },
    );
  }

  // ==========================================
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: ValueListenableBuilder<VProfileModel?>(
            valueListenable: bdProfileController.pessoaSelecionadaNotifier,
            builder: (context, value, child) {
              return CustomFloatingAppBar(
                title: 'Profile - ${value?.pfl_full_name ?? ''}',
              );
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          child: Card(
            elevation: 4,
            surfaceTintColor: Colors.transparent,
            color: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                      fontWeight: FontWeight.w100,
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
                        icon: Icon(Icons.currency_exchange, size: 16),
                        text: 'Financial',
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
                     
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildTabSection(
                          labelText: 'Profile Information',
                          child: _buildProfileForm(),
                        ),
                        _buildTabSection(
                          labelText: 'Financial',
                          child: ProfileHeadquartersBar(
                            pflId: idController.text,
                            hldId: hld_id,
                          ),
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
                        _buildTabSection(
                          labelText: 'Executive Committee',
                          child: ProfileExecutiveCommittee(),
                        ),
                        _buildTabSection(
                          labelText: 'Sanctions',
                          child: ProfileSanctions(),
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

  // ==========================================
  Widget _buildProfileForm() {
    return ValueListenableBuilder<bool>(
      valueListenable: bdProfileController.loadingNotifier,
      builder: (context, isLoading, child) {
        if (isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        return ValueListenableBuilder<String?>(
          valueListenable: bdProfileController.errorNotifier,
          builder: (context, errorMessage, child) {
            if (errorMessage != null && errorMessage.isNotEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ValueListenableBuilder<VProfileModel?>(
              valueListenable: bdProfileController.pessoaSelecionadaNotifier,
              builder: (context, profile, child) {
                if (profile == null) {
                  return const Center(child: Text('Nenhum dado encontrado.'));
                }

                const double distance = 12.0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(
                                          Icons.broken_image,
                                          size: 48,
                                        ),
                                      ),
                                    )
                                  : const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
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
                                          const ProfileUpdatePassword(),
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
                                icon: const Icon(Icons.save),
                                label: const Text('Salvar'),
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