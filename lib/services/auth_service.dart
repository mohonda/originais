import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gorouter_exemplo/services/my_supabase_client_service.dart';

class AuthService{
  final mySupabaseClient = getItMySupabaseClient<MySupabaseClient>();
  late SupabaseClient supabaseClient;

  // ==========================================
  AuthService() {
    supabaseClient = mySupabaseClient.getSupabaseClient();
  }


  // ==========================================
  Stream<AuthState> get onAuthStateChange =>
    supabaseClient.auth.onAuthStateChange;

  // ==========================================
  Future<void> signUp(String email, String password) async {
    await supabaseClient.auth.signUp(
      email: email,
      password: password
    );
  }

  // ==========================================
  Future<void> login(String email, String password) async {
    await supabaseClient.auth.signInWithPassword(
      email: email,
      password: password
      );
  }

  // ==========================================
  Future<void> signOut() async {
    await supabaseClient.auth.signOut();
  }

}
