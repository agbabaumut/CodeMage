import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;

class EdgeDetectionService {
  Future<List<ui.Offset>?> detectDocumentEdges(Uint8List imageBytes) async {
    final result = await Isolate.run(() => _detectEdgesIsolate(imageBytes));
    if (result == null) return null;
    return result
        .map((pair) => ui.Offset(pair[0], pair[1]))
        .toList();
  }
}

List<List<double>>? _detectEdgesIsolate(Uint8List imageBytes) {
  final original = img.decodeImage(imageBytes);
  if (original == null) return null;

  final w = original.width;
  final h = original.height;

  final gray = img.grayscale(img.Image.from(original));
  final blurred = img.gaussianBlur(gray, radius: 2);
  final edges = img.sobel(blurred);

  const brightnessThreshold = 80;
  const densityThreshold = 0.08;

  int topY = 0;
  for (int y = 0; y < h; y++) {
    int count = 0;
    for (int x = 0; x < w; x++) {
      final pixel = edges.getPixel(x, y);
      final luminance = img.getLuminance(pixel);
      if (luminance > brightnessThreshold) count++;
    }
    if (count > w * densityThreshold) {
      topY = y;
      break;
    }
  }

  int bottomY = h - 1;
  for (int y = h - 1; y >= 0; y--) {
    int count = 0;
    for (int x = 0; x < w; x++) {
      final pixel = edges.getPixel(x, y);
      final luminance = img.getLuminance(pixel);
      if (luminance > brightnessThreshold) count++;
    }
    if (count > w * densityThreshold) {
      bottomY = y;
      break;
    }
  }

  int leftX = 0;
  for (int x = 0; x < w; x++) {
    int count = 0;
    for (int y = 0; y < h; y++) {
      final pixel = edges.getPixel(x, y);
      final luminance = img.getLuminance(pixel);
      if (luminance > brightnessThreshold) count++;
    }
    if (count > h * densityThreshold) {
      leftX = x;
      break;
    }
  }

  int rightX = w - 1;
  for (int x = w - 1; x >= 0; x--) {
    int count = 0;
    for (int y = 0; y < h; y++) {
      final pixel = edges.getPixel(x, y);
      final luminance = img.getLuminance(pixel);
      if (luminance > brightnessThreshold) count++;
    }
    if (count > h * densityThreshold) {
      rightX = x;
      break;
    }
  }

  final docWidth = rightX - leftX;
  final docHeight = bottomY - topY;

  if (docWidth < w * 0.1 || docHeight < h * 0.1) {
    return null;
  }

  final padX = docWidth * 0.02;
  final padY = docHeight * 0.02;

  final l = (leftX - padX).clamp(0, w - 1).toDouble();
  final t = (topY - padY).clamp(0, h - 1).toDouble();
  final r = (rightX + padX).clamp(0, w - 1).toDouble();
  final b = (bottomY + padY).clamp(0, h - 1).toDouble();

  return [
    [l, t],
    [r, t],
    [r, b],
    [l, b],
  ];
}
