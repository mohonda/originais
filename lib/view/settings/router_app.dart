import 'package:flutter/material.dart';
import 'package:originais/view/settings/router_settings.dart';

class RouterApp extends StatelessWidget {
  const RouterApp({super.key});

  // ==========================================
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      routerConfig: RouterSettings.router,
    );
  }
}
