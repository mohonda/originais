import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gorouter_exemplo/view/dashboard.dart';
import 'package:gorouter_exemplo/view/itens.dart';
import 'package:gorouter_exemplo/view/about.dart';
import 'package:gorouter_exemplo/view/profile.dart';
import 'package:gorouter_exemplo/view/monthly_payments.dart';

class RouterModel {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;
  final Widget Function(BuildContext, GoRouterState) builder;

  const RouterModel ( {
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.path,
    required this.builder,
  } );

  static List<RouterModel> get routerModelList => [
    RouterModel(
      label: 'Dashboard',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      path: '/dashboard',
      builder: (context, state) => const Dashboard(),
    ),
    RouterModel (
      label: 'Itens',
      icon: Icons.person_2_outlined,
      selectedIcon: Icons.person_2,
      path: '/itens',
      builder: (context, state) => const Itens(),
    ),
    RouterModel (
      label: 'Mensalidades',
      icon: Icons.person_2_outlined,
      selectedIcon: Icons.person_2,
      path: '/mensalidades',
      builder: (context, state) => const MonthlyPayments(),
    ),
    RouterModel (
      label: 'Profile',
      icon: Icons.info_outline,
      selectedIcon: Icons.info,
      path: '/profile_screen',
      builder: (context, state) => const Profile(),
    ),
    RouterModel (
      label: 'About',
      icon: Icons.info_outline,
      selectedIcon: Icons.info,
      path: '/about',
      builder: (context, state) => const About(),
    ),
  ];
}
