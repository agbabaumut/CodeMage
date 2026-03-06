import 'package:get/get.dart';

import '../routes/app_routes.dart';

class MainShellController extends GetxController {
  final currentIndex = 0.obs;

  void changeTab(int index) {
    if (index == 1) {
      Get.toNamed(AppRoutes.capture);
      return;
    }
    currentIndex.value = index;
  }
}
