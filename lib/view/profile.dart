import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gorouter_exemplo/controllers/bd_profile_controller.dart';
import 'package:gorouter_exemplo/models/profile_model.dart';
import 'package:gorouter_exemplo/models/custom_app_bar.dart';
import 'package:gorouter_exemplo/view/profile_update_password.dart';

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

  bool isUpdate = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void onFieldChanged() {
    if ((fullNameController.text ==
            bdProfileController.pessoaSelecionadaNotifier.value?.full_name) &&
        (nickNameController.text ==
            bdProfileController.pessoaSelecionadaNotifier.value?.nickname) &&
        (urlController.text ==
            bdProfileController.pessoaSelecionadaNotifier.value?.avatar_url) &&
        (bioController.text ==
            bdProfileController.pessoaSelecionadaNotifier.value?.bio)) {
      bdProfileController.changedNotifier(false);
    } else {
      bdProfileController.changedNotifier(true);
    }
  }

  void initValues() {
    idController.text =
        bdProfileController.pessoaSelecionadaNotifier.value?.id ?? "";
    fullNameController.text =
        bdProfileController.pessoaSelecionadaNotifier.value?.full_name ?? "";
    nickNameController.text =
        bdProfileController.pessoaSelecionadaNotifier.value?.nickname ?? "";
    urlController.text =
        bdProfileController.pessoaSelecionadaNotifier.value?.avatar_url ?? "";
    bioController.text =
        bdProfileController.pessoaSelecionadaNotifier.value?.bio ?? "";
    updatedAtController.text =
        bdProfileController.pessoaSelecionadaNotifier.value?.updated_at ?? "";

    bdProfileController.changedNotifier(false);
  }

  void updateProfile() async {
    isUpdate = true;

    try {
      await bdProfileController.updateProfile(
        idController.text,
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
      await bdProfileController.fetchProfilesById(idController.text);
      isUpdate = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomFloatingAppBar(title: 'Detalhes do ID '),

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

              return ValueListenableBuilder<ProfileModel?>(
                valueListenable: bdProfileController.pessoaSelecionadaNotifier,
                builder: (context, profile, child) {
                  if (profile == null) {
                    return const Center(child: Text('Nenhum dado encontrado.'));
                  }
                  initValues();

                  const double distance = 12;

                  return Padding(
                    // padding: const EdgeInsets.all(16.0),
                    padding: const EdgeInsets.only(
                      left: 8.0,
                      right: 8.0,
                      top: 16.0,
                      bottom: 16.0,
                    ),
                    // child: Center(
                    child: SizedBox.expand(
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: idController,
                                enabled: false,
                                decoration: const InputDecoration(
                                  labelText: 'ID: ',
                                  prefixIcon: Icon(Icons.key),
                                  border: OutlineInputBorder(),
                                ),
                              ),

                              const SizedBox(height: distance),
                              TextFormField(
                                controller: updatedAtController,
                                enabled: false,
                                decoration: const InputDecoration(
                                  labelText: 'Updated at:',
                                  prefixIcon: Icon(Icons.punch_clock),
                                  border: OutlineInputBorder(),
                                ),
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
                                    return 'Por favor, informe um username.';
                                  }
                                  if (value.contains(' ')) {
                                    return 'O username não pode conter espaços.';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: distance),
                              TextFormField(
                                controller: nickNameController,
                                onChanged: (_) => onFieldChanged(),
                                decoration: const InputDecoration(
                                  labelText: 'Nick name:',
                                  prefixIcon: Icon(Icons.verified_user),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Por favor, informe um username.';
                                  }
                                  if (value.contains(' ')) {
                                    return 'O username não pode conter espaços.';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: distance),
                              GestureDetector(
                                onTap: () {
                                  bdProfileController.selecionarEEnviarFoto();
                                },
                                child: TextFormField(
                                  controller: urlController,
                                  enabled: false,
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Avatar URL (click to load...):',
                                    prefixIcon: Icon(Icons.photo_album_sharp),
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),

                              const SizedBox(height: distance),
                              TextFormField(
                                controller: bioController,
                                onChanged: (_) => onFieldChanged(),
                                decoration: const InputDecoration(
                                  labelText: 'BIO:',
                                  prefixIcon: Icon(Icons.biotech),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Por favor, informe um username.';
                                  }
                                  if (value.contains(' ')) {
                                    return 'O username não pode conter espaços.';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: distance),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      // onPressed: () =>
                                      //     dialogUpdatePassword(context),

                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ProfileUpdatePassword(),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Update Password'),
                                      style: OutlinedButton.styleFrom(
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

                              const SizedBox(height: distance),

                              ValueListenableBuilder<bool>(
                                valueListenable:
                                    bdProfileController.loadingNotifier,
                                builder: (context, isLoading, child) {
                                  return ValueListenableBuilder<bool>(
                                    valueListenable:
                                        bdProfileController.isChangedNotifier,
                                    builder: (context, isChanged, child) {
                                      final canSubmit = isChanged && !isLoading;

                                      return Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: canSubmit
                                                  ? initValues
                                                  : null,
                                              icon: const Icon(Icons.refresh),
                                              label: const Text('Cancelar'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.indigo,
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
                                                          ),
                                                    )
                                                  : const Icon(Icons.save),
                                              label: Text(
                                                isLoading
                                                    ? 'Salvando...'
                                                    : 'Salvar',
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.indigo,
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
                                  );
                                },
                              ),
                            ],
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
      ),
    );
  }
}
