import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';
import 'package:originais/view/settings/router_app.dart';
import 'package:originais/controllers/journey_riding_controller.dart';
import 'package:originais/view/dashboard_injector.dart';
import 'package:originais/controllers/profile_controller.dart';
import 'package:originais/services/my_supabase_client_service.dart';
import 'package:originais/controllers/monthly_payments_controller.dart';
import 'package:originais/controllers/forma_pagamento_controller.dart';
import 'package:originais/controllers/profile_associate_status_controller.dart';
import 'package:originais/controllers/profiles_sanctions_controller.dart';
import 'package:originais/controllers/executive_committee_termofoffice_members_controller.dart';
import 'package:originais/controllers/monthly_distinct_controller.dart';
import 'package:originais/controllers/payment_value_controller.dart';
import 'package:originais/controllers/headquarters_bar_controller.dart';
import 'package:originais/controllers/products_controller.dart';
import 'package:originais/controllers/ticket_controller.dart';
import 'package:originais/services/general_service.dart';

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

  setupGetItMySupabaseClient();
  setupGetItBdJourneyRidingController();
  setupGetItDashboardNotifier();
  setupGetItProfileBdItemController();
  setupGetItBdMonthlyPaymentsController();
  setupGetItBdFormaPagamentoController();
  setupGetItBdVProfileAssociateStatusController();
  setupGetItBdVProfilesSanctionsController();
  setupGetItBdVExecutiveCommitteeTermOfOfficeMembersController();
  setupGetItBdVMensalidadesDistinctController();
  setupGetItBdPaymentValueController();
  setupGetItBdHeadquartersBarController();
  setupGetItProductsController();
  setupGetItTicketController();

  setupGetItGeneralService();
  
  runApp(const RouterApp());
}
