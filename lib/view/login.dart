import 'package:flutter/material.dart';
import 'package:originais/controllers/login_controller.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  LoginState createState() => LoginState();
}

class LoginState extends State with SingleTickerProviderStateMixin {
  final LoginController loginController = LoginController();

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _senhaFocusNode = FocusNode();

  // ==========================================
  @override
  void initState() {
    loginController.carregarPreferencias();

    // Define a duração total da animação para 1.5 segundos
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Animação de Opacidade (de 0.0 invisível para 1.0 visível)
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // Animação de Movimento (de um pouco mais acima para a posição original)
    _slideAnimation = Tween(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    // Inicia a animação assim que a tela abre
        _startLoopAnimation();

    super.initState();
  }

  // ==========================================
  @override
  void dispose() {
    _controller.dispose();
    _emailFocusNode.dispose();
    _senhaFocusNode.dispose();
    super.dispose();
  }
    
  // ==========================================
  void _startLoopAnimation() async {
    _controller.forward();

    _controller.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        await Future.delayed(const Duration(seconds: 4));
        if (!mounted) return;
        _controller.reset();
        _controller.forward();
      }
    });
  }

  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 500,
          height: 820,
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                const SizedBox(height: 40),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Image.asset(
                      'lib/assets/images/logo.png',
                      height: 240,
                    ),
                  ),
                ),

                const SizedBox(height: 40),
                Text(
                  'Welcome',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Sign in to continue to your account',
                  style: Theme.of(context).textTheme.bodySmall,
                ),

                const SizedBox(height: 24),
                TextField(
                  controller: loginController.emailController,
                  
                  focusNode: _emailFocusNode, 
                  autofocus: 
                    loginController.emailController
                      .text.trim().isNotEmpty,
                  onSubmitted: (_) => _senhaFocusNode
                      .requestFocus(),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.mail_outline),
                    border: OutlineInputBorder(),
                    labelStyle: Theme.of(context).textTheme.bodyMedium
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

                const SizedBox(height: 16),
                ValueListenableBuilder<bool>(
                  valueListenable: loginController.obscureNotifier,
                  builder: (context, isObscure, child) {
                    return TextField(
                      controller: loginController.senhaController,
                      focusNode: _senhaFocusNode,
                       autofocus: 
                        loginController.emailController
                          .text.trim().isNotEmpty,
                      obscureText: isObscure,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) =>
                          loginController.submeter(false, context),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: Theme.of(context).textTheme.bodyMedium,
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isObscure ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () =>
                              loginController.obscureNotifier.value =
                                  !isObscure,
                        ),
                      ),
                    );
                  },
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        ValueListenableBuilder<bool>(
                          valueListenable: loginController
                            .rememberNotifier,
                          builder: (context, isRemember, child) {
                            return Checkbox(
                              value: isRemember,
                              onChanged: (v) =>
                                  loginController
                                    .rememberNotifier.value =
                                     v ?? false,
                            );
                          },
                        ),
                        Text(
                          'Remember me',
                          // tex labelStyle: Theme.of(context).textTheme.bodyMedium
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Forgot password?',
                        // style: Theme.of(context).textTheme.bodySmall,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.blueAccent,
                                      fontWeight: FontWeight.w500,
                                    ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                ValueListenableBuilder<bool>(
                  valueListenable: loginController.isLoadingNotifier,
                  builder: (context, isLoading, child) {
                    return Column(
                      children: [
                        SizedBox(
                          height: 52,
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: isLoading
                                ? null
                                : () =>
                                      loginController
                                        .submeter(false, context),
                            child: isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Sign in',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account?",
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontSize: 14.0,
                              )
                            ),
                            TextButton(
                              onPressed: (){},
                              // onPressed: isLoading
                              //     ? null
                              //     : () =>
                              //           loginController
                              //             .submeter(true, context),
                              child: Text(
                                'Sign up',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                 fontSize: 14.0,
                                 color: Colors.blueAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
