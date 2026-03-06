import 'dart:io';
import 'dart:isolate';

import '../../core/errors/app_exceptions.dart';
import '../../core/utils/image_utils.dart';
import '../../data/datasources/services/face_detection_service.dart';
import '../../data/datasources/services/image_manipulation_service.dart';
import '../entities/processing_result.dart';
import '../entities/processing_type.dart';
import '../repositories/file_storage_repository.dart';

class ProcessFaceImage {
  final FaceDetectionService _faceDetectionService;
  final ImageManipulationService _imageManipulationService;
  final FileStorageRepository _fileStorageRepository;

  ProcessFaceImage(
    this._faceDetectionService,
    this._imageManipulationService,
    this._fileStorageRepository,
  );

  Future<ProcessingResult> execute(
    String imagePath,
    void Function(ProcessingStep) onProgress,
  ) async {
    final stopwatch = Stopwatch()..start();

    onProgress(const ProcessingStep('Loading image...', 0.05, ProcessingStepStatus.inProgress));
    var imageBytes = await Isolate.run(() => File(imagePath).readAsBytes());

    imageBytes = await ImageUtils.ensureReasonableSize(imageBytes);

    onProgress(const ProcessingStep('Detecting faces...', 0.15, ProcessingStepStatus.inProgress));
    final faces = await _faceDetectionService.detectFaces(imagePath);

    if (faces.isEmpty) {
      throw const NoFacesDetectedException();
    }

    onProgress(ProcessingStep(
      'Processing ${faces.length} face(s)...',
      0.35,
      ProcessingStepStatus.inProgress,
    ));

    final boundingBoxes = faces.map((f) => f.boundingBox).toList();
    final processedBytes = await _imageManipulationService.processFaces(
      imageBytes,
      boundingBoxes,
    );

    onProgress(const ProcessingStep('Saving result...', 0.85, ProcessingStepStatus.inProgress));
    final savedPaths = await _fileStorageRepository.saveProcessedImage(
      processedBytes: processedBytes,
      originalBytes: imageBytes,
      type: ProcessingType.face,
    );

    stopwatch.stop();

    final processedFile = File(savedPaths.processedPath);
    final fileSize = await processedFile.length();

    onProgress(const ProcessingStep('Complete!', 1.0, ProcessingStepStatus.completed));

    return ProcessingResult(
      type: ProcessingType.face,
      originalPath: savedPaths.originalPath,
      processedPath: savedPaths.processedPath,
      thumbnailPath: savedPaths.thumbnailPath,
      fileSizeBytes: fileSize,
      processingDurationMs: stopwatch.elapsedMilliseconds,
      faceCount: faces.length,
    );
  }
}
