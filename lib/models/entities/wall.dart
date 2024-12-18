import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sketchbook/models/enums/entity_instance.dart';
import 'package:sketchbook/models/enums/entity_state.dart';
import 'package:sketchbook/models/enums/parent_entity.dart';
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

  factory Wall.fromJson(
    Map<String, dynamic> json,
    DragHandle handleA,
    DragHandle handleB,
  ) {
    return Wall(
      id: json['id'],
      thickness: json['thickness'],
      wallState: WallState.fromValue(json['wallState']),
      handleA: handleA,
      handleB: handleB,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'instanceType': EntityInstance.wall.value,
      'x': x,
      'y': y,
      'zIndex': zIndex,
      'thickness': thickness,
      'wallState': wallState.value,
      'handleA': handleA.toJson(),
      'handleB': handleB.toJson(),
    };
  }

  @override
  Wall clone() {
    return Wall(
      id: id,
      thickness: thickness,
      wallState: wallState,
      handleA: handleA.clone(),
      handleB: handleB.clone(),
    );
  }

  double get length =>
      sqrt(pow(handleB.x - handleA.x, 2) + pow(handleB.y - handleA.y, 2));

  @override
  bool contains(Offset position) {
    return SketchHelpers.distanceToLineSegment(position,
            Offset(handleA.x, handleA.y), Offset(handleB.x, handleB.y)) <
        thickness / 2 + 10;
  }

  DragHandle getClosestHandle(Offset position) {
    double distanceToLeft = (position - Offset(handleA.x, handleA.y)).distance;
    double distanceToRight = (position - Offset(handleB.x, handleB.y)).distance;

    return distanceToLeft < distanceToRight ? handleA : handleB;
  }

  @override
  void move(double deltaX, double deltaY) {
    final perpVector = getPerpendicularDirectionVector(this);

    // normalized perpendicular vector
    final double perpLength =
        sqrt(perpVector.dx * perpVector.dx + perpVector.dy * perpVector.dy);
    final double unitPerpDx = perpVector.dx / perpLength;
    final double unitPerpDy = perpVector.dy / perpLength;

    // project the movement onto the perpendicular vector
    final double projection = deltaX * unitPerpDx + deltaY * unitPerpDy;
    final double projectedDeltaX = projection * unitPerpDx;
    final double projectedDeltaY = projection * unitPerpDy;

    handleA.move(projectedDeltaX, projectedDeltaY);
    handleB.move(projectedDeltaX, projectedDeltaY);

    x = handleA.x;
    y = (handleA.y + handleB.y) / 2;
  }

  static double getAngle(Wall entity) {
    return atan2(entity.handleB.y - entity.handleA.y,
        entity.handleB.x - entity.handleA.x);
  }

  @override
  void draw(Canvas canvas, EntityState state, double gridScaleFactor) {
    if (wallState == WallState.removed) {
      var paint = Paint()
        ..color = state == EntityState.focused
            ? Colors.grey.shade500
            : Colors.grey.shade300
        ..strokeWidth = thickness
        ..style = PaintingStyle.stroke;

      _drawDashedLine(canvas, paint, handleA.position(), handleB.position(),
          dashLength: 20, gapLength: 5);
    } else {
      var paint = Paint()
        ..color = Colors.black
        ..strokeWidth = thickness;

      // If the entity is focused, draw the blue line with a black border
      if (state == EntityState.focused) {
        paint.color = const Color(0xFFA7C1F7); // Light blue color
        final borderPaint = Paint()..color = Colors.black;
        borderPaint.strokeWidth = thickness + 3; // Border width
        canvas.drawLine(
          Offset(handleA.x, handleA.y),
          Offset(handleB.x, handleB.y),
          borderPaint,
        );
      } else if (state == EntityState.relativePerpendicular) {
        paint.color = const Color.fromARGB(255, 2, 179, 85); // Light blue color
        final borderPaint = Paint()..color = paint.color;
        borderPaint.strokeWidth = thickness; // Border width
        canvas.drawLine(
          Offset(handleA.x, handleA.y),
          Offset(handleB.x, handleB.y),
          borderPaint,
        );
      }
      canvas.drawLine(
        Offset(handleA.x, handleA.y),
        Offset(handleB.x, handleB.y),
        paint,
      );
    }

    // Draw handles (unchanged)
    handleA.draw(canvas, state, gridScaleFactor);
    handleB.draw(canvas, state, gridScaleFactor);
  }

  // Helper function to draw a dashed line
  void _drawDashedLine(Canvas canvas, Paint paint, Offset start, Offset end,
      {double dashLength = 10.0, double gapLength = 5.0}) {
    final totalDistance = (end - start).distance;
    final dashAndGapLength = dashLength + gapLength;
    final dashCount = (totalDistance / dashAndGapLength).floor();

    // Direction vector from start to end
    final direction = (end - start) / totalDistance;

    for (int i = 0; i < dashCount; i++) {
      final dashStart = start + direction * (i * dashAndGapLength);
      final dashEnd = dashStart + direction * dashLength;

      // Draw each dash
      canvas.drawLine(dashStart, dashEnd, paint);
    }

    // Draw the final dash if needed
    final remainingDistance = totalDistance - (dashCount * dashAndGapLength);
    if (remainingDistance > dashLength) {
      final lastDashStart = start + direction * (dashCount * dashAndGapLength);
      final lastDashEnd = lastDashStart + direction * dashLength;
      canvas.drawLine(lastDashStart, lastDashEnd, paint);
    }
  }

  (Wall, Wall) split(Wall wall) {
    Offset center = getCenter(wall);

    final commonHandle = DragHandle(
      id: generateGuid(),
      x: center.dx,
      y: center.dy,
      parentEntity: ParentEntity.wall,
    );

    Wall leftWall = Wall(
      id: generateGuid(),
      thickness: wall.thickness,
      handleA: wall.handleA,
      handleB: commonHandle,
    );

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

  static Offset getCenter(wall) {
    return Offset((wall.handleA.x + wall.handleB.x) / 2,
        (wall.handleA.y + wall.handleB.y) / 2);
  }

  static Offset getPerpendicularDirectionVector(Wall wall) {
    final double wallDx = wall.handleB.x - wall.handleA.x;
    final double wallDy = wall.handleB.y - wall.handleA.y;

    final double perpDx = -wallDy;
    final double perpDy = wallDx;
    return Offset(perpDx, perpDy);
  }
}
