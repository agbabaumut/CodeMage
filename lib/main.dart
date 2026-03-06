import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app.dart';
import 'core/utils/logger.dart';
import 'data/datasources/local/hive_database.dart';
import 'data/datasources/services/notification_service.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        AppLogger.error(
          'Flutter error',
          details.exception,
          details.stack,
        );
      };

      final database = HiveDatabase();
      await database.initialize();
      Get.put<HiveDatabase>(database, permanent: true);

      final notificationService = NotificationService();
      await notificationService.initialize();
      Get.put<NotificationService>(notificationService, permanent: true);

      runApp(const App());
    },
    (error, stack) {
      AppLogger.error('Unhandled error', error, stack);
    },
  );
}
