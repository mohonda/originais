import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:originais/controllers/bd_profile_controller.dart';
import 'package:originais/models/vprofile_model.dart';
import 'package:originais/models/custom_app_bar.dart';
import 'package:originais/services/general_service.dart';
import 'package:originais/view/journey_riding.dart';
import 'package:originais/view/profile_update_password.dart';
import 'package:originais/controllers/ProfileImageService.dart';
// 🟢 Importe suas telas correspondentes aqui:
import 'package:originais/view/headquartersbar.dart';
import 'package:originais/view/ProfileMonthlyPayment.dart'; // Exemplo para a aba Monthly
import 'package:originais/view/ProfileHeadquartersBar.dart'; 
import 'package:originais/controllers/ticketController.dart';
import 'package:originais/models/ticketModel.dart';
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

  // 🟢 Controle da Aba Selecionada
  String _selectedTab = 'Profile';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomFloatingAppBar(
        title: 'Profile - ${fullNameController.text}',
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),

          // 🟢 1. TABS / SEGMENTED BUTTON NO TOPO
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  padding: WidgetStatePropertyAll(
                    EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  ),
                ),
                selected: {_selectedTab},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _selectedTab = newSelection.first;
                  });
                },
                segments: const [
                  ButtonSegment(
                    value: 'Profile',
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person),
                        SizedBox(height: 2),
                        Text('Profile', style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                  ButtonSegment(
                    value: 'Monthly',
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_month),
                        SizedBox(height: 2),
                        Text('Monthly', style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                  ButtonSegment(
                    value: 'Headquarters Bar',
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sports_bar),
                        SizedBox(height: 2),
                        Text('Bar', style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                  ButtonSegment(
                    value: 'Executive Committee',
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.manage_accounts),
                        SizedBox(height: 2),
                        Text('Exec. Committee', style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                  ButtonSegment(
                    value: 'Sanctions',
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.gavel),
                        SizedBox(height: 2),
                        Text('Sanctions', style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                  ButtonSegment(
                    value: 'Journey of the Riding',
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.motorcycle_sharp),
                        SizedBox(height: 2),
                        Text('Journey Riding', style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                  ButtonSegment(
                    value: 'Associate Status',
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.link),
                        SizedBox(height: 2),
                        Text('Associate Status', style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 🟢 2. CONTEÚDO DINÂMICO BASEADO NA ABA SELECIONADA
          Expanded(
            child: _buildBodyContent(),
          ),
        ],
      ),
    );
  }

  // 🟢 Alterna o conteúdo da tela conforme a aba selecionada
  Widget _buildBodyContent() {
    switch (_selectedTab) {
      case 'Monthly':
        // Substitua pelo Widget/Tela da Mensalidade do Usuário
        return const ProfileMonthlyPayment();

      case 'Headquarters Bar':
        return ProfileHeadquartersBar(
          pflId: idController.text,
          hldId: hld_id,
        );
      
      case 'Executive Committee':
        return ProfileExecutiveCommittee();

      case 'Sanctions':
        return ProfileSanctions();
      
      case 'Journey of the Riding':
        return ProfileJourneyRiding(pflId: idController.text, hldId: hld_id);
      
      case 'Associate Status':
        return ProfileAssociateStatus();

      case 'Profile':
      default:
        return _buildProfileForm();
    }
  }

  // 🟢 Formulário do Profile
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

                return LayoutBuilder(
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
                              child: Column(
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
                                                      errorBuilder: (context, error, stackTrace) =>
                                                          const Icon(Icons.broken_image, size: 48),
                                                    ),
                                                  )
                                                : const Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(Icons.add_a_photo, size: 40, color: Colors.black54),
                                                      SizedBox(height: 8),
                                                      Text(
                                                        'Toque para\nalterar foto',
                                                        textAlign: TextAlign.center,
                                                        style: TextStyle(fontSize: 12, color: Colors.black54),
                                                      ),
                                                    ],
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const Spacer(),
                                  const SizedBox(height: distance),

                                  // Botões
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
                                                    builder: (context) => ProfileUpdatePassword(),
                                                  ),
                                                );
                                              },
                                              icon: const Icon(Icons.lock_reset),
                                              label: const Text('Update Password'),
                                              style: OutlinedButton.styleFrom(
                                                backgroundColor: Colors.redAccent,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(vertical: 16),
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
                                              label: Text(isLoading ? 'Salvando...' : 'Salvar'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.indigo,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(vertical: 16),
                                              ),
                                            ),
                                          ),
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
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}