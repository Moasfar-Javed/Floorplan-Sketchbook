import 'package:flutter/material.dart';
import 'package:sketchbook/models/entities/entity.dart';

class DragHandle extends Entity {
  static const double handleSize = 8;

  DragHandle({
    required super.id,
    required super.x,
    required super.y,
  }) : super();

  @override
  bool contains(Offset position) {
    return (position - Offset(x, y)).distance <= handleSize;
  }

  @override
  void draw(Canvas canvas, EntityState state) {
    final paint = Paint()
      ..color = state == EntityState.focused ? Colors.pink : Colors.green;

    canvas.drawCircle(Offset(x, y), handleSize, paint);
  }
}
