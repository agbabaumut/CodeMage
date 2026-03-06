import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class CameraOverlayPainter extends CustomPainter {
  final List<Face>? faces;
  final RecognizedText? recognizedText;
  final Size imageSize;
  final Size canvasSize;
  final InputImageRotation rotation;
  final bool isFrontCamera;

  CameraOverlayPainter({
    this.faces,
    this.recognizedText,
    required this.imageSize,
    required this.canvasSize,
    this.rotation = InputImageRotation.rotation0deg,
    this.isFrontCamera = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (faces != null && faces!.isNotEmpty) {
      _paintFaces(canvas, size);
    }

    if (recognizedText != null && recognizedText!.blocks.isNotEmpty) {
      _paintTextBlocks(canvas, size);
    }
  }

  void _paintFaces(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF69F0AE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final labelPaint = Paint()
      ..color = const Color(0xFF69F0AE).withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    for (final face in faces!) {
      final rect = _scaleRect(face.boundingBox, size);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

      canvas.drawRRect(rrect, paint);

      _drawCornerMarkers(canvas, rect, paint);

      final labelRect = Rect.fromLTWH(rect.left, rect.top - 24, 60, 22);
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(4)),
        labelPaint,
      );

      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'Face',
          style: TextStyle(
            color: Color(0xFF69F0AE),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(rect.left + 8, rect.top - 22));
    }
  }

  void _paintTextBlocks(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF42A5F5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final boundaryPaint = Paint()
      ..color = const Color(0xFF42A5F5).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    for (final block in recognizedText!.blocks) {
      final rect = _scaleRect(block.boundingBox, size);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        paint,
      );
    }

    if (recognizedText!.blocks.length >= 3) {
      double minX = double.infinity;
      double minY = double.infinity;
      double maxX = double.negativeInfinity;
      double maxY = double.negativeInfinity;

      for (final block in recognizedText!.blocks) {
        final rect = _scaleRect(block.boundingBox, size);
        if (rect.left < minX) minX = rect.left;
        if (rect.top < minY) minY = rect.top;
        if (rect.right > maxX) maxX = rect.right;
        if (rect.bottom > maxY) maxY = rect.bottom;
      }

      final docRect = Rect.fromLTRB(minX - 8, minY - 8, maxX + 8, maxY + 8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(docRect, const Radius.circular(12)),
        boundaryPaint,
      );

      final docBorderPaint = Paint()
        ..color = const Color(0xFF42A5F5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      canvas.drawRRect(
        RRect.fromRectAndRadius(docRect, const Radius.circular(12)),
        docBorderPaint,
      );

      _drawCornerMarkers(canvas, docRect, docBorderPaint);
    }
  }

  void _drawCornerMarkers(Canvas canvas, Rect rect, Paint paint) {
    final markerLength = rect.width.clamp(10, 30).toDouble();
    final cornerPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(markerLength, 0), cornerPaint);
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(0, markerLength), cornerPaint);

    canvas.drawLine(rect.topRight, rect.topRight + Offset(-markerLength, 0), cornerPaint);
    canvas.drawLine(rect.topRight, rect.topRight + Offset(0, markerLength), cornerPaint);

    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + Offset(markerLength, 0), cornerPaint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + Offset(0, -markerLength), cornerPaint);

    canvas.drawLine(rect.bottomRight, rect.bottomRight + Offset(-markerLength, 0), cornerPaint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + Offset(0, -markerLength), cornerPaint);
  }

  Rect _scaleRect(Rect rect, Size size) {
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;

    double left, top, right, bottom;

    if (isFrontCamera) {
      left = size.width - rect.right * scaleX;
      right = size.width - rect.left * scaleX;
    } else {
      left = rect.left * scaleX;
      right = rect.right * scaleX;
    }

    top = rect.top * scaleY;
    bottom = rect.bottom * scaleY;

    return Rect.fromLTRB(
      left.clamp(0, size.width),
      top.clamp(0, size.height),
      right.clamp(0, size.width),
      bottom.clamp(0, size.height),
    );
  }

  @override
  bool shouldRepaint(CameraOverlayPainter oldDelegate) {
    return oldDelegate.faces != faces ||
        oldDelegate.recognizedText != recognizedText;
  }
}
