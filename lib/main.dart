import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';
import 'package:gorouter_exemplo/view/settings/router_app.dart';
import 'package:gorouter_exemplo/controllers/bd_item_controller.dart';
import 'package:gorouter_exemplo/view/dashboard_injector.dart';
import 'package:gorouter_exemplo/controllers/bd_profile_controller.dart';
import 'package:gorouter_exemplo/services/supabase_connected_user_service.dart';
import 'package:gorouter_exemplo/controllers/bd_monthlypayments_controller.dart';
import 'package:gorouter_exemplo/controllers/bd_formapagamento_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1024, 768),
      minimumSize: Size(500, 820),
      center: true,
      title: ' Originais Moto Clube \u00AE ',
    );
 
    windowManager.waitUntilReadyToShow(
      windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      }
    );
  }

  WidgetsFlutterBinding.ensureInitialized();
  try {
    if ( kIsWeb ){
      await Supabase.initialize(
        url: const String.fromEnvironment('SUPABASE_URL'),
        anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
      );
    } else {
      await Supabase.initialize(
        url: 'https://ubqhcvvyexmgyzzckzis.supabase.co',
        anonKey: 'sb_publishable_wo-dg-_T1UJActeZRCCuhQ_bdCr_RJM',
      );
    }
    
    debugPrint('✅ Supabase inicializado com sucesso!');
  } catch (error) {
    debugPrint('❌ Erro ao inicializar o Supabase: $error');
    return;
  }


  setupGetItSupabaseConnectedUser();
  setupGetItBdItemController();
  setupGetItDashboardNotifier();
  setupGetItProfileBdItemController();
  setupGetItBdMonthlyPaymentsController();
  setupGetItBdFormaPagamentoController();

  runApp(const RouterApp());
}
