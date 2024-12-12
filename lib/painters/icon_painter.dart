import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class IconPainter extends CustomPainter {
  final Offset position;
  final ui.Image image;
  final double rotationAngle;

  IconPainter({
    required this.position,
    required this.image,
    this.rotationAngle = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (position != Offset.zero) {
      final paint = Paint();
      final imageWidth = image.width.toDouble();
      final imageHeight = image.height.toDouble();

      // Save the canvas state
      canvas.save();

      // Move the canvas to the position of the image
      canvas.translate(position.dx, position.dy);

      // Rotate the canvas by the specified angle
      canvas.rotate(rotationAngle);

      // Draw the image, centering it on the rotated canvas
      final offset = Offset(-imageWidth / 2, -imageHeight / 2);
      canvas.drawImage(image, offset, paint);

      // Restore the canvas state
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant IconPainter oldDelegate) {
    return oldDelegate.position != position ||
        oldDelegate.image != image ||
        oldDelegate.rotationAngle != rotationAngle;
  }
}
