import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:sidebarx/sidebarx.dart';
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
  late final SidebarXController _sidebarController;

  final mySupabaseClient = getItMySupabaseClient<MySupabaseClient>();
  final bdProfileController = getItBdProfileController<BdProfileController>();
  final bdJourneyRidingController =
      getItBdJourneyRidingController<BdJourneyRidingController>();
  final bdMonthlyPaymentsController =
      getItbdMonthlyPaymentsController<BdMonthlyPaymentsController>();
  final bdProfileAssociateStatusController =
      getItBdVProfileAssociateStatusController<
        BdVProfileAssociateStatusController
      >();
  final bdVMensalidadesDistinctController =
      getItBdVMensalidadesDistinctController<
        BdVMensalidadesDistinctController
      >();

  int win = 0;

  bool _isMensalidadesExpanded = false;
  bool _isAssemblersExpanded = false;
  bool _isCommerceExpanded = false;

  @override
  void initState() {
    super.initState();

    _sidebarController = SidebarXController(
      selectedIndex: widget.navigationShell.currentIndex,
      extended: true,
    );

    final userId = mySupabaseClient.getUserId();
    bdProfileController.checkUserProfileExist(userId);
    bdProfileController.fetchProfilesById(userId);
    bdProfileController.loadProfiles();
    bdJourneyRidingController.loadJourneyRiding();
    bdMonthlyPaymentsController.loadCurrentMonthlyPayment();
    bdVMensalidadesDistinctController.loadMensalidadesDistincts();
  }

  @override
  Widget build(BuildContext context) {
    if (win == 0 &&
        !kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      windowManager.setSize(const Size(1024, 768));
      win++;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        if (isMobile && !_sidebarController.extended) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _sidebarController.setExtended(true);
          });
        }

        return Scaffold(
          // No Mobile: Exibe a AppBar com ícone para abrir a gaveta (Drawer)
          appBar: isMobile
              ? AppBar(
                  title: const Text('Menu'),
                  leading: Builder(
                    builder: (context) {
                      return IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      );
                    },
                  ),
                )
              : null,

          // No Mobile: O SidebarX fica dentro do Drawer
          drawer: isMobile
              ? Drawer(
                  child: SafeArea(
                    child: _buildSidebarX(context, isMobile: true),
                  ),
                )
              : null,

          body: Row(
            children: [
              // No Desktop/Tablet: O SidebarX fica visível diretamente na tela
              if (!isMobile) _buildSidebarX(context, isMobile: false),

              // Conteúdo da rota do GoRouter
              Expanded(child: widget.navigationShell),
            ],
          ),
        );
      },
    );
  }

  // ================= CONSTRUTOR REUTILIZÁVEL DO SIDEBARX =================
  SidebarX _buildSidebarX(BuildContext context, {required bool isMobile}) {
    final userEmail = mySupabaseClient.getUserEmail();

    return SidebarX(
      controller: _sidebarController,
      showToggleButton: !isMobile,
      theme: SidebarXTheme(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(color: Colors.white70),
        selectedTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        // 🟢 ADICIONE ESTAS 4 LINHAS PARA CORRIGIR O ALINHAMENTO DO ÍCONE E TEXTO
        itemPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        selectedItemPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemTextPadding: const EdgeInsets.only(left: 16),
        selectedItemTextPadding: const EdgeInsets.only(left: 16),
        
        itemDecoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
        selectedItemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
          border: Border.all(
            // color: Theme.of(context).primaryColor,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white70, size: 20),
        selectedIconTheme: IconThemeData(color: Colors.white, size: 22),
        // ==========================================
        // ADICIONE ESTAS 3 PROPRIEDADES PARA O HOVER
        // ==========================================
        hoverColor: Colors.white.withValues(
          alpha: 0.1,
        ), // Cor de fundo ao passar o mouse
        hoverTextStyle: const TextStyle(
          color: Colors.white, // Cor do texto no hover
        ),
        hoverIconTheme: const IconThemeData(
          color: Colors.white, // Cor do ícone no hover
          size: 20,
        ),
        
        
        
      ),
      extendedTheme: SidebarXTheme(width: isMobile ? double.infinity : 220),

      // CABEÇALHO (Avatar + Nome e E-mail)
      headerBuilder: (context, extended) {
        return ValueListenableBuilder(
          valueListenable: bdProfileController.pessoaSelecionadaNotifier,
          builder: (context, pessoa, child) {
            String name = pessoa?.pfl_full_name ?? "NoNe";
            final userName = name.length > 15
                ? '${name.substring(0, 15)}...'
                : name;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                children: [
                  buildAvatar(pessoa?.pfl_avatar_url ?? ""),
                  if (extended) ...[
                    const SizedBox(height: 12),
                    buildNameEmail(userName, userEmail),
                  ],
                ],
              ),
            );
          },
        );
      },

      // ITENS DE NAVEGAÇÃO
      items: [
        SidebarXItem(
          icon: Icons.home_outlined,
          label: ' Dashboard',
          onTap: () => _onItemTapped('dashboard', isMobile: isMobile),
        ),
        SidebarXItem(
          icon: Icons.person_outline,
          label: ' Commerce...',
          onTap: () {
            setState(() {
              _isCommerceExpanded = !_isCommerceExpanded;
            });
          },
        ),
        if (_isCommerceExpanded) ...[
          SidebarXItem(
            icon: Icons.subdirectory_arrow_right_rounded,
            label: '   Headquarters Bar',
            onTap: () => _onItemTapped('mensalidades', isMobile: isMobile),
          ),
          SidebarXItem(
            icon: Icons.subdirectory_arrow_right_rounded,
            label: '   Outfit',
            onTap: () => _onItemTapped('monthlygeneration', isMobile: isMobile),
          ),
        ],

        SidebarXItem(
          icon: Icons.person_outline,
          label: ' Profile',
          onTap: () => _onItemTapped('profile_screen', isMobile: isMobile),
        ),
        SidebarXItem(
          icon: Icons.two_wheeler_outlined,
          label: ' Associates Status',
          onTap: () => _onItemTapped('associates', isMobile: isMobile),
        ),
        SidebarXItem(
          icon: Icons.payments_outlined,
          selectable: false,
          label: ' Monthly...',
          onTap: () {
            setState(() {
              _isMensalidadesExpanded = !_isMensalidadesExpanded;
            });
          },
        ),
        // ================= SUBITENS DE MENSALIDADES =================
        if (_isMensalidadesExpanded) ...[
          SidebarXItem(
            icon: Icons.subdirectory_arrow_right_rounded,
            label: '   Monthly Paiment',
            onTap: () => _onItemTapped('mensalidades', isMobile: isMobile),
          ),
          // SidebarXItem(
          //   icon: Icons.subdirectory_arrow_right_rounded,
          //   label: '   Pagas e Pendentes',
          //   onTap: () => _onItemTapped('mensalidades_lista', isMobile: isMobile),
          // ),
          SidebarXItem(
            icon: Icons.subdirectory_arrow_right_rounded,
            label: '   Monthly Generation',
            onTap: () => _onItemTapped('monthlygeneration', isMobile: isMobile),
          ),
        ],
        SidebarXItem(
          icon: Icons.payments_outlined,
          selectable: false,
          label: ' Assemblers...',
          onTap: () {
            setState(() {
              _isAssemblersExpanded = !_isAssemblersExpanded;
            });
          },
        ),
        // ================= SUBITENS DE MENSALIDADES =================
        if (_isAssemblersExpanded) ...[
          SidebarXItem(
            icon: Icons.subdirectory_arrow_right_rounded,
            label: '   Journey Riding',
            onTap: () => _onItemTapped('journalriding', isMobile: isMobile),
          ),
        ],

      ],

      footerBuilder: (context, extended) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. BOTÃO SOBRE
              extended
                  ? TextButton.icon(
                      onPressed: () => context.go('/about'),
                      icon: const Icon(
                        Icons.info_outline,
                        color: Colors.white70,
                      ),
                      label: const Text(
                        'Sobre o App',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : IconButton(
                      onPressed: () => context.go('/about'),
                      icon: const Icon(
                        Icons.info_outline,
                        color: Colors.white70,
                      ),
                      tooltip: 'Sobre',
                    ),

              // 2. LINHA DIVISÓRIA DE SEPARAÇÃO
              const Divider(color: Colors.white24, height: 16, thickness: 1),

              // 3. BOTÃO DE LOGOUT
              extended
                  ? TextButton.icon(
                      onPressed: () => confirmLogout(),
                      icon: const Icon(Icons.logout, color: Colors.redAccent),
                      label: const Text(
                        'Sair do App',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : IconButton(
                      onPressed: () => confirmLogout(),
                      icon: const Icon(Icons.logout, color: Colors.redAccent),
                      tooltip: 'Logout',
                    ),
            ],
          ),
        );
      },
    );
  }

  // ================= NAVEGAÇÃO =================
  void _onItemTapped(String routeName, {required bool isMobile}) {
    if (isMobile) {
      Navigator.pop(context);
    }

    // Navega diretamente pelo nome registrado no GoRouter
    context.goNamed(routeName);
  }

  // ================= WIDGETS E MÉTODOS AUXILIARES =================
  Widget buildNameEmail(String nome, String email) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => context.go('/profile_screen'),
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
          onTap: () => context.go('/profile_screen'),
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

  Widget buildAvatar(String avatarUrl) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => context.go('/profile_screen'),
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
            backgroundColor: Theme.of(
              context,
            ).primaryColorLight.withValues(alpha: 0.4),
            child: IconButton(
              icon: const Icon(
                Icons.camera_alt,
                size: 12,
                color: Colors.white70,
              ),
              onPressed: () async {
                final newUrl = await bdProfileController
                    .selecionarEEnviarFoto();
                if (newUrl != null) {
                  setState(() {});
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  void confirmLogout() async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Deseja realmente sair do aplicativo?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
      context.go('/login');
    }
  }
}
