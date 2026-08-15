import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gorouter_exemplo/controllers/bd_profile_controller.dart';

class DashboardWidgetUsers extends StatefulWidget {
  const DashboardWidgetUsers({super.key});

  @override
  State<DashboardWidgetUsers> createState() => _DashboardWidgetUsers();
}

class _DashboardWidgetUsers extends State<DashboardWidgetUsers> {
  @override
  Widget build(BuildContext context) {
    final bdProfileController = getItBdProfileController<BdProfileController>();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total de Usuários',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const Icon(Icons.verified_user, color: Colors.green),
              ],
            ),

            ValueListenableBuilder<bool>(
              valueListenable: bdProfileController.loadingNotifier,
              builder: (context, isLoading, child) {
                if (isLoading) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                return ValueListenableBuilder<List<dynamic>>(
                  valueListenable: bdProfileController.profilesNotifier,
                  builder: (context, itens, child) {
                    return GestureDetector(
                      onTap: () {
                        context.go('/profile_screen');
                      },
                      child: Text(
                        itens.length.toString(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
