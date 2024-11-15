import 'package:flutter/material.dart';
import 'package:sketchbook/main.dart';
import 'package:sketchbook/models/drag_handle.dart';
import 'package:sketchbook/models/entity.dart';

class Wall extends Entity {
  final double thickness;
  final DragHandle leftHandle;
  final DragHandle rightHandle;

  Wall({
    required super.id,
    required this.thickness,
    required this.leftHandle,
    required this.rightHandle,
  }) : super(
          x: leftHandle.x,
          y: (leftHandle.y + rightHandle.y) / 2,
        );

  double get length => (rightHandle.x - leftHandle.x).abs();

  @override
  void draw(Canvas canvas, EntityState state) {
    var paint = Paint()..color = Colors.brown;
    paint.strokeWidth = thickness;
    if (state == EntityState.focused) {
      paint.color = Colors.blue;
    }
    canvas.drawLine(
      Offset(leftHandle.x, leftHandle.y),
      Offset(rightHandle.x, rightHandle.y),
      paint,
    );

    // Draw handles
    leftHandle.draw(canvas, state);
    rightHandle.draw(canvas, state);
  }

  @override
  bool contains(Offset position) {
    return _distanceToLineSegment(position, Offset(leftHandle.x, leftHandle.y),
            Offset(rightHandle.x, rightHandle.y)) <
        thickness / 2;
  }

  DragHandle getClosestHandle(Offset position) {
    double distanceToLeft =
        (position - Offset(leftHandle.x, leftHandle.y)).distance;
    double distanceToRight =
        (position - Offset(rightHandle.x, rightHandle.y)).distance;

    return distanceToLeft < distanceToRight ? leftHandle : rightHandle;
  }

  @override
  void move(double deltaX, double deltaY) {
    leftHandle.move(deltaX, deltaY);
    rightHandle.move(deltaX, deltaY);
    x = leftHandle.x;
    y = (leftHandle.y + rightHandle.y) / 2;
  }

  (Wall, Wall) split(Wall wall, Offset position) {
    double splitX = position.dx;
    double splitY = position.dy;

    // Create two new walls at the split point
    Wall leftWall = Wall(
      id: generateGuid(),
      thickness: wall.thickness,
      leftHandle: DragHandle(
        id: generateGuid(),
        x: wall.leftHandle.x,
        y: wall.leftHandle.y,
      ),
      rightHandle: DragHandle(
        id: generateGuid(),
        x: splitX,
        y: splitY,
      ),
    );

    Wall rightWall = Wall(
      id: generateGuid(),
      thickness: wall.thickness,
      leftHandle: DragHandle(
        id: generateGuid(),
        x: splitX,
        y: splitY,
      ),
      rightHandle: DragHandle(
        id: generateGuid(),
        x: wall.rightHandle.x,
        y: wall.rightHandle.y,
      ),
    );

    return (leftWall, rightWall);
  }

  // Helper method to calculate the distance from a point to a line segment
  double _distanceToLineSegment(
      Offset point, Offset lineStart, Offset lineEnd) {
    // Handle the case where the line start and end are the same point (no distance)
    if (lineStart == lineEnd) {
      return (point - lineStart).distance;
    }

    // Project the point onto the line defined by lineStart and lineEnd
    double lineLength = (lineEnd - lineStart).distance;
    double t = ((point.dx - lineStart.dx) * (lineEnd.dx - lineStart.dx) +
            (point.dy - lineStart.dy) * (lineEnd.dy - lineStart.dy)) /
        (lineLength * lineLength);

    // Clamp t to stay within the bounds of the line segment
    t = t.clamp(0.0, 1.0);

    // Calculate the point on the line closest to the given point
    Offset closestPoint = Offset(
      lineStart.dx + t * (lineEnd.dx - lineStart.dx),
      lineStart.dy + t * (lineEnd.dy - lineStart.dy),
    );

    // Return the distance from the point to the closest point on the line segment
    return (point - closestPoint).distance;
  }
}
