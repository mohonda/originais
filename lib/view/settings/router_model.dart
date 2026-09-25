import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:originais/view/dashboard.dart';
import 'package:originais/view/headquartersbar.dart';
import 'package:originais/view/journey_riding.dart';
import 'package:originais/view/about.dart';
import 'package:originais/view/profile.dart';
import 'package:originais/view/monthly_payments.dart';
import 'package:originais/view/associates.dart';
import 'package:originais/view/monthly_generation.dart';
import 'package:originais/view/monthly_operating_expenses.dart';

class RouterModel {
  final String name;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;
  final Widget Function(BuildContext, GoRouterState) builder;

  // ==========================================
  const RouterModel ( {
    required this.name,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.path,
    required this.builder,
  } );

  // ==========================================
  static List<RouterModel> get routerModelList => [
    RouterModel(
      name: 'dashboard',
      label: 'Dashboard',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      path: '/dashboard',
      builder: (context, state) => const Dashboard(),
    ),
    RouterModel (
      name: 'journalriding',
      label: 'Journey Riding',
      icon: Icons.person_2_outlined,
      selectedIcon: Icons.person_2,
      path: '/journalriding',
      builder: (context, state) => const JourneyRiding(),
    ),
    RouterModel (
      name: 'associates',
      label: 'Associates',
      icon: Icons.person_2_outlined,
      selectedIcon: Icons.person_2,
      path: '/associates',
      builder: (context, state) => const Associates(),
    ),
    RouterModel (
      name: 'mensalidades',
      label: 'Mensalidades',
      icon: Icons.person_2_outlined,
      selectedIcon: Icons.person_2,
      path: '/mensalidades',
      builder: (context, state) {
        final hldId = state.uri.queryParameters['hld_id'];
        return MonthlyPayments(hldId: hldId);
      },
    ),
    RouterModel (
      name: 'profile_screen',
      label: 'Profile',
      icon: Icons.info_outline,
      selectedIcon: Icons.info,
      path: '/profile_screen',
      builder: (context, state) => const Profile(),
    ),
    RouterModel (
      name: 'monthlygeneration',
      label: 'Monthly',
      icon: Icons.info_outline,
      selectedIcon: Icons.info,
      path: '/monthlygeneration',
      builder: (context, state) {
        final hldId = state.uri.queryParameters['hld_id'];
        return MonthlyGeneration(hldId: hldId);
      },
    ),
    RouterModel (
      name: 'monthlyOperatingExpenses',
      label: 'monthlyOperatingExpenses',
      icon: Icons.info_outline,
      selectedIcon: Icons.info,
      path: '/monthlyOperatingExpenses',
      builder: (context, state) {
        final pflId = state.uri.queryParameters['pfl_id'];
        final hldId = state.uri.queryParameters['hld_id'];
        final tssId = state.uri.queryParameters['tss_id'];
        return MonthlyOperatingExpenses(
          pflId: pflId,
          hldId: hldId,
          tssId: tssId,
        );
      },
    ),
    RouterModel (
      name: 'headquartersbar',
      label: 'HeadquartersBar',
      icon: Icons.info_outline,
      selectedIcon: Icons.info,
      path: '/headquartersbar',
      builder: (context, state) => const HeadquartersBar(),
    ),
    // RouterModel (
    //   name: 'headquartersbar_opended',
    //   label: 'HeadquartersBarOpended',
    //   icon: Icons.info_outline,
    //   selectedIcon: Icons.info,
    //   path: '/headquartersbar_opened',
    //   builder: (context, state) => HeadquartersBarOpened( openDate: , hld_id: ),
    // ),
    RouterModel (
      name: 'about',
      label: 'About',
      icon: Icons.info_outline,
      selectedIcon: Icons.info,
      path: '/about',
      builder: (context, state) => const About(),
    ),
  ];

}
