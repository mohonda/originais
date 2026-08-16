import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';

final getItGeneralService = GetIt.instance;

void setupGetItGeneralService() {
  getItGeneralService
      .registerLazySingleton<GeneralService>(
        () => GeneralService(),
      );
}

class GeneralService {
  
  // ==========================================
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

  // ==========================================
  String currencyMoneyBr(String valor) {
    String valorLimpo = valor.replaceAll(',', '.');

    final double valorDouble = double.tryParse(valorLimpo) ?? 0.0;

    final String tmp = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$ ',
    ).format(valorDouble);

    return tmp;
  }

  // ==========================================
  String date2Supabase( String dateBrasil ) {
    if (dateBrasil.isEmpty) return "";

    // Divide a string onde tem a barra '/'
    final partes = dateBrasil.split('/');

    // Se estiver no formato esperado (3 partes: DD, MM, YYYY)
    if (partes.length == 3) {
      final dia = partes[0];
      final mes = partes[1];
      final ano = partes[2];

      return "$ano-$mes-$dia"; // Retorna no padrão do Supabase
    }

    // Se por acaso já vier formatado ou fora do padrão, retorna como está
    return dateBrasil;
  }

  // ==========================================
  String value2Supabase( String valueBrasil ) {
    return valueBrasil.replaceAll('.', '').replaceAll(',', '.');
  }

}
