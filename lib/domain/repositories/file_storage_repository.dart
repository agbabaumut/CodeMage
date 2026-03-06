import 'dart:typed_data';
import '../entities/processing_type.dart';

class SavedPaths {
  final String originalPath;
  final String processedPath;
  final String thumbnailPath;
  final String? pdfPath;

  const SavedPaths({
    required this.originalPath,
    required this.processedPath,
    required this.thumbnailPath,
    this.pdfPath,
  });
}

abstract class FileStorageRepository {
  Future<SavedPaths> saveProcessedImage({
    required Uint8List processedBytes,
    required Uint8List originalBytes,
    required ProcessingType type,
  });

  Future<SavedPaths> saveDocumentResult({
    required Uint8List processedBytes,
    required Uint8List originalBytes,
    required Uint8List pdfBytes,
  });

  Future<void> deleteFiles(String originalPath, String processedPath,
      String thumbnailPath, String? pdfPath);

  Future<String> get baseDirectory;
}
