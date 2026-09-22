import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:originais/controllers/auth_controller.dart';
import 'package:originais/controllers/profile_controller.dart';
import 'package:originais/view/default_appbar.dart';
import 'package:originais/view/default_snackbar.dart'; 

class ProfileUpdatePassword extends StatefulWidget {
  const ProfileUpdatePassword({super.key});

  @override
  State<ProfileUpdatePassword> createState() => ProfileUpdatePasswordState();
}

class ProfileUpdatePasswordState extends State<ProfileUpdatePassword> {
  late final BdProfileController bdProfileController;
  late final AuthController authController;

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
    super.initState();
    bdProfileController = getItBdProfileController<BdProfileController>();
    authController = AuthController();

    authController.errorNotifier.addListener(_onErrorChanged);
    
    DefaultSnackbar.attachErrorListener(
      context,
      bdProfileController.errorNotifier
    );
    
    DefaultSnackbar.attachSuccessListener(
      context,
      bdProfileController.successNotifier
    );

    initValues();
  }

  // ==========================================
  @override
  void dispose() {
    authController.errorNotifier.removeListener(_onErrorChanged);
    idController.dispose();
    fullNameController.dispose();
    password1.dispose();
    password2.dispose();
    isObscurePassword1.dispose();
    isObscurePassword2.dispose();
    super.dispose();
  }

  // ==========================================
  void _onErrorChanged() {
    final error = authController.errorNotifier.value;
    if (error != null && error.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ==========================================
  void initValues() {
    idController.text =
        bdProfileController.pessoaSelecionadaNotifier.value?.pfl_id ?? "";
    fullNameController.text =
        bdProfileController.pessoaSelecionadaNotifier.value?.pfl_full_name ??
        "";
  }

  // ==========================================
  Future<void> _submeterNovaSenha() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    try {
      final success = await authController.updatePassword(
        password1.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Senha alterada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      debugPrint('❌ Erro ao atualizar senha: $e');
    }
  }

  // ==========================================
  @override
  Widget build(BuildContext context) {
    const double distance = 12;

    return Scaffold(
      appBar: DefaultAppbar(
        title: 'Update Password - ${fullNameController.text}',
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: authController.loadingNotifier,
        builder: (context, isLoading, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: 8.0,
                  right: 8.0,
                  top: 16.0,
                  bottom: 16.0,
                ),
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Campo ID
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

                              // Campo Nome
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

                              // Nova Senha
                              ValueListenableBuilder<bool>(
                                valueListenable: isObscurePassword1,
                                builder: (context, obscureValue, child) {
                                  return TextFormField(
                                    controller: password1,
                                    enabled: !isLoading,
                                    obscureText: obscureValue,
                                    decoration: InputDecoration(
                                      labelText: 'New password:',
                                      prefixIcon:
                                          const Icon(Icons.lock_outline),
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
                                      if (!RegExp(r'(?=.*[A-Z])')
                                          .hasMatch(value)) {
                                        return 'Inclua pelo menos uma letra maiúscula';
                                      }
                                      if (!RegExp(r'(?=.*[0-9])')
                                          .hasMatch(value)) {
                                        return 'Inclua pelo menos um número';
                                      }

                                      return null;
                                    },
                                  );
                                },
                              ),

                              const SizedBox(height: distance),

                              // Repetir Senha
                              ValueListenableBuilder<bool>(
                                valueListenable: isObscurePassword2,
                                builder: (context, obscureValue, child) {
                                  return TextFormField(
                                    controller: password2,
                                    enabled: !isLoading,
                                    obscureText: obscureValue,
                                    decoration: InputDecoration(
                                      labelText: 'Repeat password:',
                                      prefixIcon:
                                          const Icon(Icons.lock_outline),
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

                              const Spacer(),
                              const SizedBox(height: distance),

                              // Botões Cancelar e Salvar
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed:
                                          isLoading ? null : context.pop,
                                      icon: const Icon(Icons.arrow_back),
                                      label: const Text('Cancelar'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.indigo,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: distance),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed:
                                          isLoading ? null : _submeterNovaSenha,
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
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

}