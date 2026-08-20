import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gorouter_exemplo/controllers/bd_journeyriding_controller.dart';

class DashboardWidgetItens extends StatefulWidget {
  const DashboardWidgetItens({super.key});

  // ==========================================
  @override
  State<DashboardWidgetItens> createState() => _DashboardWidgetItens();
}

class _DashboardWidgetItens extends State<DashboardWidgetItens> {

  // ==========================================
  @override
  Widget build(BuildContext context) {
    final bdItemController = getItBdJourneyRidingController<BdJourneyRidingController>();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12)
      ),
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
                  'Total de Itens',
                  style: TextStyle(
                    color: Colors.grey[600]
                  ),
                ),
                const Icon(
                  Icons.verified_user,
                  color: Colors.green
                ),
              ],
            ),

            ValueListenableBuilder<bool>(
              valueListenable: bdItemController.loadingNotifier,
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
                  valueListenable: bdItemController.bdJourneyRidingNotifier,
                  builder: (context, itens, child) {
                    return GestureDetector(
                      onTap: () {
                        context.go('/itens');
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
