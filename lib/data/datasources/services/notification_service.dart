import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../../../domain/entities/processing_type.dart';
import '../../../domain/repositories/history_repository.dart';
import '../../../presentation/routes/app_routes.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  Future<void> showProcessingComplete(
    ProcessingType type,
    String historyId,
  ) async {
    final title = type == ProcessingType.face
        ? 'Face Processing Complete'
        : 'Document Processing Complete';

    await _plugin.show(
      0,
      title,
      'Tap to view the result',
      const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        android: AndroidNotificationDetails(
          'processing',
          'Processing',
          channelDescription: 'Image processing notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: historyId,
    );
  }

  Future<void> showBatchComplete(int succeeded, int failed) async {
    final body = failed > 0
        ? '$succeeded succeeded, $failed failed'
        : 'All $succeeded images processed successfully';

    await _plugin.show(
      2,
      'Batch Processing Complete',
      body,
      const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        android: AndroidNotificationDetails(
          'processing',
          'Processing',
          channelDescription: 'Image processing notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> showProcessingFailed(String message) async {
    await _plugin.show(
      1,
      'Processing Failed',
      message,
      const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
        android: AndroidNotificationDetails(
          'processing',
          'Processing',
          channelDescription: 'Image processing notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    final historyId = response.payload;
    if (historyId != null && historyId.isNotEmpty) {
      _navigateToResult(historyId);
    }
  }

  Future<void> _navigateToResult(String historyId) async {
    try {
      final repo = Get.find<HistoryRepository>();
      final entry = await repo.getById(historyId);
      if (entry != null) {
        Get.toNamed(AppRoutes.historyDetail, arguments: entry);
      }
    } catch (_) {}
  }
}
