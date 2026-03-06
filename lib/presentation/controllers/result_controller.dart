import 'dart:io';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/processing_history.dart';
import '../../domain/entities/processing_result.dart';
import '../../domain/entities/processing_type.dart';
import '../routes/app_routes.dart';

class ResultController extends GetxController {
  late final ProcessingResult result;
  late final ProcessingHistory historyEntry;

  final showExtractedText = false.obs;
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>;
    result = args['result'] as ProcessingResult;
    historyEntry = args['historyEntry'] as ProcessingHistory;
  }

  bool get isFaceResult => result.type == ProcessingType.face;
  bool get isDocumentResult => result.type == ProcessingType.document;
  bool get hasExtractedText =>
      result.extractedText != null && result.extractedText!.isNotEmpty;

  String get filteredText {
    if (searchQuery.value.isEmpty) return result.extractedText ?? '';
    return result.extractedText ?? '';
  }

  void toggleExtractedText() {
    showExtractedText.toggle();
  }

  void copyTextToClipboard() {
    if (result.extractedText != null) {
      Clipboard.setData(ClipboardData(text: result.extractedText!));
      Get.snackbar('Copied', 'Text copied to clipboard');
    }
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  Future<void> shareResult(Rect shareOrigin) async {
    try {
      final path = result.pdfPath ?? result.processedPath;
      final file = File(path);
      if (!await file.exists()) {
        Get.snackbar('Error', 'File not found');
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

  Future<void> openPdf() async {
    try {
      if (result.pdfPath != null) {
        await OpenFile.open(result.pdfPath!);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to open PDF');
    }
  }

  void done() {
    Get.offAllNamed(AppRoutes.main);
  }
}
