import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/storage_paths.dart';
import '../../../core/utils/file_utils.dart';
import '../../../core/utils/image_utils.dart';
import '../../../domain/entities/processing_type.dart';
import '../../../domain/repositories/file_storage_repository.dart';

class FileStorageServiceImpl implements FileStorageRepository {
  String? _baseDirPath;

  @override
  Future<String> get baseDirectory async {
    if (_baseDirPath != null) return _baseDirPath!;
    final appDir = await getApplicationDocumentsDirectory();
    _baseDirPath = '${appDir.path}/${StoragePaths.baseDir}';
    return _baseDirPath!;
  }

  Future<void> _ensureDirectories() async {
    final base = await baseDirectory;
    await FileUtils.ensureDirectory('$base/${StoragePaths.originals}');
    await FileUtils.ensureDirectory('$base/${StoragePaths.processedFaces}');
    await FileUtils.ensureDirectory('$base/${StoragePaths.processedDocuments}');
    await FileUtils.ensureDirectory('$base/${StoragePaths.pdfs}');
    await FileUtils.ensureDirectory('$base/${StoragePaths.thumbnails}');
  }

  @override
  Future<SavedPaths> saveProcessedImage({
    required Uint8List processedBytes,
    required Uint8List originalBytes,
    required ProcessingType type,
  }) async {
    await _ensureDirectories();
    final base = await baseDirectory;
    final fileName = FileUtils.generateFileName();
    final fileNameNoExt = fileName.replaceAll('.png', '');

    final originalPath = '$base/${StoragePaths.originals}/$fileName';
    final processedSubdir = type == ProcessingType.face
        ? StoragePaths.processedFaces
        : StoragePaths.processedDocuments;
    final processedPath = '$base/$processedSubdir/${fileNameNoExt}_processed.png';
    final thumbPath = '$base/${StoragePaths.thumbnails}/${fileNameNoExt}_thumb.jpg';

    await Future.wait([
      File(originalPath).writeAsBytes(originalBytes),
      File(processedPath).writeAsBytes(processedBytes),
    ]);

    final thumbBytes = await ImageUtils.generateThumbnail(processedBytes);
    await File(thumbPath).writeAsBytes(thumbBytes);

    return SavedPaths(
      originalPath: originalPath,
      processedPath: processedPath,
      thumbnailPath: thumbPath,
    );
  }

  @override
  Future<SavedPaths> saveDocumentResult({
    required Uint8List processedBytes,
    required Uint8List originalBytes,
    required Uint8List pdfBytes,
  }) async {
    await _ensureDirectories();
    final base = await baseDirectory;
    final fileName = FileUtils.generateFileName();
    final fileNameNoExt = fileName.replaceAll('.png', '');

    final originalPath = '$base/${StoragePaths.originals}/$fileName';
    final processedPath =
        '$base/${StoragePaths.processedDocuments}/${fileNameNoExt}_processed.png';
    final pdfPath = '$base/${StoragePaths.pdfs}/$fileNameNoExt.pdf';
    final thumbPath = '$base/${StoragePaths.thumbnails}/${fileNameNoExt}_thumb.jpg';

    await Future.wait([
      File(originalPath).writeAsBytes(originalBytes),
      File(processedPath).writeAsBytes(processedBytes),
      File(pdfPath).writeAsBytes(pdfBytes),
    ]);

    final thumbBytes = await ImageUtils.generateThumbnail(processedBytes);
    await File(thumbPath).writeAsBytes(thumbBytes);

    return SavedPaths(
      originalPath: originalPath,
      processedPath: processedPath,
      thumbnailPath: thumbPath,
      pdfPath: pdfPath,
    );
  }

  @override
  Future<void> deleteFiles(String originalPath, String processedPath,
      String thumbnailPath, String? pdfPath) async {
    await FileUtils.safeDelete(originalPath);
    await FileUtils.safeDelete(processedPath);
    await FileUtils.safeDelete(thumbnailPath);
    await FileUtils.safeDelete(pdfPath);
  }
}
