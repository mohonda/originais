import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gorouter_exemplo/controllers/bd_profile_controller.dart';
import 'package:gorouter_exemplo/models/custom_app_bar.dart';
import 'package:gorouter_exemplo/controllers/auth_controller.dart';

class ProfileUpdatePassword extends StatefulWidget {
  const ProfileUpdatePassword({super.key});

  // ==========================================
  @override
  State<ProfileUpdatePassword> createState() => ProfileUpdatePasswordState();

}

class ProfileUpdatePasswordState extends State<ProfileUpdatePassword> {
  final bdProfileController = getItBdProfileController<BdProfileController>();

  final idController = TextEditingController();
  final fullNameController = TextEditingController();
  final password1 = TextEditingController();
  final password2 = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  final ValueNotifier<bool> isObscurePassword1 = ValueNotifier<bool>(true);
  final ValueNotifier<bool> isObscurePassword2 = ValueNotifier<bool>(true);

  // ==========================================
  @override
  void initState() {
    initValues();

    super.initState();
  }

  // ==========================================
  @override
  void dispose() {
    super.dispose();
  }

  // ==========================================
  void initValues() {
    idController.text =
        bdProfileController
          .pessoaSelecionadaNotifier
          .value?.pfl_id ?? "";
    fullNameController.text =
        bdProfileController
          .pessoaSelecionadaNotifier
          .value?.pfl_full_name ?? "";
  }

  // ==========================================
  @override
  Widget build(BuildContext context) {
    const double distance = 12;

    return Scaffold(
      appBar: const CustomFloatingAppBar(title: 'Update Password'),
      body: Padding(
        padding: const EdgeInsets.only(
          left: 8.0,
          right: 8.0,
          top: 16.0,
          bottom: 16.0,
        ),
        child: SizedBox.expand(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              // 3. Envolvendo a Column com o widget Form
              child: Form(
                key: _formKey,
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
                      controller: fullNameController,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Name:',
                        prefixIcon: Icon(Icons.verified_user),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: distance),
                    ValueListenableBuilder<bool>(
                      valueListenable: isObscurePassword1,
                      builder: (context, obscureValue, child) {
                        return TextFormField(
                          controller: password1,
                          obscureText: obscureValue,
                          decoration: InputDecoration(
                            labelText: 'New password:',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              onPressed: () {
                                isObscurePassword1.value =
                                    !isObscurePassword1.value;
                              },
                              icon: Icon(
                                obscureValue
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Informe a nova senha';
                            }
                            if (value.length < 6) {
                              return 'A senha deve ter pelo menos 6 caracteres';
                            }
                            if (value.contains(' ')) {
                              return 'A senha não pode conter espaços.';
                            }
                            if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
                              return 'Inclua pelo menos uma letra maiúscula';
                            }
                            if (!RegExp(r'(?=.*[0-9])').hasMatch(value)) {
                              return 'Inclua pelo menos um número';
                            }

                            return null;
                          },
                        );
                      },
                    ),

                    const SizedBox(height: distance),
                    ValueListenableBuilder<bool>(
                      valueListenable: isObscurePassword2,
                      builder: (context, obscureValue, child) {
                        return TextFormField(
                          controller: password2,
                          obscureText: obscureValue,
                          decoration: InputDecoration(
                            labelText: 'Repeat password:',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              onPressed: () {
                                isObscurePassword2.value =
                                    !isObscurePassword2.value;
                              },
                              icon: Icon(
                                obscureValue
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value != password1.text) {
                              return 'As senhas não coincidem';
                            }
                            return null;
                          },
                        );
                      },
                    ),

                    const SizedBox(height: distance),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: context.pop,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Cancelar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.indigo,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: distance),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                try {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Atualizando senha...'),
                                    ),
                                  );

                                  AuthController authController = AuthController();
                                  await authController
                                    .updatePassword(
                                      password1.text.trim()
                                    );

                                  if (context.mounted) {
                                    ScaffoldMessenger
                                      .of(context)
                                      .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Senha alterada com sucesso!',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      context.pop();
                                  }
                                } catch (error) {
                                  if (context.mounted) {
                                    ScaffoldMessenger
                                      .of(context)
                                      .showSnackBar(
                                        SnackBar(
                                          content: Text(error.toString()),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                  }
                                }
                              }
                            },
                            icon: const Icon(Icons.save),
                            label: const Text('Salvar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16
                              ),
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
      ),
    );
  }

}
