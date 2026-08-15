import 'package:intl/intl.dart';

class GeneralService {
  String formatarDataBr(String dataIso) {
    if (dataIso.isEmpty) {
      return '';
    }
    try {
      final data = DateTime.parse(dataIso);
      final dia = data.day.toString().padLeft(2, '0');
      final mes = data.month.toString().padLeft(2, '0');
      return '$dia/$mes/${data.year}';
    } catch (_) {
      return dataIso;
    }
  }

  String currencyMoneyBr(String valor) {
    String valorLimpo = valor.replaceAll(',', '.');

    final double valorDouble = double.tryParse(valorLimpo) ?? 0.0;

    final String tmp = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$ ',
    ).format(valorDouble);

    return tmp;
  }

}
