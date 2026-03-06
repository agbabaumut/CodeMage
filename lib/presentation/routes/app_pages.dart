import 'package:get/get.dart';

import '../bindings/batch_processing_binding.dart';
import '../bindings/batch_result_binding.dart';
import '../bindings/capture_binding.dart';
import '../bindings/history_detail_binding.dart';
import '../bindings/home_binding.dart';
import '../bindings/main_shell_binding.dart';
import '../bindings/processing_binding.dart';
import '../bindings/result_binding.dart';
import '../pages/batch_processing/batch_processing_page.dart';
import '../pages/batch_processing/batch_result_page.dart';
import '../pages/paywall/paywall_page.dart';
import '../pages/capture/capture_page.dart';
import '../pages/history_detail/history_detail_page.dart';
import '../pages/home/home_page.dart';
import '../pages/main/main_shell_page.dart';
import '../pages/processing/processing_page.dart';
import '../pages/result/result_page.dart';
import '../pages/splash/splash_page.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashPage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.main,
      page: () => const MainShellPage(),
      binding: MainShellBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.capture,
      page: () => const CapturePage(),
      binding: CaptureBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.processing,
      page: () => const ProcessingPage(),
      binding: ProcessingBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.result,
      page: () => const ResultPage(),
      binding: ResultBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.historyDetail,
      page: () => const HistoryDetailPage(),
      binding: HistoryDetailBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.batchProcessing,
      page: () => const BatchProcessingPage(),
      binding: BatchProcessingBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.batchResult,
      page: () => const BatchResultPage(),
      binding: BatchResultBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.paywall,
      page: () => const PaywallPage(),
      transition: Transition.downToUp,
      fullscreenDialog: true,
    ),
  ];
}
