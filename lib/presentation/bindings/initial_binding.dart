import 'package:get/get.dart';

import '../../data/datasources/local/hive_database.dart';
import '../../data/datasources/services/edge_detection_service.dart';
import '../../data/datasources/services/face_detection_service.dart';
import '../../data/datasources/services/file_storage_service.dart';
import '../../data/datasources/services/image_manipulation_service.dart';
import '../../data/datasources/services/pdf_generation_service.dart';
import '../../data/datasources/services/text_recognition_service.dart';
import '../../data/repositories/history_repository_impl.dart';
import '../../domain/repositories/file_storage_repository.dart';
import '../../domain/repositories/history_repository.dart';
import '../../domain/usecases/delete_processing_entry.dart';
import '../../domain/usecases/detect_content_type.dart';
import '../../domain/usecases/get_processing_history.dart';
import '../../domain/usecases/process_document_image.dart';
import '../../domain/usecases/process_face_image.dart';
import '../../domain/usecases/save_processing_result.dart';
import '../controllers/batch_processing_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<FaceDetectionService>(FaceDetectionService(), permanent: true);
    Get.put<TextRecognitionService>(TextRecognitionService(), permanent: true);
    Get.put<EdgeDetectionService>(EdgeDetectionService(), permanent: true);
    Get.put<ImageManipulationService>(ImageManipulationService(), permanent: true);
    Get.put<PdfGenerationService>(PdfGenerationService(), permanent: true);

    Get.put<HistoryRepository>(
      HistoryRepositoryImpl(Get.find<HiveDatabase>()),
      permanent: true,
    );
    Get.put<FileStorageRepository>(
      FileStorageServiceImpl(),
      permanent: true,
    );

    Get.put(DetectContentType(
      Get.find<FaceDetectionService>(),
      Get.find<TextRecognitionService>(),
    ));
    Get.put(ProcessFaceImage(
      Get.find<FaceDetectionService>(),
      Get.find<ImageManipulationService>(),
      Get.find<FileStorageRepository>(),
    ));
    Get.put(ProcessDocumentImage(
      Get.find<TextRecognitionService>(),
      Get.find<EdgeDetectionService>(),
      Get.find<ImageManipulationService>(),
      Get.find<PdfGenerationService>(),
      Get.find<FileStorageRepository>(),
    ));
    Get.put(SaveProcessingResult(Get.find<HistoryRepository>()));
    Get.put(GetProcessingHistory(Get.find<HistoryRepository>()));
    Get.put(DeleteProcessingEntry(
      Get.find<HistoryRepository>(),
      Get.find<FileStorageRepository>(),
    ));

    Get.put<BatchProcessingController>(
      BatchProcessingController(),
      permanent: true,
    );
  }
}
