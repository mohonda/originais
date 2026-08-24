import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gorouter_exemplo/models/custom_app_bar.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

// Modelo simples para concentrar os dados dinâmicos do app
class AppSystemDetails {
  final String version;
  final String buildNumber;
  final String platform;

  AppSystemDetails({
    required this.version,
    required this.buildNumber,
    required this.platform,
  });

  static Future<AppSystemDetails> fetch() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final platformName = kIsWeb
        ? 'Web Browser'
        : defaultTargetPlatform.name.toUpperCase();

    return AppSystemDetails(
      version: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
      platform: platformName,
    );
  }
}

class About extends StatefulWidget {
  const About({super.key});

  @override
  State<About> createState() => _AboutState();
}

class _AboutState extends State<About> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // ==========================================
  @override
  void initState() {

    // Configuração do controlador da animação
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _startLoopAnimation();
    
    super.initState();
  }

  // ==========================================
  void _startLoopAnimation() async {
    _controller.forward();

    _controller.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        await Future.delayed(const Duration(seconds: 6));
        if (!mounted) return;
        _controller.reset();
        _controller.forward();
      }
    });
  }

  // ==========================================
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomFloatingAppBar(title: 'About'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          // 1. LayoutBuilder obtém a altura total disponível na tela
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    // 2. Garante altura mínima igual à tela para manter centralizado
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 20.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 1. Logo Animada
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Image.asset(
                                'lib/assets/images/logo.png',
                                height:
                                    180, // Ajustado de 240 para 180 para melhor encaixe em telas pequenas
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.motorcycle,
                                      size: 80,
                                      color: Colors.grey,
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 2. Título do Aplicativo com ®
                          RichText(
                            textAlign: TextAlign.center,
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              children: [
                                TextSpan(text: 'Originais Moto Clube '),
                                TextSpan(
                                  text: '®',
                                  style: TextStyle(fontSize: 22),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),

                          // 3. Descrição do Projeto
                          Text(
                            'Originais Sempre, Sempre Originais',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Orgulho Em Pertencer 100',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'LIBERDADE, IGUALDADE E IRMANDADE',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),

                          InkWell(
                            onTap: _abrirInstagram,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 6.0,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.camera_alt,
                                    size: 18,
                                    color: Colors.pink,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '@originaismc',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                      decoration: TextDecoration.underline,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),

                          // 4. Detalhes do Sistema
                          FutureBuilder<AppSystemDetails>(
                            future: AppSystemDetails.fetch(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const CircularProgressIndicator.adaptive();
                              }

                              final info = snapshot.data;
                              final versionText = info != null
                                  ? '${info.version} (${info.buildNumber})'
                                  : '1.0.0';
                              final platformText = info?.platform ?? 'N/A';

                              return Column(
                                children: [
                                  _buildInfoRow('Software de Gestão', ""),
                                  const SizedBox(height: 3),
                                  _buildInfoRow('Versão:', versionText),
                                  const SizedBox(height: 3),
                                  _buildInfoRow('Backend Supabase:', 'v2.x'),
                                  const SizedBox(height: 3),
                                  _buildInfoRow('Plataforma:', platformText),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 16),

                          // 5. Rodapé do Desenvolvedor / Copyright
                          Text(
                            'Desenvolvido por mohonda.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[400],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '© 2026 Originais Moto Clube. Todos os direitos reservados.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[400],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ==========================================
  // Helper para criar as linhas de informação padronizadas
  Widget _buildInfoRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$title ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.white,
          ),
        ),
        Text(value, style: const TextStyle(fontSize: 13, color: Colors.white)),
      ],
    );
  }

  // ==========================================
  Future<void> _abrirInstagram() async {
    final Uri url = Uri.parse('https://www.instagram.com/originaismc');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Não foi possível abrir o link $url');
    }
  }
}
