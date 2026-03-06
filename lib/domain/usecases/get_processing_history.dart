import '../entities/processing_history.dart';
import '../repositories/history_repository.dart';

class GetProcessingHistory {
  final HistoryRepository _repository;

  GetProcessingHistory(this._repository);

  Future<List<ProcessingHistory>> execute() async {
    return _repository.getAll();
  }
}
