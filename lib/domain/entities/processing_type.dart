enum ProcessingType {
  face,
  document;

  String get displayName {
    switch (this) {
      case ProcessingType.face:
        return 'Face Processed';
      case ProcessingType.document:
        return 'Document Scan';
    }
  }

  String get iconLabel {
    switch (this) {
      case ProcessingType.face:
        return '👤';
      case ProcessingType.document:
        return '📄';
    }
  }
}

enum ProcessingStatus {
  idle,
  detecting,
  processing,
  saving,
  complete,
  error,
}
