import 'package:flutter/material.dart';
import 'package:gorouter_exemplo/view/dashboard_widgetItens.dart';
import 'package:gorouter_exemplo/view/dashboard_widgetUsers.dart';
import 'package:gorouter_exemplo/view/monthly_payments.dart';
import 'package:gorouter_exemplo/models/custom_app_bar.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _Dashboard();
}

class _Dashboard extends State<Dashboard> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomFloatingAppBar(title: 'Dashboard'),
      body: Padding(
        padding: const EdgeInsets.only(
          left: 8.0,
          right: 8.0,
          top: 16.0,
          bottom: 16.0,
        ),
        child: SizedBox.expand(
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWideScreen = constraints.maxWidth > 800;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: isWideScreen ? 4 : 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: isWideScreen ? 1.8 : 1.3,
                          children: const [
                            DashboardWidgetUsers(),
                            DashboardWidgetItens(),
                            
                          ],
                        ),

                        const SizedBox(height: 24),
                        

                        const SizedBox(
                          height: 350,
                          child: MonthlyPayments()
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
