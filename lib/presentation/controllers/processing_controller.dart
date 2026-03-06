import 'package:get/get.dart';

import '../../core/errors/app_exceptions.dart';
import '../../core/utils/logger.dart';
import '../../data/datasources/services/notification_service.dart';
import '../../domain/entities/processing_result.dart';
import '../../domain/entities/processing_type.dart';
import '../../domain/usecases/detect_content_type.dart';
import '../../domain/usecases/process_document_image.dart';
import '../../domain/usecases/process_face_image.dart';
import '../../domain/usecases/save_processing_result.dart';
import '../controllers/capture_controller.dart';
import '../routes/app_routes.dart';

class ProcessingController extends GetxController {
  final _detectContentType = Get.find<DetectContentType>();
  final _processFaceImage = Get.find<ProcessFaceImage>();
  final _processDocumentImage = Get.find<ProcessDocumentImage>();
  final _saveProcessingResult = Get.find<SaveProcessingResult>();

  final processingSteps = <ProcessingStep>[].obs;
  final overallProgress = 0.0.obs;
  final detectedType = Rxn<ProcessingType>();
  final currentStatus = ProcessingStatus.idle.obs;
  final errorMessage = ''.obs;

  late final String imagePath;
  bool _isBackgroundMode = false;

  @override
  void onInit() {
    super.onInit();
    imagePath = Get.arguments as String;
    _startProcessing();
  }

  Future<void> _startProcessing() async {
    try {
      if (!_isBackgroundMode) {
        currentStatus.value = ProcessingStatus.detecting;
        _onProgress(const ProcessingStep(
          'Analyzing image...',
          0.05,
          ProcessingStepStatus.inProgress,
        ));
      }

      final type = await _detectContentType.execute(imagePath);
      if (!_isBackgroundMode) {
        detectedType.value = type;
        currentStatus.value = ProcessingStatus.processing;
      }

      final result = type == ProcessingType.face
          ? await _processFaceImage.execute(
              imagePath,
              _isBackgroundMode ? (_) {} : _onProgress,
            )
          : await _processDocumentImage.execute(
              imagePath,
              _isBackgroundMode ? (_) {} : _onProgress,
            );

      if (!_isBackgroundMode) {
        currentStatus.value = ProcessingStatus.saving;
      }
      final historyEntry = await _saveProcessingResult.execute(result);

      if (_isBackgroundMode) {
        final notificationService = Get.find<NotificationService>();
        await notificationService.showProcessingComplete(
          type,
          historyEntry.id,
        );
        return;
      }

      currentStatus.value = ProcessingStatus.complete;

      await Future.delayed(const Duration(milliseconds: 500));
      Get.offNamed(AppRoutes.result, arguments: {
        'result': result,
        'historyEntry': historyEntry,
      });
    } on AppException catch (e) {
      if (_isBackgroundMode) {
        final notificationService = Get.find<NotificationService>();
        await notificationService.showProcessingFailed(e.message);
        return;
      }
      currentStatus.value = ProcessingStatus.error;
      errorMessage.value = e.message;
    } catch (e, stack) {
      AppLogger.error('Processing failed', e, stack);
      if (_isBackgroundMode) {
        final notificationService = Get.find<NotificationService>();
        await notificationService.showProcessingFailed(e.toString());
        return;
      }
      currentStatus.value = ProcessingStatus.error;
      errorMessage.value = 'Processing failed: ${e.toString()}';
    }
  }

  void _onProgress(ProcessingStep step) {
    final index = processingSteps.indexWhere(
      (s) => s.description == step.description,
    );
    if (index >= 0) {
      processingSteps[index] = step;
    } else {
      processingSteps.add(step);
    }
    overallProgress.value = step.progress;
  }

  void continueInBackground() {
    _isBackgroundMode = true;
    Get.offAllNamed(AppRoutes.main);
  }

  void retry() {
    processingSteps.clear();
    overallProgress.value = 0.0;
    errorMessage.value = '';
    _startProcessing();
  }

  void goBack() {
    if (Get.isRegistered<CaptureController>()) {
      Get.find<CaptureController>().resumeCamera();
    }
    Get.back();
  }
}
