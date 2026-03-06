import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/storage_paths.dart';
import '../../models/processing_history_model.dart';

class HiveDatabase {
  late Box<ProcessingHistoryModel> _historyBox;

  Future<void> initialize() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ProcessingHistoryModelAdapter());
    _historyBox = await Hive.openBox<ProcessingHistoryModel>(StoragePaths.hiveBox);
  }

  Box<ProcessingHistoryModel> get historyBox => _historyBox;

  Future<List<ProcessingHistoryModel>> getAllHistory() async {
    return _historyBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<ProcessingHistoryModel?> getHistoryById(String id) async {
    return _historyBox.values.cast<ProcessingHistoryModel?>().firstWhere(
          (item) => item?.id == id,
          orElse: () => null,
        );
  }

  Future<void> saveHistory(ProcessingHistoryModel model) async {
    await _historyBox.put(model.id, model);
  }

  Future<void> deleteHistory(String id) async {
    await _historyBox.delete(id);
  }

  Future<void> deleteAllHistory() async {
    await _historyBox.clear();
  }
}
