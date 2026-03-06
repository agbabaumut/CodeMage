import 'processing_type.dart';

class ProcessingHistory {
  final String id;
  final ProcessingType type;
  final DateTime createdAt;
  final String originalImagePath;
  final String processedImagePath;
  final String? pdfPath;
  final int fileSizeBytes;
  final int processingDurationMs;
  final String thumbnailPath;
  final int faceCount;
  final String? extractedText;

  const ProcessingHistory({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.originalImagePath,
    required this.processedImagePath,
    this.pdfPath,
    required this.fileSizeBytes,
    required this.processingDurationMs,
    required this.thumbnailPath,
    this.faceCount = 0,
    this.extractedText,
  });

  ProcessingHistory copyWith({
    String? id,
    ProcessingType? type,
    DateTime? createdAt,
    String? originalImagePath,
    String? processedImagePath,
    String? pdfPath,
    int? fileSizeBytes,
    int? processingDurationMs,
    String? thumbnailPath,
    int? faceCount,
    String? extractedText,
  }) {
    return ProcessingHistory(
      id: id ?? this.id,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      originalImagePath: originalImagePath ?? this.originalImagePath,
      processedImagePath: processedImagePath ?? this.processedImagePath,
      pdfPath: pdfPath ?? this.pdfPath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      processingDurationMs: processingDurationMs ?? this.processingDurationMs,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      faceCount: faceCount ?? this.faceCount,
      extractedText: extractedText ?? this.extractedText,
    );
  }
}
