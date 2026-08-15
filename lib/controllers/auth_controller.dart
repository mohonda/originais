import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gorouter_exemplo/view/settings/router_settings.dart';

class AuthController {
  // Pega a instância já inicializada do Supabase
  final supabase = Supabase.instance.client;

  Future<void> authentication({
    required String email,
    required String password,
    required bool isSignUp,
  }) async {
    try {
      if (isSignUp) {
        // Fluxo de Cadastro
        await supabase.auth.signUp(email: email, password: password);
      } else {
        // Fluxo de Login
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      }
    } on AuthException catch (e) {
      // Captura erros do próprio Supabase (senha errada, limite de tentativas, etc)
      throw Exception(e.message);
    } catch (e) {
      // Captura erros genéricos (falta de internet, falha no dispositivo)
      throw Exception('Ocorreu um erro inesperado. Verifique sua conexão.');
    }
  }

  // Já deixamos o método de logout pronto
  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    RouterSettings.router.go('/login');
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      // Senha alterada com sucesso
    } on AuthException catch (error) {
      throw Exception( error.message );
    } catch (error) {
      throw Exception( error );
    }
  }
}

// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:gorouter_exemplo/view/settings/router_settings.dart';
// import 'package:gorouter_exemplo/services/auth_service.dart';

// class AuthController extends ChangeNotifier {
//   final AuthService _authService = AuthService();

//   bool isLoading = false;
//   String? erro;

//   Future<void> authentication({
//     required String email,
//     required String password,
//     required bool isSignUp,
//   }) async {
//     isLoading = true;
//     erro = null;
//     notifyListeners();

//     try {
//       if (isSignUp) {
//         await _authService.signUp(email, password);
//       } else {
//         await _authService.login(email, password);
//       }
//     } catch (error) {
//       erro = 'Falha na autenticação. Verifique os dados.';
//     } finally {
//       isLoading = false;
//       notifyListeners();
//       RouterSettings.router.go('/dashboard');
//     }
//   }

//   Future<void> logout() async {
//     isLoading = true;
//     notifyListeners();

//     await _authService.signOut();
//     RouterSettings.router.go('/login');

//     isLoading = false;
//     notifyListeners();
//   }

//   Future<void> loginComGoogle() async {
//     try {
//       await Supabase.instance.client.auth.signInWithOAuth(
//         OAuthProvider.google,
//       );
//     } catch (e) {
//       throw Exception('Erro ao fazer login com o Google: $e');
//     }
//   }
// }
