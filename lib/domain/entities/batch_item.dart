import 'processing_history.dart';
import 'processing_type.dart';

enum BatchItemStatus { pending, processing, completed, failed }

class BatchItem {
  final String imagePath;
  final BatchItemStatus status;
  final ProcessingType? detectedType;
  final ProcessingHistory? historyEntry;
  final String? error;

  const BatchItem({
    required this.imagePath,
    this.status = BatchItemStatus.pending,
    this.detectedType,
    this.historyEntry,
    this.error,
  });

  BatchItem copyWith({
    String? imagePath,
    BatchItemStatus? status,
    ProcessingType? detectedType,
    ProcessingHistory? historyEntry,
    String? error,
  }) {
    return BatchItem(
      imagePath: imagePath ?? this.imagePath,
      status: status ?? this.status,
      detectedType: detectedType ?? this.detectedType,
      historyEntry: historyEntry ?? this.historyEntry,
      error: error ?? this.error,
    );
  }
}
