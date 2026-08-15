import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_it/get_it.dart';

final getItSupabaseConnectedUser = GetIt.instance;

void setupGetItSupabaseConnectedUser() {
  getItSupabaseConnectedUser.registerLazySingleton<SupabaseConnectedUser>(
    () => SupabaseConnectedUser(),
  );
}

class SupabaseConnectedUser {
  String getUserId() {
    final String? userId = Supabase.instance.client.auth.currentUser?.id;

    return userId ?? 'id';
  }

  String getUserName() {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      final String? nome =
          user.userMetadata?['full_name'] ?? user.userMetadata?['name'];

      return nome ?? 'No name!!!';
    } else {
      return 'No logged!!!';
    }
  }

  String getUserEmail() {
    final String? userEmail = Supabase.instance.client.auth.currentUser?.email;

    return userEmail ?? 'No e-mail!!!';
  }
}
