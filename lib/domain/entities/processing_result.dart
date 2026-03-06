import 'processing_type.dart';

class ProcessingResult {
  final ProcessingType type;
  final String originalPath;
  final String processedPath;
  final String thumbnailPath;
  final String? pdfPath;
  final int fileSizeBytes;
  final int processingDurationMs;
  final int faceCount;
  final String? extractedText;

  const ProcessingResult({
    required this.type,
    required this.originalPath,
    required this.processedPath,
    required this.thumbnailPath,
    this.pdfPath,
    required this.fileSizeBytes,
    required this.processingDurationMs,
    this.faceCount = 0,
    this.extractedText,
  });
}

class ProcessingStep {
  final String description;
  final double progress;
  final ProcessingStepStatus status;

  const ProcessingStep(this.description, this.progress, this.status);
}

enum ProcessingStepStatus { pending, inProgress, completed, failed }
