import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../core/errors/app_exceptions.dart';
import '../../core/utils/image_utils.dart';
import '../../data/datasources/services/edge_detection_service.dart';
import '../../data/datasources/services/image_manipulation_service.dart';
import '../../data/datasources/services/pdf_generation_service.dart';
import '../../data/datasources/services/text_recognition_service.dart';
import '../entities/processing_result.dart';
import '../entities/processing_type.dart';
import '../repositories/file_storage_repository.dart';

class ProcessDocumentImage {
  final TextRecognitionService _textRecognitionService;
  final EdgeDetectionService _edgeDetectionService;
  final ImageManipulationService _imageManipulationService;
  final PdfGenerationService _pdfGenerationService;
  final FileStorageRepository _fileStorageRepository;

  ProcessDocumentImage(
    this._textRecognitionService,
    this._edgeDetectionService,
    this._imageManipulationService,
    this._pdfGenerationService,
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

    onProgress(const ProcessingStep('Recognizing text...', 0.15, ProcessingStepStatus.inProgress));
    final recognizedText = await _textRecognitionService.recognizeText(imagePath);

    if (recognizedText.blocks.isEmpty) {
      throw const NoTextDetectedException();
    }

    onProgress(const ProcessingStep('Detecting document edges...', 0.30, ProcessingStepStatus.inProgress));
    var corners = await _edgeDetectionService.detectDocumentEdges(imageBytes);
    corners ??= _inferDocumentCorners(recognizedText.blocks);

    onProgress(const ProcessingStep('Correcting perspective...', 0.45, ProcessingStepStatus.inProgress));
    final processedBytes = await _imageManipulationService.processDocument(
      imageBytes,
      corners,
    );

    onProgress(const ProcessingStep('Generating PDF...', 0.70, ProcessingStepStatus.inProgress));
    final pdfBytes = await _pdfGenerationService.generatePdf(processedBytes);

    onProgress(const ProcessingStep('Saving result...', 0.85, ProcessingStepStatus.inProgress));
    final savedPaths = await _fileStorageRepository.saveDocumentResult(
      processedBytes: processedBytes,
      originalBytes: imageBytes,
      pdfBytes: pdfBytes,
    );

    stopwatch.stop();

    final pdfFile = File(savedPaths.pdfPath!);
    final fileSize = await pdfFile.length();

    onProgress(const ProcessingStep('Complete!', 1.0, ProcessingStepStatus.completed));

    return ProcessingResult(
      type: ProcessingType.document,
      originalPath: savedPaths.originalPath,
      processedPath: savedPaths.processedPath,
      thumbnailPath: savedPaths.thumbnailPath,
      pdfPath: savedPaths.pdfPath,
      fileSizeBytes: fileSize,
      processingDurationMs: stopwatch.elapsedMilliseconds,
      extractedText: recognizedText.text,
    );
  }

  List<Offset>? _inferDocumentCorners(List<TextBlock> blocks) {
    if (blocks.length < 2) return null;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final block in blocks) {
      final rect = block.boundingBox;
      if (rect.left < minX) minX = rect.left;
      if (rect.top < minY) minY = rect.top;
      if (rect.right > maxX) maxX = rect.right;
      if (rect.bottom > maxY) maxY = rect.bottom;
    }

    final padX = (maxX - minX) * 0.05;
    final padY = (maxY - minY) * 0.05;

    return [
      Offset(minX - padX, minY - padY),
      Offset(maxX + padX, minY - padY),
      Offset(maxX + padX, maxY + padY),
      Offset(minX - padX, maxY + padY),
    ];
  }
}
