import 'dart:io';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class FileUtils {
  FileUtils._();

  static const _uuid = Uuid();

  static String generateFileName({String extension = 'png'}) {
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final id = _uuid.v4().substring(0, 8);
    return '${date}_$id.$extension';
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String formatDuration(int milliseconds) {
    if (milliseconds < 1000) return '${milliseconds}ms';
    final seconds = milliseconds / 1000;
    if (seconds < 60) return '${seconds.toStringAsFixed(1)}s';
    final mins = (seconds / 60).floor();
    final remainingSecs = (seconds % 60).floor();
    if (remainingSecs == 0) return '${mins}m';
    return '${mins}m ${remainingSecs}s';
  }

  static Future<Directory> ensureDirectory(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<void> safeDelete(String? path) async {
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
