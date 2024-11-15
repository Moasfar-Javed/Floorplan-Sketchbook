import 'package:flutter/material.dart';
import 'package:sketchbook/models/enums/entity_state.dart';
import 'package:sketchbook/models/enums/wall_state.dart';
import 'package:sketchbook/models/enums/z_index.dart';
import 'package:sketchbook/sketch_helpers.dart';
import 'package:sketchbook/main.dart';
import 'package:sketchbook/models/entities/drag_handle.dart';
import 'package:sketchbook/models/entities/entity.dart';



class Wall extends Entity {
  final double thickness;
  DragHandle handleA;
  DragHandle handleB;
  WallState wallState;

  Wall({
    required super.id,
    required this.thickness,
    required this.handleA,
    required this.handleB,
    this.wallState = WallState.active,
  }) : super(
          x: handleA.x,
          y: (handleA.y + handleB.y) / 2,
          zIndex: ZIndex.wall.value,
        );

  double get length => (handleB.x - handleA.x).abs();

  @override
  void draw(Canvas canvas, EntityState state) {
    var paint = Paint()..color = Colors.brown;
    paint.strokeWidth = thickness;
    if (state == EntityState.focused) {
      paint.color = Colors.blue;
    }
    if (wallState == WallState.removed) {
      paint.color = Colors.grey.shade300;
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
        ..strokeWidth = thickness + 10,
    );

    // Draw handles
    handleA.draw(canvas, state);
    handleB.draw(canvas, state);
  }

  @override
  bool contains(Offset position) {
    return SketchHelpers.distanceToLineSegment(position,
            Offset(handleA.x, handleA.y), Offset(handleB.x, handleB.y)) <
        thickness / 2;
  }

  DragHandle getClosestHandle(Offset position) {
    double distanceToLeft = (position - Offset(handleA.x, handleA.y)).distance;
    double distanceToRight = (position - Offset(handleB.x, handleB.y)).distance;

    return distanceToLeft < distanceToRight ? handleA : handleB;
  }

  @override
  void move(double deltaX, double deltaY) {
    handleA.move(deltaX, deltaY);
    handleB.move(deltaX, deltaY);
    x = handleA.x;
    y = (handleA.y + handleB.y) / 2;
  }

  (Wall, Wall) split(Wall wall, Offset position) {
    double splitX = position.dx;
    double splitY = position.dy;

    // Create two new walls at the split point
    final commonHandle = DragHandle(
      id: generateGuid(),
      x: splitX,
      y: splitY,
    );

    Wall leftWall = Wall(
        id: generateGuid(),
        thickness: wall.thickness,
        handleA: wall.handleA,
        handleB: commonHandle);

    Wall rightWall = Wall(
      id: generateGuid(),
      thickness: wall.thickness,
      handleA: commonHandle,
      handleB: wall.handleB,
    );

    return (leftWall, rightWall);
  }

  void replaceHandle(DragHandle oldHandle, DragHandle newHandle) {
    if (handleA.isEqual(oldHandle)) {
      handleA = newHandle;
    } else if (handleB.isEqual(oldHandle)) {
      handleB = newHandle;
    }
  }
}
