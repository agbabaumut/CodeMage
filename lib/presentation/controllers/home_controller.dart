import 'package:get/get.dart';

import '../../domain/entities/processing_history.dart';
import '../../domain/usecases/delete_processing_entry.dart';
import '../../domain/usecases/get_processing_history.dart';
import '../routes/app_routes.dart';

class HomeController extends GetxController {
  final _getProcessingHistory = Get.find<GetProcessingHistory>();
  final _deleteProcessingEntry = Get.find<DeleteProcessingEntry>();

  final historyList = <ProcessingHistory>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  @override
  void onReady() {
    super.onReady();
    loadHistory();
  }

  Future<void> loadHistory() async {
    isLoading.value = true;
    try {
      final history = await _getProcessingHistory.execute();
      historyList.assignAll(history);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load history');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteEntry(String id) async {
    try {
      await _deleteProcessingEntry.execute(id);
      historyList.removeWhere((item) => item.id == id);
      Get.snackbar('Deleted', 'Entry removed successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete entry');
    }
  }

  void navigateToCapture() {
    Get.toNamed(AppRoutes.capture);
  }

  void navigateToDetail(ProcessingHistory entry) {
    Get.toNamed(AppRoutes.historyDetail, arguments: entry);
  }
}
