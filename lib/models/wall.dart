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
  double _distanceToLineSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final ap = p - a;
    double t =
        (ap.dx * ab.dx + ap.dy * ab.dy) / (ab.dx * ab.dx + ab.dy * ab.dy);
    t = t.clamp(0.0, 1.0); // Clamp t to be between 0 and 1
    final closestPoint = Offset(a.dx + t * ab.dx, a.dy + t * ab.dy);
    return (p - closestPoint).distance;
  }
}
