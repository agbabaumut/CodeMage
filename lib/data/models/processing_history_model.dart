import 'package:hive/hive.dart';
import '../../domain/entities/processing_history.dart';
import '../../domain/entities/processing_type.dart';

part 'processing_history_model.g.dart';

@HiveType(typeId: 0)
class ProcessingHistoryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int type; // 0 = face, 1 = document

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final String originalImagePath;

  @HiveField(4)
  final String processedImagePath;

  @HiveField(5)
  final String? pdfPath;

  @HiveField(6)
  final int fileSizeBytes;

  @HiveField(7)
  final int processingDurationMs;

  @HiveField(8)
  final String thumbnailPath;

  @HiveField(9)
  final int faceCount;

  @HiveField(10)
  final String? extractedText;

  ProcessingHistoryModel({
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

  ProcessingHistory toEntity() {
    return ProcessingHistory(
      id: id,
      type: type == 0 ? ProcessingType.face : ProcessingType.document,
      createdAt: createdAt,
      originalImagePath: originalImagePath,
      processedImagePath: processedImagePath,
      pdfPath: pdfPath,
      fileSizeBytes: fileSizeBytes,
      processingDurationMs: processingDurationMs,
      thumbnailPath: thumbnailPath,
      faceCount: faceCount,
      extractedText: extractedText,
    );
  }

  static ProcessingHistoryModel fromEntity(ProcessingHistory entity) {
    return ProcessingHistoryModel(
      id: entity.id,
      type: entity.type == ProcessingType.face ? 0 : 1,
      createdAt: entity.createdAt,
      originalImagePath: entity.originalImagePath,
      processedImagePath: entity.processedImagePath,
      pdfPath: entity.pdfPath,
      fileSizeBytes: entity.fileSizeBytes,
      processingDurationMs: entity.processingDurationMs,
      thumbnailPath: entity.thumbnailPath,
      faceCount: entity.faceCount,
      extractedText: entity.extractedText,
    );
  }
}
