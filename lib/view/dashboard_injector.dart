import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get_it/get_it.dart';

final getItDashboardNotifier = GetIt.instance;

void setupGetItDashboardNotifier() {
  getItDashboardNotifier.registerLazySingleton<DashboardNotifier>(() => DashboardNotifier());
}

class DashboardNotifier extends StatefulWidget {
  const DashboardNotifier({super.key});

  @override
  State<DashboardNotifier> createState() => _DashboardNotifier();
}

class _DashboardNotifier extends State<DashboardNotifier> {
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  List<FlSpot> _salesChartData = [
    const FlSpot(1, 2.5),
    const FlSpot(2, 1.8),
    const FlSpot(3, 4.0),
    const FlSpot(4, 3.2),
    const FlSpot(5, 5.5),
    const FlSpot(6, 4.8),
    const FlSpot(7, 7.0),
  ];
  
  List<FlSpot> get salesChartData => _salesChartData;

  @override
  Widget build(BuildContext context) {
  // Pontos (X, Y) para o gráfico da fl_chart
    // return salesChartData;
  return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
      ),
  );
  }

  // Simula uma requisição de API / Banco de dados para atualizar a tela
  Future<void> refreshData() async {
    _isLoading = true;
    // notifyListeners();

    await Future.delayed(const Duration(seconds: 1)); // Simula delay da rede

    // Novos dados simulados
    _salesChartData = [
      const FlSpot(1, 3.0),
      const FlSpot(2, 2.2),
      const FlSpot(3, 5.1),
      const FlSpot(4, 4.0),
      const FlSpot(5, 6.8),
      const FlSpot(6, 5.5),
      const FlSpot(7, 8.5),
    ];

    _isLoading = false;
    // notifyListeners(); // Notifica os widgets ouvintes
  }
}
