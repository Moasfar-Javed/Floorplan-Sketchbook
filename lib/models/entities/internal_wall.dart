import 'package:flutter/material.dart';
import 'package:sketchbook/models/entities/drag_handle.dart';
import 'package:sketchbook/models/entities/entity.dart';
import 'package:sketchbook/models/enums/entity_state.dart';
import 'package:sketchbook/models/enums/z_index.dart';
import 'package:sketchbook/sketch_helpers.dart';

class InternalWall extends Entity {
  final double thickness;
  DragHandle handleA;
  DragHandle handleB;

  InternalWall({
    required super.id,
    required this.thickness,
    required this.handleA,
    required this.handleB,
  }) : super(
          x: handleA.x,
          y: (handleA.y + handleB.y) / 2,
          zIndex: ZIndex.internalWall.value,
        );

  @override
  bool contains(Offset position) {
    return SketchHelpers.distanceToLineSegment(position,
            Offset(handleA.x, handleA.y), Offset(handleB.x, handleB.y)) <
        thickness / 2;
  }

  @override
  void draw(Canvas canvas, EntityState state) {
    var paint = Paint()..color = Colors.amber;
    paint.strokeWidth = thickness;
    if (state == EntityState.focused) {
      handleA.draw(canvas, state);
      handleB.draw(canvas, state);
    }
    canvas.drawLine(
      Offset(handleA.x, handleA.y),
      Offset(handleB.x, handleB.y),
      paint,
    );
    canvas.drawLine(
      Offset(handleA.x, handleA.y),
      Offset(handleB.x, handleB.y),
      Paint()
        ..color = Colors.transparent
        ..strokeWidth = thickness + 20,
    );
  }

  @override
  void move(double deltaX, double deltaY) {
    handleA.move(deltaX, deltaY);
    handleB.move(deltaX, deltaY);
  }
}
