import 'package:flutter/material.dart';
import 'package:sketchbook/models/entities/drag_handle.dart';
import 'package:sketchbook/models/entities/entity.dart';
import 'package:sketchbook/models/enums/direction_state.dart';
import 'package:sketchbook/models/enums/entity_state.dart';
import 'package:sketchbook/models/enums/z_index.dart';
import 'package:sketchbook/sketch_helpers.dart';

class Window extends Entity {
  final double thickness;
  DragHandle handleA;
  DragHandle handleB;
  DirectionState directionState = DirectionState.vertical;

  Window({
    required super.id,
    required this.thickness,
    required this.handleA,
    required this.handleB,
  }) : super(
          x: handleA.x,
          y: (handleA.y + handleB.y) / 2,
          zIndex: ZIndex.window.value,
        );

  @override
  bool contains(Offset position) {
    return SketchHelpers.distanceToLineSegment(position,
            Offset(handleA.x, handleA.y), Offset(handleB.x, handleB.y)) <
        thickness / 2 + 20;
  }

  @override
  void draw(Canvas canvas, EntityState state) {
    var paint = Paint()..color = Colors.white;
    var bgPaint = Paint()..color = Colors.black;
    var middlePaint = Paint()..color = Colors.black;
    middlePaint.strokeWidth = 2;

    bgPaint.strokeWidth = thickness + 3;
    paint.strokeWidth = thickness;

    if (state == EntityState.focused) {
      paint.color = const Color(0xFFD3E0FB);
      bgPaint.color = const Color(0xFF2463EB);
      middlePaint.color = const Color(0xFF2463EB);
    }

    // Calculate direction vector from handleA to handleB
    Offset direction = Offset(handleB.x - handleA.x, handleB.y - handleA.y);

    // Normalize the direction to get a unit vector
    double length = direction.distance;
    Offset unitDirection = direction / length;

    // Extend the background line by 2px in both directions
    Offset extendedHandleA = Offset(
      handleA.x - unitDirection.dx * 2,
      handleA.y - unitDirection.dy * 2,
    );
    Offset extendedHandleB = Offset(
      handleB.x + unitDirection.dx * 2,
      handleB.y + unitDirection.dy * 2,
    );

    // Draw the extended background line (thicker)
    canvas.drawLine(
      extendedHandleA,
      extendedHandleB,
      bgPaint,
    );

    // Draw the regular line (normal thickness)
    canvas.drawLine(
      Offset(handleA.x, handleA.y),
      Offset(handleB.x, handleB.y),
      paint,
    );

    // Draw the middle line
    canvas.drawLine(
      handleA.position(),
      handleB.position(),
      middlePaint,
    );

    // Draw the handles
    handleA.draw(canvas, state);
    handleB.draw(canvas, state);
  }

  @override
  void move(double deltaX, double deltaY) {
    handleA.move(deltaX, deltaY);
    handleB.move(deltaX, deltaY);
  }
}
