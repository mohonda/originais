import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gorouter_exemplo/models/custom_app_bar.dart';

class About extends StatelessWidget {
  const About({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomFloatingAppBar(title: 'About'),
      body: Padding(
        padding: const EdgeInsets.only(
          left: 8.0,
          right: 8.0,
          top: 16.0,
          bottom: 16.0,
        ),
        child: SizedBox.expand(
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 8.0,
                right: 8.0,
                top: 16.0,
                bottom: 16.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sobre o Aplicativo',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Versão 1.0.0\nDesenvolvido com Flutter.',
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: () => context.go('/dashboard'),
                    child: const Text('Voltar para Home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
