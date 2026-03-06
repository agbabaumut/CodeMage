import 'package:path_provider/path_provider.dart';

import '../../domain/entities/processing_history.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/local/hive_database.dart';
import '../models/processing_history_model.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final HiveDatabase _database;
  String? _docsPath;

  HistoryRepositoryImpl(this._database);

  Future<String> _getDocsPath() async {
    _docsPath ??= (await getApplicationDocumentsDirectory()).path;
    return _docsPath!;
  }

  String _toRelative(String path, String docsPath) {
    if (path.startsWith(docsPath)) {
      return path.substring(docsPath.length);
    }
    return path;
  }

  String _toAbsolute(String path, String docsPath) {
    if (!path.startsWith('/')) {
      return '$docsPath$path';
    }
    if (!path.startsWith(docsPath)) {
      final marker = '/codeway_processor/';
      final idx = path.indexOf(marker);
      if (idx >= 0) {
        return '$docsPath${path.substring(idx)}';
      }
    }
    return path;
  }

  ProcessingHistory _resolveAbsolutePaths(
      ProcessingHistory entity, String docsPath) {
    return entity.copyWith(
      thumbnailPath: _toAbsolute(entity.thumbnailPath, docsPath),
      originalImagePath: _toAbsolute(entity.originalImagePath, docsPath),
      processedImagePath: _toAbsolute(entity.processedImagePath, docsPath),
      pdfPath: entity.pdfPath != null
          ? _toAbsolute(entity.pdfPath!, docsPath)
          : null,
    );
  }

  ProcessingHistory _stripToRelativePaths(
      ProcessingHistory entry, String docsPath) {
    return entry.copyWith(
      thumbnailPath: _toRelative(entry.thumbnailPath, docsPath),
      originalImagePath: _toRelative(entry.originalImagePath, docsPath),
      processedImagePath: _toRelative(entry.processedImagePath, docsPath),
      pdfPath: entry.pdfPath != null
          ? _toRelative(entry.pdfPath!, docsPath)
          : null,
    );
  }

  @override
  Future<List<ProcessingHistory>> getAll() async {
    final models = await _database.getAllHistory();
    final docsPath = await _getDocsPath();
    return models
        .map((m) => _resolveAbsolutePaths(m.toEntity(), docsPath))
        .toList();
  }

  @override
  Future<ProcessingHistory?> getById(String id) async {
    final model = await _database.getHistoryById(id);
    if (model == null) return null;
    final docsPath = await _getDocsPath();
    return _resolveAbsolutePaths(model.toEntity(), docsPath);
  }

  @override
  Future<void> save(ProcessingHistory entry) async {
    final docsPath = await _getDocsPath();
    final relativeEntry = _stripToRelativePaths(entry, docsPath);
    final model = ProcessingHistoryModel.fromEntity(relativeEntry);
    await _database.saveHistory(model);
  }

  @override
  Future<void> delete(String id) async {
    await _database.deleteHistory(id);
  }

  @override
  Future<void> deleteAll() async {
    await _database.deleteAllHistory();
  }
}
