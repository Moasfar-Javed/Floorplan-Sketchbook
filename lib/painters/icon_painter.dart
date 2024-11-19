import 'package:flutter/material.dart';

class IconPainter extends CustomPainter {
  final Offset position;
  final Icon icon;
  final Offset cameraOffset;

  IconPainter({
    required this.position,
    required this.icon,
    required this.cameraOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(cameraOffset.dx, cameraOffset.dy);
    if (position != Offset.zero) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.icon!.codePoint),
          style: TextStyle(
            fontSize: icon.size ?? 24,
            fontFamily: icon.icon!.fontFamily,
            package: icon.icon!.fontPackage,
            color: icon.color ?? Colors.black,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      // Draw the icon at the specified position
      final offset =
          position - Offset(textPainter.width / 2, textPainter.height / 2);
      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant IconPainter oldDelegate) {
    return oldDelegate.position != position || oldDelegate.icon != icon;
  }
}
