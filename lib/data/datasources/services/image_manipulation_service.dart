import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;

class ImageManipulationService {
  Future<Uint8List> processFaces(
    Uint8List imageBytes,
    List<ui.Rect> boundingBoxes,
  ) async {
    final boxData = boundingBoxes
        .map((b) => [b.left, b.top, b.width, b.height])
        .toList();

    return Isolate.run(() {
      return _processFacesIsolate(imageBytes, boxData);
    });
  }

  Future<Uint8List> processDocument(
    Uint8List imageBytes,
    List<ui.Offset>? corners,
  ) async {
    final cornerData = corners?.map((c) => [c.dx, c.dy]).toList();

    return Isolate.run(() {
      return _processDocumentIsolate(imageBytes, cornerData);
    });
  }
}

Uint8List _processFacesIsolate(
  Uint8List imageBytes,
  List<List<double>> boundingBoxes,
) {
  final original = img.decodeImage(imageBytes);
  if (original == null) throw Exception('Failed to decode image');

  for (final box in boundingBoxes) {
    final bx = box[0];
    final by = box[1];
    final bw = box[2];
    final bh = box[3];

    final padding = 0.1;
    final x = (bx - bw * padding).clamp(0, original.width - 1).toInt();
    final y = (by - bh * padding).clamp(0, original.height - 1).toInt();
    final w = (bw * (1 + padding * 2)).clamp(1, original.width - x).toInt();
    final h = (bh * (1 + padding * 2)).clamp(1, original.height - y).toInt();

    if (w <= 0 || h <= 0) continue;

    final faceCrop = img.copyCrop(original, x: x, y: y, width: w, height: h);
    final grayFace = img.grayscale(faceCrop);
    img.compositeImage(original, grayFace, dstX: x, dstY: y);
  }

  return Uint8List.fromList(img.encodePng(original));
}

Uint8List _processDocumentIsolate(
  Uint8List imageBytes,
  List<List<double>>? cornerData,
) {
  final original = img.decodeImage(imageBytes);
  if (original == null) throw Exception('Failed to decode image');

  img.Image result;

  if (cornerData != null && cornerData.length == 4) {
    result = _applyPerspectiveTransform(original, cornerData);
  } else {
    result = img.Image.from(original);
  }

  result = img.adjustColor(result, contrast: 1.4);

  result = img.grayscale(result);

  return Uint8List.fromList(img.encodePng(result));
}

img.Image _applyPerspectiveTransform(
  img.Image source,
  List<List<double>> corners,
) {
  final srcTL = corners[0];
  final srcTR = corners[1];
  final srcBR = corners[2];
  final srcBL = corners[3];

  final topWidth = _dist(srcTL, srcTR);
  final bottomWidth = _dist(srcBL, srcBR);
  final leftHeight = _dist(srcTL, srcBL);
  final rightHeight = _dist(srcTR, srcBR);

  final outWidth = max(topWidth, bottomWidth).toInt();
  final outHeight = max(leftHeight, rightHeight).toInt();

  if (outWidth <= 0 || outHeight <= 0) return source;

  final dstTL = [0.0, 0.0];
  final dstTR = [outWidth.toDouble(), 0.0];
  final dstBR = [outWidth.toDouble(), outHeight.toDouble()];
  final dstBL = [0.0, outHeight.toDouble()];

  final matrix = _computeHomography(
    [dstTL, dstTR, dstBR, dstBL],
    [srcTL, srcTR, srcBR, srcBL],
  );

  if (matrix == null) return source;

  final output = img.Image(width: outWidth, height: outHeight);

  for (int y = 0; y < outHeight; y++) {
    for (int x = 0; x < outWidth; x++) {
      final mapped = _applyHomography(matrix, x.toDouble(), y.toDouble());
      final sx = mapped[0].round();
      final sy = mapped[1].round();

      if (sx >= 0 && sx < source.width && sy >= 0 && sy < source.height) {
        output.setPixel(x, y, source.getPixel(sx, sy));
      }
    }
  }

  return output;
}

double _dist(List<double> a, List<double> b) {
  return sqrt(pow(a[0] - b[0], 2) + pow(a[1] - b[1], 2));
}

List<double>? _computeHomography(
  List<List<double>> src,
  List<List<double>> dst,
) {
  if (src.length != 4 || dst.length != 4) return null;

  final a = List<List<double>>.generate(8, (_) => List.filled(9, 0.0));

  for (int i = 0; i < 4; i++) {
    final sx = src[i][0];
    final sy = src[i][1];
    final dx = dst[i][0];
    final dy = dst[i][1];

    a[i * 2] = [-sx, -sy, -1, 0, 0, 0, sx * dx, sy * dx, dx];
    a[i * 2 + 1] = [0, 0, 0, -sx, -sy, -1, sx * dy, sy * dy, dy];
  }

  for (int col = 0; col < 8; col++) {
    int maxRow = col;
    double maxVal = a[col][col].abs();
    for (int row = col + 1; row < 8; row++) {
      if (a[row][col].abs() > maxVal) {
        maxVal = a[row][col].abs();
        maxRow = row;
      }
    }

    if (maxVal < 1e-10) return null;

    final temp = a[col];
    a[col] = a[maxRow];
    a[maxRow] = temp;

    for (int row = 0; row < 8; row++) {
      if (row == col) continue;
      final factor = a[row][col] / a[col][col];
      for (int j = col; j < 9; j++) {
        a[row][j] -= factor * a[col][j];
      }
    }
  }

  final h = List<double>.filled(9, 0.0);
  for (int i = 0; i < 8; i++) {
    h[i] = -a[i][8] / a[i][i];
  }
  h[8] = 1.0;

  return h;
}

List<double> _applyHomography(List<double> h, double x, double y) {
  final w = h[6] * x + h[7] * y + h[8];
  if (w.abs() < 1e-10) return [0, 0];
  return [
    (h[0] * x + h[1] * y + h[2]) / w,
    (h[3] * x + h[4] * y + h[5]) / w,
  ];
}
