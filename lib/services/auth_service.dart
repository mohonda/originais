import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _auth = Supabase.instance.client.auth;

  // Escuta se o usuário está logado ou não
  Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;

  Future<void> signUp(String email, String password) async {
    await _auth.signUp(email: email, password: password);
  }

  Future<void> login(String email, String password) async {
    await _auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
