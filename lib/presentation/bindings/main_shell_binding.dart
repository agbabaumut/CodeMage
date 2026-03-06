import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../controllers/main_shell_controller.dart';

class MainShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MainShellController>(() => MainShellController());
    Get.lazyPut<HomeController>(() => HomeController());
  }
}
