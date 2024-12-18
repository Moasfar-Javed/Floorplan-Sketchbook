import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sketchbook/extensions.dart';
import 'package:sketchbook/models/entities/drag_handle.dart';
import 'package:sketchbook/models/entities/entity.dart';
import 'package:sketchbook/models/entities/wall.dart';
import 'package:sketchbook/models/enums/entity_instance.dart';
import 'package:sketchbook/models/enums/entity_state.dart';
import 'package:sketchbook/models/enums/z_index.dart';
import 'package:sketchbook/sketch_helpers.dart';

class Window extends Entity {
  final double thickness;
  DragHandle handleA;
  DragHandle handleB;

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

  factory Window.fromJson(
    Map<String, dynamic> json,
  ) {
    return Window(
      id: json['id'],
      thickness: json['thickness'],
      handleA: DragHandle.fromJson(json['handleA']),
      handleB: DragHandle.fromJson(json['handleB']),
    );
  }

  double get length =>
      sqrt(pow(handleB.x - handleA.x, 2) + pow(handleB.y - handleA.y, 2));

  static double getAngle(Window entity) {
    return atan2(entity.handleB.y - entity.handleA.y,
        entity.handleB.x - entity.handleA.x);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'instanceType': EntityInstance.window.value,
      'x': x,
      'y': y,
      'zIndex': zIndex,
      'thickness': thickness,
      'handleA': handleA.toJson(),
      'handleB': handleB.toJson(),
    };
  }

  @override
  Window clone() {
    return Window(
        id: id,
        thickness: thickness,
        handleA: handleA.clone(),
        handleB: handleB.clone());
  }

  @override
  bool contains(Offset position) {
    return SketchHelpers.distanceToLineSegment(position,
            Offset(handleA.x, handleA.y), Offset(handleB.x, handleB.y)) <
        thickness / 2 + 20;
  }

  @override
  void draw(Canvas canvas, EntityState state, double gridScaleFactor) {
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

    double length = direction.distance;
    if (length == 0) {
      return;
    }

    Offset unitDirection = direction / length;

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
    handleA.draw(canvas, state, gridScaleFactor);
    handleB.draw(canvas, state, gridScaleFactor);
  }

  @override
  void move(double deltaX, double deltaY) {
    handleA.move(deltaX, deltaY);
    handleB.move(deltaX, deltaY);
  }

  void snapToClosestWall(List<Wall> walls) {
    double originalLength =
        Offset(handleB.x - handleA.x, handleB.y - handleA.y).distance;
    if (walls.isEmpty) return;

    // Calculate the midpoint and direction vector of the window
    double windowMidX = (handleA.x + handleB.x) / 2;
    double windowMidY = (handleA.y + handleB.y) / 2;

    Wall? closestWall;
    double minDistance = double.infinity;

    for (Wall wall in walls) {
      double distanceToWall = SketchHelpers.distanceToLineSegment(
        Offset(windowMidX, windowMidY),
        Offset(wall.handleA.x, wall.handleA.y),
        Offset(wall.handleB.x, wall.handleB.y),
      );

      if (distanceToWall < minDistance) {
        minDistance = distanceToWall;
        closestWall = wall;
      }
    }

    if (closestWall == null) return;

    // Align the midpoint of the window to the closest wall's center
    Offset wallCenter = Wall.getCenter(closestWall);
    double alignmentOffsetX = wallCenter.dx - windowMidX;
    double alignmentOffsetY = wallCenter.dy - windowMidY;

    handleA.x += alignmentOffsetX;
    handleA.y += alignmentOffsetY;
    handleB.x += alignmentOffsetX;
    handleB.y += alignmentOffsetY;

    // Calculate the closest wall's direction vector
    Offset wallDirection = Offset(
      closestWall.handleB.x - closestWall.handleA.x,
      closestWall.handleB.y - closestWall.handleA.y,
    ).normalize();

    // // Adjust the direction of the window to match the wall's direction
    Offset newDirection = wallDirection * originalLength;

    // // Recompute handle positions to match the wall’s direction and maintain length
    handleB.x = handleA.x + newDirection.dx;
    handleB.y = handleA.y + newDirection.dy;
  }
}
