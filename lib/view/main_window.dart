import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:window_manager/window_manager.dart';

import 'package:originais/controllers/auth_controller.dart';
import 'package:originais/controllers/journey_riding_controller.dart';
import 'package:originais/controllers/monthly_distinct_controller.dart';
import 'package:originais/controllers/monthly_payments_controller.dart';
import 'package:originais/controllers/profile_associate_status_controller.dart';
import 'package:originais/controllers/profile_controller.dart';
import 'package:originais/controllers/profile_image_service.dart';
import 'package:originais/services/my_supabase_client_service.dart';

class MainWindow extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainWindow({super.key, required this.navigationShell});

  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow> {
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

  final paymentService = ProfileImageService();

  int win = 0;

  bool _isMensalidadesExpanded = false;
  bool _isAssemblersExpanded = false;
  bool _isCommerceExpanded = false;

  String pfl_id = '';
  String hld_id = '';

  // ==========================================
  @override
  void initState() {
    super.initState();

    _sidebarController = SidebarXController(
      selectedIndex: widget.navigationShell.currentIndex,
      extended: true,
    );

    bdProfileController.errorNotifier.addListener(_onErrorProfileChanged);
    bdJourneyRidingController.errorNotifier.addListener(_onErrorJourneyChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inicializarDados();
    });
  }

  // ==========================================
  @override
  void dispose() {
    bdProfileController.errorNotifier.removeListener(_onErrorProfileChanged);
    bdJourneyRidingController.errorNotifier.removeListener(_onErrorJourneyChanged);
    _sidebarController.dispose();
    super.dispose();
  }

  // ==========================================
  void _onErrorProfileChanged() {
    final erro = bdProfileController.errorNotifier.value;
    if (erro != null && erro.isNotEmpty && mounted) {
      _exibirSnackBarErro(erro);
    }
  }

  // ==========================================
  void _onErrorJourneyChanged() {
    final erro = bdJourneyRidingController.errorNotifier.value;
    if (erro != null && erro.isNotEmpty && mounted) {
      _exibirSnackBarErro(erro);
    }
  }

  // ==========================================
  void _exibirSnackBarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================
  Future<void> _inicializarDados() async {
    pfl_id = mySupabaseClient.getUserId();

    if (pfl_id.isEmpty) return;

    await bdProfileController.checkUserProfileExist(pfl_id);

    hld_id =
        bdProfileController.pessoaSelecionadaNotifier.value?.hld_id ?? '1';

    await Future.wait([
      bdProfileController.fetchProfilesById(pfl_id, hld_id),
      bdProfileController.loadProfiles(hld_id),
      bdJourneyRidingController.loadJourneyRiding(hld_id),
      bdMonthlyPaymentsController.loadCurrentMonthlyPayment(),
      bdVMensalidadesDistinctController.loadMensalidadesDistincts(),
    ]);
  }

  // ==========================================
  @override
  Widget build(BuildContext context) {
    if (win == 0 &&
        !kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      windowManager.setSize(const Size(1024, 768));
      win++;
    }

    return ValueListenableBuilder<bool>(
      valueListenable: bdProfileController.loadingNotifier,
      builder: (context, isLoading, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            if (isMobile && !_sidebarController.extended) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _sidebarController.setExtended(true);
              });
            }

            return Scaffold(
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
                      bottom: isLoading
                          ? const PreferredSize(
                              preferredSize: Size.fromHeight(2.0),
                              child: LinearProgressIndicator(),
                            )
                          : null,
                    )
                  : null,

              drawer: isMobile
                  ? Drawer(
                      child: SafeArea(
                        child: _buildSidebarX(context, isMobile: true),
                      ),
                    )
                  : null,

              body: Stack(
                children: [
                  Row(
                    children: [
                      if (!isMobile) _buildSidebarX(context, isMobile: false),
                      Expanded(child: widget.navigationShell),
                    ],
                  ),

                  // 🟢 Indicador visual discreto superior durante o processamento do banco
                  if (isLoading && !isMobile)
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(minHeight: 3),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
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
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          color: Colors.white70,
          fontWeight: FontWeight.w100,
          fontSize: 12,
        ),
        selectedTextStyle: const TextStyle(
          fontFamily: 'Roboto',
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        itemPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        selectedItemPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        itemTextPadding: const EdgeInsets.only(left: 16),
        selectedItemTextPadding: const EdgeInsets.only(left: 16),
        itemDecoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
        selectedItemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
          border: Border.all(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white70, size: 20),
        selectedIconTheme: const IconThemeData(color: Colors.white, size: 22),
        hoverColor: Colors.white.withValues(alpha: 0.1),
        hoverTextStyle: const TextStyle(color: Colors.white),
        hoverIconTheme: const IconThemeData(color: Colors.white, size: 20),
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
            iconBuilder: (selected, hovered) {
              return const Icon(
                Icons.subdirectory_arrow_right_rounded,
                color: Colors.orangeAccent,
                size: 20,
              );
            },
            label: '   Headquarters Bar',
            onTap: () => _onItemTapped('headquartersbar', isMobile: isMobile),
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
        if (_isMensalidadesExpanded) ...[
          SidebarXItem(
            iconBuilder: (selected, hovered) {
              return const Icon(
                Icons.subdirectory_arrow_right_rounded,
                color: Colors.orangeAccent,
                size: 20,
              );
            },
            label: '   Monthly Paiment',
            onTap: () => _onItemTapped(
                            'mensalidades',
                            isMobile: isMobile,
                            queryParameters: {'hld_id': hld_id},
                          ),
          ),
          SidebarXItem(
            iconBuilder: (selected, hovered) {
              return const Icon(
                Icons.subdirectory_arrow_right_rounded,
                color: Colors.orangeAccent,
                size: 20,
              );
            },
            label: '   Monthly Generation',
            onTap: () =>
                _onItemTapped('monthlygeneration', isMobile: isMobile),
          ),
          SidebarXItem(
            iconBuilder: (selected, hovered) {
              return const Icon(
                Icons.subdirectory_arrow_right_rounded,
                color: Colors.orangeAccent,
                size: 20,
              );
            },
            label: '   Monthly Operating Expenses',
            onTap: () => _onItemTapped(
                'monthlyOperatingExpenses',
                isMobile: isMobile,
                queryParameters: {
                  'pfl_id': pfl_id,
                  'hld_id': hld_id,
                  'tss_id': '5'
                },
              ),
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
        if (_isAssemblersExpanded) ...[
          SidebarXItem(
            iconBuilder: (selected, hovered) {
              return const Icon(
                Icons.subdirectory_arrow_right_rounded,
                color: Colors.orangeAccent,
                size: 20,
              );
            },
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
              extended
                  ? TextButton.icon(
                      onPressed: () => context.go('/about'),
                      icon: const Icon(
                        Icons.info_outline,
                        color: Colors.white70,
                      ),
                      label: Text(
                        'Sobre o App',
                        style: Theme.of(context).textTheme.bodySmall,
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

              const Divider(color: Colors.white24, height: 16, thickness: 1),

              extended
                  ? TextButton.icon(
                      onPressed: () => confirmLogout(),
                      icon: const Icon(Icons.logout, color: Colors.redAccent),
                      label: Text(
                        'Sair do App',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

  // ==========================================
  void _onItemTapped(
    String routeName, {
    required bool isMobile,
    Map<String, String>? queryParameters,
    Object? extra,
  }) {
    if (isMobile) {
      Navigator.pop(context);
    }

    context.goNamed(
      routeName,
      queryParameters: queryParameters ?? const {},
      extra: extra,
    );
  }

  // ==========================================
  Widget buildNameEmail(String nome, String email) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => context.go('/profile_screen'),
          child: Text(
            nome,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => context.go('/profile_screen'),
          child: Text(
            email,
            style: Theme.of(context).textTheme.bodySmall,
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
                try {
                  await paymentService.selecionarAnexoEEnviar(
                    context: context,
                    payload: {
                      'pfl_id': pfl_id,
                      'hld_id': hld_id,
                    },
                    isDocumentoOuComprovanteLocal: false,
                  );
                  // Atualiza perfil após alterar avatar
                  await bdProfileController.fetchProfilesById(pfl_id, hld_id);
                } catch (e) {
                  if (mounted) {
                    _exibirSnackBarErro('Erro ao atualizar imagem de perfil.');
                  }
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
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