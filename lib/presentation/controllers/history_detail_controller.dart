import 'dart:io';
import 'dart:ui';

import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/processing_history.dart';
import '../../domain/entities/processing_type.dart';
import '../../domain/usecases/delete_processing_entry.dart';
import '../../core/utils/file_utils.dart';
import '../routes/app_routes.dart';

class HistoryDetailController extends GetxController {
  final _deleteProcessingEntry = Get.find<DeleteProcessingEntry>();

  late final ProcessingHistory entry;

  @override
  void onInit() {
    super.onInit();
    entry = Get.arguments as ProcessingHistory;
  }

  bool get isDocument => entry.type == ProcessingType.document;
  bool get hasPdf => entry.pdfPath != null;

  String get formattedFileSize => FileUtils.formatFileSize(entry.fileSizeBytes);
  String get formattedDuration => FileUtils.formatDuration(entry.processingDurationMs);

  Future<void> shareResult(Rect shareOrigin) async {
    try {
      final path = entry.pdfPath ?? entry.processedImagePath;
      final file = File(path);
      if (!await file.exists()) {
        Get.snackbar('Error', 'File not found. Try processing the image again.');
        return;
      }
      await Share.shareXFiles(
        [XFile(path)],
        subject: 'CodeMage - Processed Image',
        sharePositionOrigin: shareOrigin,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to share: ${e.toString()}');
    }
  }

  Future<void> openInExternalViewer() async {
    try {
      if (entry.pdfPath != null) {
        await OpenFile.open(entry.pdfPath!);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to open file');
    }
  }

  Future<void> deleteAndGoBack() async {
    try {
      await _deleteProcessingEntry.execute(entry.id);
      Get.offAllNamed(AppRoutes.main);
      Get.snackbar('Deleted', 'Entry removed successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete entry');
    }
  }
}
