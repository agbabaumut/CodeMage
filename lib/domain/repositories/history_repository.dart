import '../entities/processing_history.dart';

abstract class HistoryRepository {
  Future<List<ProcessingHistory>> getAll();
  Future<ProcessingHistory?> getById(String id);
  Future<void> save(ProcessingHistory entry);
  Future<void> delete(String id);
  Future<void> deleteAll();
}
