import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gorouter_exemplo/models/mensalidades_model.dart';
import 'dart:typed_data';
import 'package:gorouter_exemplo/services/general_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gorouter_exemplo/services/my_supabase_client_service.dart';

final getItbdMonthlyPaymentsController = GetIt.instance;

void setupGetItBdMonthlyPaymentsController() {
  getItbdMonthlyPaymentsController
      .registerLazySingleton<BdMonthlyPaymentsController>(
        () => BdMonthlyPaymentsController(),
      );
}

class BdMonthlyPaymentsController extends ChangeNotifier {
  final mySupabaseClient = getItMySupabaseClient<MySupabaseClient>();
  late SupabaseClient supabaseClient;

  final ValueNotifier<List<MensalidadesModel>> monthlyPaymentsNotifier =
      ValueNotifier<List<MensalidadesModel>>([]);

  final ValueNotifier<MensalidadesModel?> monthlyPaymentsIndividual =
      ValueNotifier<MensalidadesModel?>(null);

  final ValueNotifier<bool> loadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);

  final generalService = getItGeneralService<GeneralService>();

  // ==========================================
  BdMonthlyPaymentsController() {
    supabaseClient = mySupabaseClient.getSupabaseClient();
  }
    // ==========================================
  Future<void> loadCurrentMonthlyPayment() async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final String month = DateTime.now().month.toString().padLeft(2, '0');
      final String year = DateTime.now().year.toString();

      final resposta = await supabaseClient
        .from('vmensalidades')
        .select()
        .eq('mes_referencia', month)
        .eq('ano_referencia', year);

      monthlyPaymentsNotifier.value = 
          resposta.map((item) =>
          MensalidadesModel.fromJson(item)).toList();

    } catch (e, stackTrace) {
      monthlyPaymentsNotifier.value = [];
      debugPrint("BdMonthlyPaymentsController::loadCurrentMonthlyPayment: $e\n$stackTrace");
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> loadMonthlyPaymentsIndividual(
    String id,
    String month,
    String year,
  ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;
      
      final resposta = await supabaseClient
          .from('vmensalidades')
          .select()
          .eq('id', id)
          .eq('mes_referencia', month)
          .eq('ano_referencia', year)
          .single();

      monthlyPaymentsIndividual.value =
        MensalidadesModel.fromJson(resposta);

    } catch (e, stackTrace) {
      monthlyPaymentsIndividual.value = null;
      errorNotifier.value = 'BdMonthlyPaymentsController::loadMonthlyPaymentsIndividual:  $e\n$stackTrace';
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  Future<void> updateCheckingCopy(
    String id,
    String mesReferencia,
    String anoReferencia,
    String comprovantePag,
  ) async {
    try {
      loadingNotifier.value = true;
      errorNotifier.value = null;

      final resposta = await supabaseClient
        .from('mensalidades')
        .update({'comprovante_pag': comprovantePag})
        .eq('mes_referencia', mesReferencia)
        .eq('ano_referencia', anoReferencia)
        .eq('id', id)
        .select()
        .single();
        
        monthlyPaymentsIndividual.value = MensalidadesModel.fromJson( resposta );
    } catch (e, stackTrace) {
      monthlyPaymentsIndividual.value = null;
      errorNotifier.value = 'BdMonthlyPaymentsController::loadMonthlyPaymentsIndividual:  $e\n$stackTrace';
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ==========================================
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

      String dataSupabase = generalService.date2Supabase( datapagamento.toString() );
      String valorSupabase = generalService.value2Supabase( valor.toString() );

      final resposta = await supabaseClient
        .from('mensalidades')
        .update({
          'valor': valorSupabase,
          'data_pagamento': dataSupabase,
          'forma_pagamento': formapagamento,
        })
        .eq('mes_referencia', mes)
        .eq('ano_referencia', ano)
        .eq('id', id )
        .select()
        .single();

      monthlyPaymentsIndividual.value = MensalidadesModel.fromJson( resposta );

    } catch (e, stackTrace) {
      monthlyPaymentsIndividual.value = null;
      errorNotifier.value = 'BdMonthlyPaymentsController::loadMonthlyPaymentsIndividual:  $e\n$stackTrace';
    } finally {
      loadCurrentMonthlyPayment();
      loadingNotifier.value = false;
    }
  }

  // ==========================================
  // ==========================================
  // ==========================================
  // ==========================================
  Future selecionarEEnviarFoto(String id, String mes, String ano) async {
  try {
      final isLinux = !kIsWeb && Platform.isLinux;
      final isWebOrLinux = kIsWeb || isLinux;
      
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'tiff', 'pdf'],
        allowMultiple: false,
        withData:
            true, // Garante que 'file.bytes' não venha nulo no Android/iOS/Desktop
      );

      if (result == null || result.files.isEmpty) return;

      loadingNotifier.value = true;
      errorNotifier.value = null;

      final PlatformFile file = result.files.single;
      final String ext = file.extension?.toLowerCase() ?? '';
      final Uint8List? rawBytes = file.bytes;
      Uint8List? compressedBytes;

      if (rawBytes == null) {
        debugPrint('Erro: Os bytes do arquivo não puderam ser carregados.');
        return;
      }

      // ==========================================
      // Lógica: PDF ou Imagem
      // ==========================================
      if (ext == 'pdf') {
        Uint8List? rawImageBytes;

        try {
          await for (final page in Printing.raster(
            rawBytes,
            pages: [0],
            dpi: 200,
          )) {
            rawImageBytes = await page.toPng();
            break; // Pega apenas a primeira página
          }
        } catch (e) {
          debugPrint('Erro ao processar PDF: $e');
          return;
        }

        if (rawImageBytes == null) {
          debugPrint('Erro: Falha ao converter o PDF em imagem.');
          return;
        }

        compressedBytes = await _compressImageBytes(rawImageBytes, isLinux );
      } else {
        compressedBytes = await _compressImageBytes(rawBytes, isLinux);
      }

      // ==========================================
      // Upload para o Supabase
      // ==========================================
      if (compressedBytes == null) {
        debugPrint('Erro: Não foi possível comprimir o arquivo final.');
        return;
      }

      final fileExt = isWebOrLinux ? 'jpg' : 'webp';
      final mimeType = isWebOrLinux ? 'image/jpeg' : 'image/webp';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '$id/${ano}_${mes}_monthlypayments_$timestamp.$fileExt';

      await supabaseClient.storage
          .from('monthypayments')
          .uploadBinary(
            filePath,
            compressedBytes,
            fileOptions: FileOptions(upsert: true, contentType: mimeType),
          );

      final imageUrl = supabaseClient.storage
          .from('monthypayments')
          .getPublicUrl(filePath);

      // Salva a URL no perfil do banco de dados
      await updateCheckingCopy(id, mes, ano, imageUrl);
      } catch ( e, stackTrace ) {
      monthlyPaymentsIndividual.value = null;
      errorNotifier.value = "BdProfileController::selecionarEEnviarFoto: $e \n$stackTrace";
    } finally {
      loadingNotifier.value = false;
    }    
  }

  // ==========================================
  // Compressor Baseado em Bytes (Memória)
  // ==========================================
  Future<Uint8List?> _compressImageBytes(Uint8List bytes, bool isLinux) async {
    if ( isLinux ) {
      // Tratamento puro em Dart para Linux
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) return null;

      final resizedImage = img.copyResize(
        decodedImage,
        width: decodedImage.width > 800 ? 800 : decodedImage.width,
        maintainAspect: true,
      );

      return Uint8List.fromList(
        img.encodeJpg(
          resizedImage,
          quality: 60
      ));
    }
    return await FlutterImageCompress.compressWithList(
      bytes, // Repare que usamos compressWithList em vez de compressWithFile
      quality: 60,
      minWidth: 800,
      minHeight: 800,
      format: CompressFormat.webp,
    );
  }

}
