import 'dart:io';
import 'dart:isolate';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

import '../../core/errors/app_exceptions.dart';
import '../../data/datasources/services/face_detection_service.dart';
import '../../data/datasources/services/text_recognition_service.dart';
import '../entities/processing_type.dart';

class DetectContentType {
  final FaceDetectionService _faceDetectionService;
  final TextRecognitionService _textRecognitionService;

  DetectContentType(this._faceDetectionService, this._textRecognitionService);

  Future<ProcessingType> execute(String imagePath) async {
    final results = await Future.wait([
      _faceDetectionService.detectFaces(imagePath),
      _textRecognitionService.recognizeText(imagePath),
    ]);

    final faces = results[0] as List<Face>;
    final recognizedText = results[1] as RecognizedText;

    final hasFaces = faces.isNotEmpty;
    final hasText = recognizedText.blocks.isNotEmpty;
    final hasDocument = recognizedText.blocks.length >= 3;

    if (hasFaces && !hasDocument) return ProcessingType.face;
    if (!hasFaces && hasDocument) return ProcessingType.document;

    if (hasFaces && hasDocument) {
      final imageBytes = await File(imagePath).readAsBytes();
      final dimensions = await Isolate.run(() {
        final decoded = img.decodeImage(imageBytes);
        if (decoded == null) return null;
        return [decoded.width.toDouble(), decoded.height.toDouble()];
      });

      if (dimensions != null) {
        final totalFaceArea = faces.fold<double>(
          0,
          (sum, face) => sum + face.boundingBox.width * face.boundingBox.height,
        );
        final imageArea = dimensions[0] * dimensions[1];
        final ratio = totalFaceArea / imageArea;

        return ratio > 0.15 ? ProcessingType.face : ProcessingType.document;
      }
      return ProcessingType.face;
    }

    if (hasFaces) return ProcessingType.face;
    if (hasText) return ProcessingType.document;

    throw const NeitherDetectedException();
  }
}
