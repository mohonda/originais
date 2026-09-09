import 'package:flutter/material.dart';
import 'package:originais/view/settings/router_settings.dart';
import 'package:google_fonts/google_fonts.dart';

class RouterApp extends StatelessWidget {
  const RouterApp({super.key});

  // ==========================================
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      // 🎨 O Theme Data entra AQUI:
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
        
        // Define a fonte padrão para todo o aplicativo
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.light().textTheme,
        ).copyWith(
          headlineSmall: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
            color: Colors.indigo,
            letterSpacing: 0.15,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 10.0,
            fontWeight: FontWeight.w100,
            color: Colors.indigo,
            letterSpacing: 0.15,
          ),
          bodySmall:  TextStyle(
            fontFamily: 'Roboto',
            fontSize: 8.0,
            fontWeight: FontWeight.w100,
            color: Colors.indigo,
            letterSpacing: 0.15,
          ),
        ),
      ),

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
