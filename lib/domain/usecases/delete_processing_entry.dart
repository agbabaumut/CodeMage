import '../repositories/file_storage_repository.dart';
import '../repositories/history_repository.dart';

class DeleteProcessingEntry {
  final HistoryRepository _historyRepository;
  final FileStorageRepository _fileStorageRepository;

  DeleteProcessingEntry(this._historyRepository, this._fileStorageRepository);

  Future<void> execute(String id) async {
    final entry = await _historyRepository.getById(id);
    if (entry != null) {
      await _fileStorageRepository.deleteFiles(
        entry.originalImagePath,
        entry.processedImagePath,
        entry.thumbnailPath,
        entry.pdfPath,
      );
    }
    await _historyRepository.delete(id);
  }
}
