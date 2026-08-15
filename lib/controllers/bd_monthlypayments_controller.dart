import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gorouter_exemplo/models/mensalidades_model.dart';
import 'package:gorouter_exemplo/services/bd_monthlypayments_service.dart';


final getItbdMonthlyPaymentsController = GetIt.instance;

void setupGetItBdMonthlyPaymentsController() {
  getItbdMonthlyPaymentsController
      .registerLazySingleton<BdMonthlyPaymentsController>(
        () => BdMonthlyPaymentsController(),
      );
}

class BdMonthlyPaymentsController extends ChangeNotifier {
  final BdMonthlyPaymentsService bdMonthlyPaymentsService =
      BdMonthlyPaymentsService();

  final ValueNotifier<List<MensalidadesModel>> monthlyPaymentsNotifier =
      ValueNotifier<List<MensalidadesModel>>([]);

  final ValueNotifier<List<MensalidadesModel>> paidNotifier =
      ValueNotifier<List<MensalidadesModel>>([]);
  final ValueNotifier<List<MensalidadesModel>> npaidNotifier =
      ValueNotifier<List<MensalidadesModel>>([]);

  final ValueNotifier<MensalidadesModel?> monthlyPaymentsIndividual =
      ValueNotifier<MensalidadesModel?>(null);

  final ValueNotifier<bool> loadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<bool> isChangedNotifier = ValueNotifier<bool>(false);

  void changedNotifier(bool value) {
    isChangedNotifier.value = value;
  }

  Future<void> loadCurrentMonthlyPayment() async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      String month = DateTime.now().month.toString();
      String year = DateTime.now().year.toString();

      monthlyPaymentsNotifier.value = await bdMonthlyPaymentsService
          .loadCurrentMonthlyPayment(month, year);
    } catch (e) {
      monthlyPaymentsNotifier.value = ([]);
      paidNotifier.value = ([]);
      npaidNotifier.value = ([]);
      errorNotifier.value = 'BdMonthlyPaymentsController::loadProfiles: $e';
    } finally {
      loadingNotifier.value = false;
    }
  }

  Future<void> loadMonthlyPaymentsIndividual(
    String id,
    String month,
    String year,
  ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      monthlyPaymentsIndividual.value = await bdMonthlyPaymentsService
          .loadMonthlyPaymentsIndividual(id, month, year);
    } catch (e) {
      monthlyPaymentsIndividual.value = null;
      errorNotifier.value = 'BdMonthlyPaymentsController::loadProfiles: $e';
    } finally {
      loadingNotifier.value = false;
    }
  }

  Future selecionarEEnviarFoto(String id, String mes, String ano) async {
    final supabase = Supabase.instance.client;

    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'tiff', 'pdf'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    final PlatformFile file = result.files.single;
    if (file.path == null) return;

    final String ext = file.extension?.toLowerCase() ?? '';
    Uint8List? compressedBytes;

    // ==========================================
    // Lógica: PDF ou Imagem
    // ==========================================
    if (ext == 'pdf') {
      final pdfBytes = await File(file.path!).readAsBytes();
      Uint8List? rawImageBytes;

      await for (final page in
        Printing.raster(
          pdfBytes,
          pages: [0],
          dpi: 200,
        )
      )
      {
        rawImageBytes = await page.toPng();
        break; // Pega apenas a primeira página e sai do loop
      }

      if (rawImageBytes == null) {
        debugPrint('Erro: Falha ao converter o PDF em imagem.');
        return;
      }

      // 3. Comprime os bytes gerados pelo PDF
      compressedBytes = await _compressImageBytes(rawImageBytes);
    } else {
      debugPrint('Imagem detectada: ${file.path}');
      // 3. Lê o arquivo de imagem e comprime
      final imageBytes = await File(file.path!).readAsBytes();
      compressedBytes = await _compressImageBytes(imageBytes);
    }

    // ==========================================
    // Upload para o Supabase
    // ==========================================
    if (compressedBytes == null) {
      debugPrint('Erro: Não foi possível comprimir o arquivo final.');
      return;
    }

    final isLinux = Platform.isLinux;
    final fileExt = isLinux ? 'jpg' : 'webp';
    final mimeType = isLinux ? 'image/jpeg' : 'image/webp';
    final timestamp = DateTime.now();
    final filePath = '$id/${ano}_${mes}_monthlypayments_$timestamp.$fileExt';

    supabase.storage
        .from('monthypayments')
        .uploadBinary(
          filePath,
          compressedBytes,
          fileOptions: FileOptions(upsert: true, contentType: mimeType),
        );

    final imageUrl = supabase.storage
        .from('monthypayments')
        .getPublicUrl(filePath);

    // Salva a URL no perfil do banco de dados
    updateComprovante(id, mes, ano, imageUrl);
  }

  // ==========================================
  // Compressor Baseado em Bytes (Memória)
  // ==========================================
  Future<Uint8List?> _compressImageBytes(Uint8List bytes) async {
    if (Platform.isLinux) {
      // Tratamento puro em Dart para Linux
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) return null;

      final resizedImage = img.copyResize(
        decodedImage,
        width: decodedImage.width > 1080 ? 1080 : decodedImage.width,
        maintainAspect: true,
      );

      return Uint8List.fromList(img.encodeJpg(resizedImage, quality: 70));
    }
    return await FlutterImageCompress.compressWithList(
      bytes, // Repare que usamos compressWithList em vez de compressWithFile
      quality: 70,
      minWidth: 1080,
      minHeight: 1080,
      format: CompressFormat.webp,
    );
  }

  Future<void> updateComprovante(
    String id,
    String mes,
    String ano,
    String avatarUrl,
  ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      await bdMonthlyPaymentsService.updateComprovante(id, mes, ano, avatarUrl);
      // await loadMonthlyPaymentsIndividual( id, mes, ano );
      
    } catch (e) {
      monthlyPaymentsIndividual.value = null;
      errorNotifier.value = 'BdProfileController::updateComprovante: $e';
    } finally {
      monthlyPaymentsIndividual.value = await bdMonthlyPaymentsService
          .loadMonthlyPaymentsIndividual(id, mes, ano);
      loadingNotifier.value = false;
    }
  }

  Future<void> updatePaymentsProfile(
    String id,
    String mes,
    String ano,
    String valor,
    String datapagamento,
    String formapagamento,
  ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      String dataSupabase = formatarDataParaSupabase(datapagamento.toString());
      String valorSupabase = valor.replaceAll('.', '').replaceAll(',', '.');

      await bdMonthlyPaymentsService.updatePaymentsProfile(
        id,
        mes,
        ano,
        valorSupabase,
        dataSupabase,
        formapagamento,
      );
    } catch (e) {
      monthlyPaymentsIndividual.value = null;
      errorNotifier.value = 'BdProfileController::updatePaymentsProfile: $e';
    } finally {
      loadMonthlyPaymentsIndividual(id, mes, ano);
      loadCurrentMonthlyPayment();
      loadingNotifier.value = false;
    }
  }

  String formatarDataParaSupabase(String dataBrasil) {
    if (dataBrasil.isEmpty) return "";

    // Divide a string onde tem a barra '/'
    final partes = dataBrasil.split('/');

    // Se estiver no formato esperado (3 partes: DD, MM, YYYY)
    if (partes.length == 3) {
      final dia = partes[0];
      final mes = partes[1];
      final ano = partes[2];

      return "$ano-$mes-$dia"; // Retorna no padrão do Supabase
    }

    // Se por acaso já vier formatado ou fora do padrão, retorna como está
    return dataBrasil;
  }
}
