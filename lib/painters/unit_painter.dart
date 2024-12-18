import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sketchbook/models/entities/internal_wall.dart';
import 'package:sketchbook/models/entities/wall.dart';
import 'package:sketchbook/models/enums/unit.dart';
import 'package:sketchbook/sketch_helpers.dart';

/// A CustomPainter to render parallel lines to walls with some spacing
/// to indicate their unit size
class UnitPainter extends CustomPainter {
  final double scaleFactor;
  final List<Wall> walls;
  final List<InternalWall> internalWalls;
  final double spacing; // Spacing between a wall and a parallel unit line
  final Unit unit;
  Path? wallsPath; // The closed path formed by the walls

  UnitPainter({
    required this.scaleFactor,
    required this.walls,
    required this.internalWalls,
    required this.unit,
    this.spacing = 15.0,
  });

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = const Color(0xFF6C757D)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    _drawWallUnitLines(canvas, paint);
    _drawInternalWallUnitLines(canvas, paint);
  }

  void _drawWallUnitLines(Canvas canvas, Paint paint) {
    wallsPath = _getWallsPath();

    for (var wall in walls) {
      // final textPainter = _getTextPainter(wall.id);
      final textPainter = _getTextPainter(wall.length);

      // Generate the initial parallel path
      Path parallelPath = _getParallelLine(
        Offset(wall.handleA.x, wall.handleA.y),
        Offset(wall.handleB.x, wall.handleB.y),
        spacing,
        textPainter.width,
      );

      // Adjust path if it intersects the wallsPath
      // - unit line should not be on the inner side of the wall's closed loop
      if (_isParallelLineInsidePath(parallelPath)) {
        parallelPath = _getParallelLine(
          Offset(wall.handleA.x, wall.handleA.y),
          Offset(wall.handleB.x, wall.handleB.y),
          -spacing,
          textPainter.width,
        );
      }

      PathMetric pathMetric = parallelPath.computeMetrics().first;
      Tangent? startTangent = pathMetric.getTangentForOffset(0.0);
      Tangent? endTangent = pathMetric.getTangentForOffset(pathMetric.length);

      if (startTangent != null && endTangent != null) {
        final totalLength = pathMetric.length;
        final textWidth = textPainter.width;
        final whiteStart = (totalLength - textWidth - 10) / 2;
        final whiteEnd = whiteStart + textWidth + 10;

        // Hoop that we must jump through to show a gap in the path
        // for our text to match the design
        final Paint mainPaint = Paint()
          ..color = paint.color
          ..strokeWidth = paint.strokeWidth
          ..style = PaintingStyle.stroke;

        final Paint whitePaint = Paint()
          ..color = const Color(0xFFD3E0FB).withOpacity(0)
          ..strokeWidth = paint.strokeWidth
          ..style = PaintingStyle.stroke;

        canvas.drawPath(pathMetric.extractPath(0, whiteStart), mainPaint);
        canvas.drawPath(
            pathMetric.extractPath(whiteEnd, totalLength), mainPaint);
        canvas.drawPath(
            pathMetric.extractPath(whiteStart, whiteEnd), whitePaint);

        // Draw text and terminators
        Offset midpoint =
            _calculateMidpoint(startTangent.position, endTangent.position);
        double angle = atan2(
          endTangent.position.dy - startTangent.position.dy,
          endTangent.position.dx - startTangent.position.dx,
        );
        _drawTextAtPoint(canvas, midpoint, paint, angle, textPainter);

        _drawTerminatorAtPoint(
          canvas,
          startTangent.position.dx,
          startTangent.position.dy,
          paint,
          atan2(startTangent.vector.dy, startTangent.vector.dx),
        );

        _drawTerminatorAtPoint(
          canvas,
          endTangent.position.dx,
          endTangent.position.dy,
          paint,
          atan2(endTangent.vector.dy, endTangent.vector.dx),
        );
      }
    }
  }

  void _drawInternalWallUnitLines(Canvas canvas, Paint paint) {
    wallsPath = _getWallsPath();

    for (var wall in internalWalls) {
      final textPainter = _getTextPainter(wall.length);

      // Generate the initial parallel path
      Path parallelPath = _getParallelLine(
        Offset(wall.handleA.x, wall.handleA.y),
        Offset(wall.handleB.x, wall.handleB.y),
        -spacing,
        textPainter.width,
      );

      PathMetric pathMetric = parallelPath.computeMetrics().first;
      Tangent? startTangent = pathMetric.getTangentForOffset(0.0);
      Tangent? endTangent = pathMetric.getTangentForOffset(pathMetric.length);

      if (startTangent != null && endTangent != null) {
        final totalLength = pathMetric.length;
        final textWidth = textPainter.width;
        final whiteStart = (totalLength - textWidth - 10) / 2;
        final whiteEnd = whiteStart + textWidth + 10;

        // Hoop that we must jump through to show a gap in the path
        // for our text to match the design
        final Paint mainPaint = Paint()
          ..color = paint.color
          ..strokeWidth = paint.strokeWidth
          ..style = PaintingStyle.stroke;

        final Paint whitePaint = Paint()
          ..color = const Color(0xFFD3E0FB).withOpacity(0)
          ..strokeWidth = paint.strokeWidth
          ..style = PaintingStyle.stroke;

        canvas.drawPath(pathMetric.extractPath(0, whiteStart), mainPaint);
        canvas.drawPath(
            pathMetric.extractPath(whiteEnd, totalLength), mainPaint);
        canvas.drawPath(
            pathMetric.extractPath(whiteStart, whiteEnd), whitePaint);

        // Draw text and terminators
        Offset midpoint =
            _calculateMidpoint(startTangent.position, endTangent.position);
        double angle = atan2(
          endTangent.position.dy - startTangent.position.dy,
          endTangent.position.dx - startTangent.position.dx,
        );
        _drawTextAtPoint(canvas, midpoint, paint, angle, textPainter);

        _drawTerminatorAtPoint(
          canvas,
          startTangent.position.dx,
          startTangent.position.dy,
          paint,
          atan2(startTangent.vector.dy, startTangent.vector.dx),
        );

        _drawTerminatorAtPoint(
          canvas,
          endTangent.position.dx,
          endTangent.position.dy,
          paint,
          atan2(endTangent.vector.dy, endTangent.vector.dx),
        );
      }
    }
  }

  /// Creates a parallel line with given spacing and text width
  Path _getParallelLine(
      Offset start, Offset end, double spacing, double textWidth) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = sqrt(dx * dx + dy * dy);

    const padding = 0.2;
    final adjustedLength = length * (1 - padding);

    final directionX = dx / length;
    final directionY = dy / length;

    final offsetStart = Offset(
      start.dx + directionX * (length - adjustedLength) * padding,
      start.dy + directionY * (length - adjustedLength) * padding,
    );

    final offsetEnd = Offset(
      end.dx - directionX * (length - adjustedLength) * padding,
      end.dy - directionY * (length - adjustedLength) * padding,
    );

    final normalX = -dy / length;
    final normalY = dx / length;

    final parallelStart = Offset(
      offsetStart.dx + normalX * spacing,
      offsetStart.dy + normalY * spacing,
    );

    final parallelEnd = Offset(
      offsetEnd.dx + normalX * spacing,
      offsetEnd.dy + normalY * spacing,
    );

    return Path()
      ..moveTo(parallelStart.dx, parallelStart.dy)
      ..lineTo(parallelEnd.dx, parallelEnd.dy);
  }

  /// Draws a path terminator (a short line) at a given point.
  void _drawTerminatorAtPoint(
      Canvas canvas, double x, double y, Paint paint, double angle) {
    const double length = 8;
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle);
    canvas.drawLine(
        const Offset(0, -length / 2), const Offset(0, length / 2), paint);
    canvas.restore();
  }

  /// Calculates the midpoint between two points
  Offset _calculateMidpoint(Offset start, Offset end) {
    return Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
  }

  /// Prepares a TextPainter for rendering text, scaling the font size based on the scale factor
  TextPainter _getTextPainter(dynamic text) {
    double baseFontSize = 12.0; // Base font size (before scaling)
    double scaledFontSize = baseFontSize / scaleFactor; // Scale the font size

    scaledFontSize = scaledFontSize.clamp(10.0, 24.0);

    return TextPainter(
      text: TextSpan(
        text: SketchHelpers.distancePxToUnit(text, unit),
        style: TextStyle(
          color: const Color(0xFF2463EB),
          fontSize: scaledFontSize,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
  }

  /// Draws text at a specified point with rotation
  void _drawTextAtPoint(Canvas canvas, Offset point, Paint paint, double angle,
      TextPainter textPainter) {
    canvas.save();
    canvas.translate(point.dx, point.dy);
    canvas.rotate(angle);
    textPainter.paint(
        canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
    canvas.restore();
  }

  /// Checks if the parallel line intersects the wallsPath
  bool _isParallelLineInsidePath(Path parallelPath) {
    if (wallsPath == null) return false;

    const margin = 10.0;

    for (var metric in parallelPath.computeMetrics()) {
      final startPosition = metric.getTangentForOffset(0.0)?.position;
      final endPosition = metric.getTangentForOffset(metric.length)?.position;

      if (startPosition != null && endPosition != null) {
        final midPoint = _calculateMidpoint(startPosition, endPosition);
        if (_isPointInsideWithMargin(startPosition, margin) ||
            _isPointInsideWithMargin(midPoint, margin) ||
            _isPointInsideWithMargin(endPosition, margin)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Checks if a point is inside the wallsPath or near it
  bool _isPointInsideWithMargin(Offset point, double margin) {
    if (wallsPath!.contains(point)) return true;

    for (var metric in wallsPath!.computeMetrics()) {
      final distance =
          metric.getTangentForOffset(0.0)?.position.distance ?? double.infinity;
      if (distance <= margin) return true;
    }
    return false;
  }

  /// Creates the path connecting the walls
  /// **[SHOULD BE KEPT THE SAME AS IN BASE PAINTER]
  Path? _getWallsPath() {
    Path path = Path();
    Set<int> visitedWalls = <int>{};
    Wall? currentWall = walls.firstOrNull;

    if (currentWall != null) {
      while (currentWall != null && visitedWalls.length < walls.length + 1) {
        path.lineTo(currentWall.handleA.x, currentWall.handleA.y);
        visitedWalls.add(currentWall.hashCode);

        currentWall = walls
            .where((wall) =>
                !visitedWalls.contains(wall.hashCode) &&
                (wall.handleA.id == currentWall?.handleB.id ||
                    wall.handleB.id == currentWall?.handleB.id))
            .firstOrNull;
      }
    }

    path.close();
    return path;
  }
}
