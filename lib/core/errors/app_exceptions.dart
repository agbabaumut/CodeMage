import '../constants/app_strings.dart';

sealed class AppException implements Exception {
  final String message;
  final String? technicalDetail;
  const AppException(this.message, [this.technicalDetail]);

  @override
  String toString() => message;
}

class NoFacesDetectedException extends AppException {
  const NoFacesDetectedException() : super(AppStrings.noFacesDetected);
}

class NoTextDetectedException extends AppException {
  const NoTextDetectedException() : super(AppStrings.noTextDetected);
}

class NeitherDetectedException extends AppException {
  const NeitherDetectedException()
      : super('Could not identify faces or documents in this image.');
}

class ImageDecodingException extends AppException {
  const ImageDecodingException([String? detail])
      : super(AppStrings.imageCorrupted, detail);
}

class StorageException extends AppException {
  const StorageException([String? detail])
      : super(AppStrings.storageFull, detail);
}

class CameraNotAvailableException extends AppException {
  const CameraNotAvailableException([String? detail])
      : super(AppStrings.cameraUnavailable, detail);
}

class PermissionDeniedException extends AppException {
  final bool isPermanent;
  const PermissionDeniedException({this.isPermanent = false})
      : super(AppStrings.permissionRequired);
}
