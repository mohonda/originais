import 'package:gorouter_exemplo/view/settings/router_settings.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gorouter_exemplo/services/my_supabase_client_service.dart';

class AuthController {
  // Pega a instância já inicializada do Supabase
  final mySupabaseClient = getItMySupabaseClient<MySupabaseClient>();
  late SupabaseClient supabaseClient;
  
  // ==========================================
  AuthController() {
    supabaseClient = mySupabaseClient.getSupabaseClient();
  }

  // ==========================================
  Future<void> authentication({
    required String email,
    required String password,
    required bool isSignUp,
  }) async {
    try {
      if (isSignUp) {
        // Fluxo de Cadastro
        await supabaseClient.auth.signUp(
          email: email,
          password: password
        );
      } else {
        // Fluxo de Login
        await supabaseClient.auth.signInWithPassword(
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

  // ==========================================
  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    RouterSettings.router.go('/login');
  }

  // ==========================================
  Future<void> updatePassword( String newPassword ) async {
    try {
      await supabaseClient.auth.updateUser(
        UserAttributes( password: newPassword ),
      );
      // Senha alterada com sucesso
    } on AuthException catch (error) {
      throw Exception( error.message );
    } catch (error) {
      throw Exception( error );
    }
  }

}
