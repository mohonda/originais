import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:originais/controllers/bd_profile_controller.dart';
import 'package:originais/models/vprofile_model.dart';
import 'package:originais/models/custom_app_bar.dart';
import 'package:originais/view/profile_update_password.dart';
import 'package:originais/controllers/ProfileImageService.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  // ==========================================
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

  // ==========================================
  @override
  void initState() {
    super.initState();
  }

  // ==========================================
  @override
  void dispose() {
    super.dispose();
  }

  // ==========================================
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

  // ==========================================
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

  // ==========================================
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
      await bdProfileController.fetchProfilesById( idController.text, hld_id );
      isUpdate = false;
    }
  }

  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomFloatingAppBar(
        title: 'Profile - ${fullNameController.text.toString()}',
      ),
      body: ValueListenableBuilder<bool>(
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
                            // Desconta o padding externo de 16 (topo + base = 32)
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
                                              prefixIcon: Icon(
                                                Icons.punch_clock,
                                              ),
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
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Por favor, informe o nome.';
                                        }
                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: distance),

                                    // LINHA 3: Form Esquerda + Avatar Direita
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Column(
                                            children: [
                                              TextFormField(
                                                controller: nickNameController,
                                                onChanged: (_) =>
                                                    onFieldChanged(),
                                                decoration:
                                                    const InputDecoration(
                                                      labelText: 'Nick name:',
                                                      prefixIcon: Icon(
                                                        Icons.verified_user,
                                                      ),
                                                      border:
                                                          OutlineInputBorder(),
                                                    ),
                                              ),
                                              const SizedBox(height: distance),
                                              TextFormField(
                                                controller: bioController,
                                                onChanged: (_) =>
                                                    onFieldChanged(),
                                                maxLines: 3,
                                                decoration:
                                                    const InputDecoration(
                                                      labelText: 'BIO:',
                                                      prefixIcon: Icon(
                                                        Icons.biotech,
                                                      ),
                                                      border:
                                                          OutlineInputBorder(),
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
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.grey.shade400,
                                                ),
                                              ),
                                              child:
                                                  urlController.text.isNotEmpty
                                                  ? ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      child: Image.network(
                                                        urlController.text,
                                                        fit: BoxFit.contain,
                                                        errorBuilder:
                                                            (
                                                              context,
                                                              error,
                                                              stackTrace,
                                                            ) => const Icon(
                                                              Icons
                                                                  .broken_image,
                                                              size: 48,
                                                            ),
                                                      ),
                                                    )
                                                  : const Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Icons.add_a_photo,
                                                          size: 40,
                                                          color: Colors.black54,
                                                        ),
                                                        SizedBox(height: 8),
                                                        Text(
                                                          'Toque para\nalterar foto',
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color:
                                                                Colors.black54,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    // ---------------------------------------------------
                                    // EMPURRA OS ELEMENTOS ABAIXO PARA O FINAL DA TELA
                                    // ---------------------------------------------------
                                    const Spacer(),
                                    const SizedBox(height: distance),

                                    // Botões Cancelar e Salvar
                                    ValueListenableBuilder<bool>(
                                      valueListenable:
                                          bdProfileController.isChangedNotifier,
                                      builder: (context, isChanged, child) {
                                        final canSubmit =
                                            isChanged && !isLoading;

                                        return Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: canSubmit
                                                    ? initValues
                                                    : null,
                                                icon: const Icon(
                                                  Icons.arrow_back,
                                                ),
                                                label: const Text('Cancelar'),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor:
                                                      Colors.indigo,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 16,
                                                      ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: distance),
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
                                                icon: const Icon(
                                                  Icons.lock_reset,
                                                ),
                                                label: const Text(
                                                  'Update Password',
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.redAccent,
                                                  foregroundColor: Colors.white,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 16,
                                                      ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: distance),
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: canSubmit
                                                    ? updateProfile
                                                    : null,
                                                icon: isLoading
                                                    ? const SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                      )
                                                    : const Icon(Icons.save),
                                                label: Text(
                                                  isLoading
                                                      ? 'Salvando...'
                                                      : 'Salvar',
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.indigo,
                                                  foregroundColor: Colors.white,
                                                  padding:
                                                      const EdgeInsets.symmetric(
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
      ),
    );
  }

}
