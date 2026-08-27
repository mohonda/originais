import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';
import 'package:gorouter_exemplo/services/my_supabase_client_service.dart';
import 'package:gorouter_exemplo/view/settings/router_settings.dart';
import 'package:gorouter_exemplo/controllers/auth_controller.dart';
import 'package:gorouter_exemplo/controllers/bd_profile_controller.dart';
import 'package:gorouter_exemplo/controllers/bd_journeyriding_controller.dart';
import 'package:gorouter_exemplo/controllers/bd_monthlypayments_controller.dart';
import 'package:gorouter_exemplo/controllers/bd_vprofile_associatestatus_controller.dart';
import 'package:gorouter_exemplo/controllers/bd_vprofiles_sanctions_controller.dart';
import 'package:gorouter_exemplo/controllers/bd_vmensalidades_distinct_controller.dart';


class MainWindow extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainWindow({super.key, required this.navigationShell});

  @override
  State<MainWindow> createState() => _MainWindow();
}

class _MainWindow extends State<MainWindow> {
  bool _menuEstendido = true;

  final mySupabaseClient =
      getItMySupabaseClient<MySupabaseClient>();

  final bdProfileController = getItBdProfileController<BdProfileController>();
  final bdJourneyRidingController = getItBdJourneyRidingController<BdJourneyRidingController>();
  final bdMonthlyPaymentsController =
      getItbdMonthlyPaymentsController<BdMonthlyPaymentsController>();

  final bdProfileAssociateStatusController =
    getItBdVProfileAssociateStatusController<BdVProfileAssociateStatusController>();
  
  final bdVMensalidadesDistinctController =
      getItBdVMensalidadesDistinctController<BdVMensalidadesDistinctController>();

  int win = 0;

  // ==========================================
  @override
  void initState() {
    final userId = mySupabaseClient.getUserId();
    bdProfileController.checkUserProfileExist(userId);
    bdProfileController.fetchProfilesById(userId);

    bdProfileController.loadProfiles();
    bdJourneyRidingController.loadJourneyRiding();

    bdMonthlyPaymentsController.loadCurrentMonthlyPayment();

    bdVMensalidadesDistinctController.loadMensalidadesDistincts();
    
    super.initState();
  }

  // ==========================================
  Widget buildNameEmail(String nome, String email) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            context.go('/profile_screen');
          },
          child: Text(
            nome,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            context.go('/profile_screen');
          },
          child: Text(
            email,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  Widget buildAvatar(String avatarUrl) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            context.go('/profile_screen');
          },
          child: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey[300],
            backgroundImage: avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : null,
            child: avatarUrl.isEmpty
                ? const Icon(Icons.person, size: 40, color: Colors.grey)
                : null,
          ),
        ),
        Positioned(
          bottom: -2,
          right: -2,
          child: CircleAvatar(
            radius: 12,
            backgroundColor: Theme.of(context).primaryColorLight.withValues(alpha: 0.4),
            child: IconButton(
              icon: const Icon(Icons.camera_alt, size: 12, color: Colors.white70),
              onPressed: () async {
                final newUrl = await bdProfileController
                    .selecionarEEnviarFoto();
                if (newUrl != null) {
                  setState(() {
                    avatarUrl = newUrl;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  @override
  Widget build(BuildContext context) {
    final destinations = [
      ...RouterSettings.buildMobileDestinations(),
      const NavigationDestination(
        icon: Icon(Icons.logout, color: Colors.redAccent),
        label: 'Sair',
      ),
    ];

    final userEmail = mySupabaseClient.getUserEmail();
    if (win == 0 &&
        !kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      windowManager.setSize(Size(1024, 768));
      win++;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          return Scaffold(
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  clipBehavior: Clip
                      .none, // Permite que o botão "vaze" para fora do container
                  children: [
                    Container(
                      color: Colors.transparent,
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 8.0,
                                top: 24.0,
                                right: 8.0,
                                bottom: 8.0,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ValueListenableBuilder(
                                    valueListenable: bdProfileController
                                        .pessoaSelecionadaNotifier,
                                    builder: (context, pessoa, child) {
                                      String name;
                                      String fName = pessoa?.pfl_full_name ?? "NoNe";
                                      String nName = pessoa?.pfl_full_name ?? "";
                                      if ( nName.isNotEmpty ){
                                        name = nName;
                                      } else {
                                        name = fName;
                                      }
                                      final userName = name.length > 15
                                          ? '${name.substring(0, 15)}...'
                                          : name;
                                      return Column(
                                        children: [
                                          buildAvatar(pessoa?.pfl_avatar_url ?? ""),
                                          const SizedBox(height: 12),
                                          if (_menuEstendido) ...[
                                            buildNameEmail(userName, userEmail),
                                          ],
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),

                            Expanded(
                              child: NavigationRail(
                                selectedIndex:
                                    widget.navigationShell.currentIndex,
                                onDestinationSelected: (int index) {
                                  widget.navigationShell.goBranch(
                                    index,
                                    initialLocation:
                                        index ==
                                        widget.navigationShell.currentIndex,
                                  );
                                },
                                labelType: NavigationRailLabelType.all,
                                destinations:
                                    RouterSettings.buildRailDestinations(
                                      _menuEstendido,
                                    ),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: 24.0,
                                left: 8.0,
                                right: 8.0,
                              ),
                              child: _menuEstendido
                                  ? TextButton.icon(
                                      onPressed: () async => confirmLogout(),
                                      icon: const Icon(
                                        Icons.logout,
                                        color: Colors.redAccent,
                                      ),
                                      label: const Text(
                                        'Sair do App',
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : IconButton(
                                      onPressed: () async => confirmLogout(),
                                      icon: const Icon(
                                        Icons.logout,
                                        color: Colors.redAccent,
                                      ),
                                      tooltip: 'Logout',
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 4. O Novo Botão de Expandir Posicionado na Linha
                    Positioned(
                      right:
                          -8, // Puxa exatamente metade da largura do botão para fora
                      top: 2, // A altura em que o botão vai ficar no menu
                      child: Material(
                        elevation:
                            2, // Dá uma sombra legal para parecer que está flutuando
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            setState(() {
                              _menuEstendido = !_menuEstendido;
                            });
                          },
                          child: Container(
                            height: 28, // Tamanho do botão
                            width: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context)
                                .scaffoldBackgroundColor,
                            ),
                            child: Icon(
                              _menuEstendido
                                  ? Icons.arrow_back_ios_new
                                  : Icons.arrow_forward_ios,
                              size: 14,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: widget.navigationShell),
              ],
            ),
          );
        } else {
          return Scaffold(
            body: widget.navigationShell,
            bottomNavigationBar: NavigationBar(
              selectedIndex: widget.navigationShell.currentIndex,
              onDestinationSelected: (int index) {
                // Intercepta o clique no último item (logout)
                if (index == destinations.length - 1) {
                  confirmLogout();
                  return;
                }

                widget.navigationShell.goBranch(
                  index,
                  initialLocation:
                    index == widget.navigationShell.currentIndex,
                );
              },
              destinations: destinations,
            ),
          );
        }
      },
    );
  }

  // ==========================================
  void confirmLogout() async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              // onPressed: () => Navigator.pop(context, true),
              onPressed: () => context.go('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red
              ),
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar == true && context.mounted) {
      AuthController().logout();
    }
  }
}
