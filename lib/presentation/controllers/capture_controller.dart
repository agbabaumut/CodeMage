import 'dart:async';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../routes/app_routes.dart';
import 'batch_processing_controller.dart';

class CaptureController extends GetxController {
  CameraController? cameraController;
  final isCameraInitialized = false.obs;
  final isFrontCamera = false.obs;
  final flashMode = FlashMode.off.obs;
  final isCapturing = false.obs;
  final hasPermission = false.obs;
  final permissionPermanentlyDenied = false.obs;

  final detectedFaces = <Face>[].obs;
  final detectedText = Rxn<RecognizedText>();
  final isLiveDetectionEnabled = true.obs;
  final detectionLabel = ''.obs;

  List<CameraDescription> _cameras = [];
  final _imagePicker = ImagePicker();

  FaceDetector? _faceDetector;
  TextRecognizer? _textRecognizer;
  bool _isProcessingFrame = false;

  @override
  void onInit() {
    super.onInit();
    _initDetectors();
    _initCamera();
  }

  @override
  void onClose() {
    _stopImageStream();
    cameraController?.dispose();
    _faceDetector?.close();
    _textRecognizer?.close();
    super.onClose();
  }

  void _initDetectors() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableLandmarks: false,
        enableContours: false,
      ),
    );
    _textRecognizer = TextRecognizer();
  }

  Future<void> _initCamera() async {
    try {
      final status = await Permission.camera.request();
      if (status.isPermanentlyDenied) {
        hasPermission.value = false;
        permissionPermanentlyDenied.value = true;
        return;
      }

      if (!status.isGranted) {
        hasPermission.value = false;
        permissionPermanentlyDenied.value = false;
        return;
      }

      hasPermission.value = true;
      permissionPermanentlyDenied.value = false;

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        Get.snackbar('Error', 'No cameras found on this device');
        return;
      }

      await _setupCamera(_cameras.first);
    } catch (e) {
      Get.snackbar('Error', 'Failed to initialize camera');
    }
  }

  Future<void> retryPermission() async {
    if (permissionPermanentlyDenied.value) {
      await openAppSettings();
    } else {
      await _initCamera();
    }
  }

  Future<void> _setupCamera(CameraDescription camera) async {
    _stopImageStream();
    cameraController?.dispose();

    cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: defaultTargetPlatform == TargetPlatform.iOS
          ? ImageFormatGroup.bgra8888
          : ImageFormatGroup.nv21,
    );

    try {
      await cameraController!.initialize();
      await cameraController!.setFlashMode(flashMode.value);
      isCameraInitialized.value = true;

      if (isLiveDetectionEnabled.value) {
        _startImageStream();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to initialize camera');
    }
  }

  void _startImageStream() {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }

    try {
      cameraController!.startImageStream(_processCameraFrame);
    } catch (_) {}
  }

  void _stopImageStream() {
    try {
      if (cameraController?.value.isStreamingImages ?? false) {
        cameraController!.stopImageStream();
      }
    } catch (_) {}
  }

  void _processCameraFrame(CameraImage image) {
    if (_isProcessingFrame || !isLiveDetectionEnabled.value) return;
    _isProcessingFrame = true;

    _runDetection(image).then((_) {
      _isProcessingFrame = false;
    }).catchError((_) {
      _isProcessingFrame = false;
    });
  }

  Future<void> _runDetection(CameraImage image) async {
    final inputImage = _convertCameraImage(image);
    if (inputImage == null) return;

    try {
      final results = await Future.wait([
        _faceDetector!.processImage(inputImage),
        _textRecognizer!.processImage(inputImage),
      ]);

      final faces = results[0] as List<Face>;
      final text = results[1] as RecognizedText;

      detectedFaces.assignAll(faces);
      detectedText.value = text;

      if (faces.isNotEmpty) {
        detectionLabel.value =
            '${faces.length} face${faces.length > 1 ? 's' : ''} detected';
      } else if (text.blocks.length >= 3) {
        detectionLabel.value = 'Document detected';
      } else {
        detectionLabel.value = '';
      }
    } catch (_) {}
  }

  InputImage? _convertCameraImage(CameraImage image) {
    final camera = cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    }

    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    if (image.planes.isEmpty) return null;

    return InputImage.fromBytes(
      bytes: image.planes.first.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  Size get imageSize {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return const Size(1, 1);
    }
    return Size(
      cameraController!.value.previewSize!.height,
      cameraController!.value.previewSize!.width,
    );
  }

  void resetDetectionState() {
    detectedFaces.clear();
    detectedText.value = null;
    detectionLabel.value = '';
  }

  void resumeCamera() {
    resetDetectionState();
    if (isLiveDetectionEnabled.value &&
        cameraController != null &&
        cameraController!.value.isInitialized) {
      _startImageStream();
    }
  }

  Future<void> captureImage() async {
    if (cameraController == null || isCapturing.value) return;

    isCapturing.value = true;
    try {
      _stopImageStream();
      resetDetectionState();

      final xFile = await cameraController!.takePicture();
      _navigateToProcessing(xFile.path);
    } catch (e) {
      Get.snackbar('Error', 'Failed to capture image');
      if (isLiveDetectionEnabled.value) {
        _startImageStream();
      }
    } finally {
      isCapturing.value = false;
    }
  }

  Future<void> pickFromGallery() async {
    try {
      final xFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 4000,
        maxHeight: 4000,
      );

      if (xFile != null) {
        Get.find<BatchProcessingController>().addBatch([xFile.path]);
        Get.offNamed(AppRoutes.batchProcessing);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image');
    }
  }

  Future<void> pickMultipleFromGallery() async {
    try {
      final files = await _imagePicker.pickMultiImage(limit: 20);
      if (files.isNotEmpty) {
        final paths = files.map((f) => f.path).toList();
        Get.find<BatchProcessingController>().addBatch(paths);
        Get.offNamed(AppRoutes.batchProcessing);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick images');
    }
  }

  Future<void> toggleFlash() async {
    if (cameraController == null) return;

    final modes = [FlashMode.off, FlashMode.auto, FlashMode.always];
    final currentIndex = modes.indexOf(flashMode.value);
    final nextMode = modes[(currentIndex + 1) % modes.length];

    await cameraController!.setFlashMode(nextMode);
    flashMode.value = nextMode;
  }

  Future<void> switchCamera() async {
    if (_cameras.length < 2) return;

    isFrontCamera.toggle();
    final camera = isFrontCamera.value ? _cameras.last : _cameras.first;
    isCameraInitialized.value = false;
    detectedFaces.clear();
    detectedText.value = null;
    detectionLabel.value = '';
    await _setupCamera(camera);
  }

  void toggleLiveDetection() {
    isLiveDetectionEnabled.toggle();
    if (isLiveDetectionEnabled.value) {
      _startImageStream();
    } else {
      _stopImageStream();
      detectedFaces.clear();
      detectedText.value = null;
      detectionLabel.value = '';
    }
  }

  void _navigateToProcessing(String imagePath) {
    Get.find<BatchProcessingController>().addBatch([imagePath]);
    Get.offNamed(AppRoutes.batchProcessing);
  }
}
