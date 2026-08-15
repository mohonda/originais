import 'package:go_router/go_router.dart';
import 'package:gorouter_exemplo/view/main_window.dart';
import 'package:gorouter_exemplo/models/router_model.dart';
import 'package:flutter/material.dart';
import 'package:gorouter_exemplo/view/login.dart';

class RouterSettings {
  static final GoRouter router = GoRouter(
    initialLocation: 'login',
    routes: <RouteBase> [
      GoRoute(path: '/login', builder: (context, state) => LoginHero()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainWindow(navigationShell: navigationShell);
        },
        branches: RouterModel.routerModelList.map((item) {
          return StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(path: item.path, builder: item.builder),
            ],
          );
        }).toList(),
      ),
    ],
  );

  static List<NavigationRailDestination> buildRailDestinations(bool isLabel) {
    if (isLabel) {
      return RouterModel.routerModelList
          .map(
            (item) => NavigationRailDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: Text(item.label),
            ),
          )
          .toList();
    } else {
      return RouterModel.routerModelList
          .map(
            (item) => NavigationRailDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: Text(''),
            ),
          )
          .toList();
    }
  }

  // Gera a lista de itens para a NavigationBar (Mobile)
  static List<NavigationDestination> buildMobileDestinations() {
    return RouterModel.routerModelList
        .map(
          (item) => NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon),
            label: item.label,
          ),
        )
        .toList();
  }
}
