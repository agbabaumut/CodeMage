import 'dart:async';

import 'package:get/get.dart';

import '../../core/errors/app_exceptions.dart';
import '../../core/utils/logger.dart';
import '../../data/datasources/services/notification_service.dart';
import '../../domain/entities/batch_item.dart';
import '../../domain/entities/processing_type.dart';
import '../../domain/usecases/detect_content_type.dart';
import '../../domain/usecases/process_document_image.dart';
import '../../domain/usecases/process_face_image.dart';
import '../../domain/usecases/save_processing_result.dart';
import '../routes/app_routes.dart';
import 'home_controller.dart';

class BatchProcessingController extends GetxController {
  final _detectContentType = Get.find<DetectContentType>();
  final _processFaceImage = Get.find<ProcessFaceImage>();
  final _processDocumentImage = Get.find<ProcessDocumentImage>();
  final _saveProcessingResult = Get.find<SaveProcessingResult>();

  final items = <BatchItem>[].obs;
  final currentIndex = (-1).obs;
  final isProcessing = false.obs;
  final overallProgress = 0.0.obs;
  final currentItemProgress = 0.0.obs;
  final currentStepDescription = ''.obs;
  final isBannerDismissed = false.obs;

  int _totalDurationMs = 0;
  Timer? _bannerDismissTimer;

  bool get hasItems => items.isNotEmpty;
  bool get hasVisibleBanner => hasItems && !isBannerDismissed.value;

  int get completedCount =>
      items.where((i) => i.status == BatchItemStatus.completed).length;

  int get failedCount =>
      items.where((i) => i.status == BatchItemStatus.failed).length;

  int get totalDurationMs => _totalDurationMs;

  void addBatch(List<String> paths) {
    final newItems = paths.map((p) => BatchItem(imagePath: p)).toList();
    items.addAll(newItems);
    isBannerDismissed.value = false;
    _bannerDismissTimer?.cancel();
    if (!isProcessing.value) {
      _processQueue();
    }
  }

  Future<void> _processQueue() async {
    isProcessing.value = true;

    // Find first pending item index
    int startIndex = items.indexWhere((i) => i.status == BatchItemStatus.pending);
    if (startIndex == -1) {
      isProcessing.value = false;
      return;
    }

    for (int i = startIndex; i < items.length; i++) {
      if (items[i].status != BatchItemStatus.pending) continue;

      currentIndex.value = i;
      currentItemProgress.value = 0.0;
      currentStepDescription.value = 'Analyzing image...';

      items[i] = items[i].copyWith(status: BatchItemStatus.processing);
      items.refresh();

      final stopwatch = Stopwatch()..start();

      try {
        currentStepDescription.value = 'Detecting content type...';
        final type = await _detectContentType.execute(items[i].imagePath);

        items[i] = items[i].copyWith(detectedType: type);
        items.refresh();

        currentStepDescription.value = type == ProcessingType.face
            ? 'Processing face...'
            : 'Processing document...';

        final progressCallback = (step) {
          currentItemProgress.value = step.progress;
          currentStepDescription.value = step.description;
        };

        final result = type == ProcessingType.face
            ? await _processFaceImage.execute(items[i].imagePath, progressCallback)
            : await _processDocumentImage.execute(items[i].imagePath, progressCallback);

        currentStepDescription.value = 'Saving result...';
        final historyEntry = await _saveProcessingResult.execute(result);

        stopwatch.stop();
        _totalDurationMs += stopwatch.elapsedMilliseconds;

        items[i] = items[i].copyWith(
          status: BatchItemStatus.completed,
          historyEntry: historyEntry,
        );
        items.refresh();
        _refreshHome();
      } on AppException catch (e) {
        stopwatch.stop();
        _totalDurationMs += stopwatch.elapsedMilliseconds;

        items[i] = items[i].copyWith(
          status: BatchItemStatus.failed,
          error: e.message,
        );
        items.refresh();
      } catch (e, stack) {
        stopwatch.stop();
        _totalDurationMs += stopwatch.elapsedMilliseconds;

        AppLogger.error('Batch item processing failed', e, stack);
        items[i] = items[i].copyWith(
          status: BatchItemStatus.failed,
          error: 'Processing failed: ${e.toString()}',
        );
        items.refresh();
      }

      // Calculate progress based on all non-pending items
      final processedCount = items.where((i) =>
          i.status == BatchItemStatus.completed ||
          i.status == BatchItemStatus.failed).length;
      overallProgress.value = processedCount / items.length;
    }

    isProcessing.value = false;
    currentStepDescription.value = 'Batch complete!';

    _onComplete();
  }

  void _refreshHome() {
    try {
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().loadHistory();
      }
    } catch (_) {}
  }

  void _onComplete() {
    try {
      final notificationService = Get.find<NotificationService>();
      notificationService.showBatchComplete(completedCount, failedCount);
    } catch (_) {}

    _refreshHome();

    _bannerDismissTimer?.cancel();
    _bannerDismissTimer = Timer(const Duration(seconds: 5), () {
      isBannerDismissed.value = true;
    });
  }

  void dismissBanner() {
    _bannerDismissTimer?.cancel();
    isBannerDismissed.value = true;
  }

  void clearCompleted() {
    items.removeWhere((i) =>
        i.status == BatchItemStatus.completed ||
        i.status == BatchItemStatus.failed);
    if (items.isEmpty) {
      overallProgress.value = 0.0;
      currentIndex.value = -1;
      _totalDurationMs = 0;
    }
  }

  void goToBackground() {
    Get.offAllNamed(AppRoutes.main);
  }

  void viewResults() {
    Get.offNamed(AppRoutes.batchResult, arguments: items.toList());
  }
}
