import 'package:flutter/material.dart';
import 'package:originais/view/settings/router_settings.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:originais/services/my_supabase_client_service.dart';

class AuthController {
  // Pega a instância já inicializada do Supabase
  final mySupabaseClient = getItMySupabaseClient<MySupabaseClient>();
  late SupabaseClient supabaseClient;

  final ValueNotifier<bool> loadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);
    final ValueNotifier<String?> successNotifier = ValueNotifier<String?>(null);

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
      loadingNotifier.value = true;
      errorNotifier.value = null;

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
      errorNotifier.value = 'authentication: $e';
      throw Exception(e.message);
    } catch (e) {
      errorNotifier.value = 'authentication: $e';
      throw Exception('Ocorreu um erro inesperado. Verifique sua conexão.');
    } finally{
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    RouterSettings.router.go('/login');
  }

  // ==========================================
  Future<bool> updatePassword( String newPassword ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      await supabaseClient.auth.updateUser(
        UserAttributes( password: newPassword ),
      );
      return true;      
    } on AuthException catch (e) {
      errorNotifier.value = 'updatePassword: $e';
      throw Exception( e.message );
      
    } catch (e) {
      errorNotifier.value = 'updatePassword: $e';
      throw Exception( e );
    } finally{
      successNotifier.value = 'Password updated with sucess!';
      loadingNotifier.value = false;
    }
  }

}
