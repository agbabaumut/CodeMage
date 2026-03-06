import 'package:uuid/uuid.dart';

import '../entities/processing_history.dart';
import '../entities/processing_result.dart';
import '../repositories/history_repository.dart';

class SaveProcessingResult {
  final HistoryRepository _repository;
  static const _uuid = Uuid();

  SaveProcessingResult(this._repository);

  Future<ProcessingHistory> execute(ProcessingResult result) async {
    final entry = ProcessingHistory(
      id: _uuid.v4(),
      type: result.type,
      createdAt: DateTime.now(),
      originalImagePath: result.originalPath,
      processedImagePath: result.processedPath,
      pdfPath: result.pdfPath,
      fileSizeBytes: result.fileSizeBytes,
      processingDurationMs: result.processingDurationMs,
      thumbnailPath: result.thumbnailPath,
      faceCount: result.faceCount,
      extractedText: result.extractedText,
    );

    await _repository.save(entry);
    return entry;
  }
}
