import 'dart:typed_data';
import 'dart:isolate';
import 'package:image/image.dart' as img;

class ImageUtils {
  ImageUtils._();

  static const int maxDimension = 4000;

  static Future<Uint8List> ensureReasonableSize(Uint8List imageBytes) async {
    return Isolate.run(() {
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) return imageBytes;

      if (decoded.width <= maxDimension && decoded.height <= maxDimension) {
        return imageBytes;
      }

      final resized = img.copyResize(
        decoded,
        width: decoded.width > decoded.height ? maxDimension : null,
        height: decoded.height >= decoded.width ? maxDimension : null,
        interpolation: img.Interpolation.linear,
      );

      return Uint8List.fromList(img.encodePng(resized));
    });
  }

  static Future<Uint8List> generateThumbnail(
    Uint8List imageBytes, {
    int size = 200,
    int quality = 80,
  }) async {
    return Isolate.run(() {
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) return imageBytes;

      final thumbnail = img.copyResizeCropSquare(decoded, size: size);
      return Uint8List.fromList(img.encodeJpg(thumbnail, quality: quality));
    });
  }
}
