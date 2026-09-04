import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';

class ProcessedImageData {
  final Uint8List bytes;
  final String extension;
  final String mimeType;

  ProcessedImageData({
    required this.bytes,
    required this.extension,
    required this.mimeType,
  });
}

enum _SourceType { camera, file }

abstract class BaseImageUploadService {
  final ValueNotifier<bool> loadingNotifier;
  final ValueNotifier<String?> errorNotifier;

  BaseImageUploadService({
    required this.loadingNotifier,
    required this.errorNotifier,
  });

  bool isDocumentoOuComprovante = true;

  // ===========================================================================
  // MÉTODOS ABSTRATOS (Devem ser implementados pelas classes filhas)
  // ===========================================================================
  
  /// Define como e onde salvar o arquivo no Supabase Storage
  @protected
  Future<String> fazerUploadStorage(
    ProcessedImageData imageData, 
    Map<String, dynamic>? payload,
  );

  /// Define qual tabela e colunas atualizar com a URL do arquivo
  @protected
  Future<void> atualizarBancoDados(
    String imageUrl, 
    Map<String, dynamic>? payload,
  );

  // ===========================================================================
  // MÉTODOS REUTILIZÁVEIS (Lógica comum para todo o sistema)
  // ===========================================================================

  /// Orquestra a interface e o fluxo completo de carregamento e envio
  Future<void> selecionarAnexoEEnviar({
    required BuildContext context,
    Map<String, dynamic>? payload,
    bool isDocumentoOuComprovanteLocal = true,
  }) async {
    isDocumentoOuComprovante = isDocumentoOuComprovanteLocal;

    final bool isCameraReady =
        kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

    final _SourceType? selectedSource = await showModalBottomSheet<_SourceType>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              if (isCameraReady)
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.indigo),
                  title: const Text('Tirar Foto'),
                  onTap: () => Navigator.of(bc).pop(_SourceType.camera),
                ),
              ListTile(
                leading: const Icon(Icons.folder, color: Colors.indigo),
                title: const Text('Escolher Arquivo (PDF ou Galeria)'),
                onTap: () => Navigator.of(bc).pop(_SourceType.file),
              ),
            ],
          ),
        );
      },
    );

    if (selectedSource == null) return;

    ProcessedImageData? imageData;
    if (selectedSource == _SourceType.camera) {
      imageData = await loadCamera();
    } else if (selectedSource == _SourceType.file) {
      imageData = await loadFile();
    }

    if (imageData != null) {
      try {
        loadingNotifier.value = true;
        errorNotifier.value = null;
        debugPrint('aqui....');

        // Executa os métodos especializados da classe filha
        final imageUrl = await fazerUploadStorage(imageData, payload);
        await atualizarBancoDados(imageUrl, payload);
      } catch (e, stackTrace) {
        errorNotifier.value = "${runtimeType}::selecionarAnexoEEnviar: $e \n$stackTrace";
      } finally {
        loadingNotifier.value = false;
      }
    }
  }

  Future<ProcessedImageData?> loadFile() async {
    try {
      final isLinux = !kIsWeb && Platform.isLinux;
      final isWebOrLinux = kIsWeb || isLinux;

       List<PlatformFile> result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'tiff', 'pdf'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.isEmpty) return null;

      loadingNotifier.value = true;
      errorNotifier.value = null;

      final PlatformFile file = result.first;
      final String ext = file.extension?.toLowerCase() ?? '';
      final Uint8List? rawBytes = await file.readAsBytes();

      if (rawBytes == null || rawBytes.isEmpty) {
        throw Exception('Os bytes do arquivo não puderam ser carregados.');
      }

      Uint8List? compressedBytes;

      if (ext == 'pdf') {
        Uint8List? rawImageBytes;
        try {
          await for (final page in Printing.raster(
            rawBytes,
            pages: [0],
            dpi: 200,
          )) {
            rawImageBytes = await page.toPng();
            break;
          }
        } catch (e) {
          throw Exception('Erro ao processar arquivo PDF: $e');
        }

        if (rawImageBytes == null) {
          throw Exception('Falha ao converter a página do PDF em imagem.');
        }

        compressedBytes = await _compressImageBytes(rawImageBytes, isWebOrLinux);
      } else {
        compressedBytes = await _compressImageBytes(rawBytes, isWebOrLinux);
      }

      if (compressedBytes == null) {
        throw Exception('Não foi possível comprimir a imagem final.');
      }

      final String fileExt = isWebOrLinux ? 'jpg' : 'webp';
      final String mimeType = isWebOrLinux ? 'image/jpeg' : 'image/webp';

      return ProcessedImageData(
        bytes: compressedBytes,
        extension: fileExt,
        mimeType: mimeType,
      );
    } catch (e, stackTrace) {
      errorNotifier.value = "${runtimeType}::loadFile: $e \n$stackTrace";
      return null;
    } finally {
      loadingNotifier.value = false;
    }
  }

  Future<ProcessedImageData?> loadCamera() async {
    try {
      final isLinux = !kIsWeb && Platform.isLinux;
      final isWebOrLinux = kIsWeb || isLinux;

      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1024,
      );

      if (photo == null) return null;

      loadingNotifier.value = true;
      errorNotifier.value = null;

      final Uint8List photoBytes = await photo.readAsBytes();

      final compressedBytes = await _compressImageBytes(photoBytes, isWebOrLinux);

      if (compressedBytes == null) {
        throw Exception('Não foi possível comprimir a imagem final.');
      }

      final String finalExt = isWebOrLinux ? 'jpg' : 'webp';
      final String finalMimeType = isWebOrLinux ? 'image/jpeg' : 'image/webp';

      return ProcessedImageData(
        bytes: compressedBytes,
        extension: finalExt,
        mimeType: finalMimeType,
      );
    } catch (e, stackTrace) {
      errorNotifier.value = "${runtimeType}::loadCamera: $e \n$stackTrace";
      return null;
    } finally {
      loadingNotifier.value = false;
    }
  }

  Future<Uint8List?> _compressImageBytes(
    Uint8List bytes,
    bool useDartImage
    ) async {
    if (useDartImage) {
      var decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) return null;

      if (isDocumentoOuComprovante) {
        decodedImage = img.grayscale(decodedImage);
      }

      final resizedImage = img.copyResize(
        decodedImage,
        width: decodedImage.width > 700 ? 700 : decodedImage.width,
      );

      return Uint8List.fromList(
        img.encodeJpg(resizedImage, quality: 45),
      );
    }

    return await FlutterImageCompress.compressWithList(
      bytes,
      quality: 45,
      minWidth: 700,
      minHeight: 700,
      format: CompressFormat.webp,
    );
  }
}