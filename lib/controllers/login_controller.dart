import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gorouter_exemplo/controllers/auth_controller.dart';
import 'package:gorouter_exemplo/view/settings/router_settings.dart';

class LoginController {
  final ValueNotifier<bool> rememberNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> obscureNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);
  
  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

  // ==========================================
  void dispose() {
    rememberNotifier.dispose();
    obscureNotifier.dispose();
    isLoadingNotifier.dispose();
    emailController.dispose();
    senhaController.dispose();
  }

  // ==========================================
  Future<void> carregarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    final bool remembered = prefs.getBool('remember_me') ?? false;

    if (remembered) {
      rememberNotifier.value = true;
      emailController.text = prefs.getString('saved_email') ?? '';
    }
  }

  // ==========================================
  Future<void> _salvarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (rememberNotifier.value) {
      await prefs.setBool('remember_me', true);
      await prefs.setString('saved_email', emailController.text.trim());
    } else {
      await prefs.setBool('remember_me', false);
      await prefs.remove('saved_email');
    }
  }

  // ==========================================
  Future<void> submeter(bool ehCadastro, BuildContext context) async {
    final email = emailController.text.trim();
    final senha = senhaController.text.trim();

    if (email.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha o e-mail e a senha.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    isLoadingNotifier.value = true;

    try {
      await _salvarPreferencias();

      await AuthController().authentication(
        email: email,
        password: senha,
        isSignUp: ehCadastro,
      );
      RouterSettings.router.go('/dashboard');

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      isLoadingNotifier.value = false;
    }
  }

}
