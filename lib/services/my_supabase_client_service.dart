import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_it/get_it.dart';

final getItMySupabaseClient = GetIt.instance;

void setupGetItMySupabaseClient() {
  getItMySupabaseClient.registerLazySingleton<MySupabaseClient>(
    () => MySupabaseClient(),
  );
}

class MySupabaseClient {
  final SupabaseClient supabaseClient = Supabase.instance.client;

  // ==========================================
  SupabaseClient getSupabaseClient() {
    return supabaseClient;
  }

  // ==========================================
  String getUserId() {
    // final String? userId = Supabase.instance.client.auth.currentUser?.id;
    final String? userId = supabaseClient.auth.currentUser?.id;

    return userId ?? 'id';
  }

  // ==========================================
  String getUserName() {
    // final user = Supabase.instance.client.auth.currentUser;
    final user = supabaseClient.auth.currentUser;

    if (user != null) {
      final String? nome =
          user.userMetadata?['full_name'] ?? user.userMetadata?['name'];

      return nome ?? 'No name!!!';
    } else {
      return 'No logged!!!';
    }
  }

  // ==========================================
  String getUserEmail() {
    // final String? userEmail = Supabase.instance.client.auth.currentUser?.email;
    final String? userEmail = supabaseClient.auth.currentUser?.email;

    return userEmail ?? 'No e-mail!!!';
  }
}
