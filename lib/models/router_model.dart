import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gorouter_exemplo/view/dashboard.dart';
import 'package:gorouter_exemplo/view/journey_riding.dart';
import 'package:gorouter_exemplo/view/about.dart';
import 'package:gorouter_exemplo/view/profile.dart';
import 'package:gorouter_exemplo/view/monthly_payments.dart';
import 'package:gorouter_exemplo/view/associates.dart';
import 'package:gorouter_exemplo/view/monthly_generation.dart';

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
      builder: (context, state) => const MonthlyPayments(),
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
      builder: (context, state) => const MonthlyGeneration(),
    ),
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
