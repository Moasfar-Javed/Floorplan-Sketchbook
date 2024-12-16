import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sketchbook/models/entities/drag_handle.dart';
import 'package:sketchbook/models/entities/entity.dart';
import 'package:sketchbook/models/enums/entity_instance.dart';
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

  double get length =>
      sqrt(pow(handleB.x - handleA.x, 2) + pow(handleB.y - handleA.y, 2));

  factory InternalWall.fromJson(
    Map<String, dynamic> json,
  ) {
    return InternalWall(
      id: json['id'],
      thickness: json['thickness'],
      handleA: DragHandle.fromJson(json['handleA']),
      handleB: DragHandle.fromJson(json['handleB']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'instanceType': EntityInstance.internalWall.value,
      'x': x,
      'y': y,
      'zIndex': zIndex,
      'thickness': thickness,
      'handleA': handleA.toJson(),
      'handleB': handleB.toJson(),
    };
  }

  @override
  InternalWall clone() {
    return InternalWall(
      id: id,
      thickness: thickness,
      handleA: handleA.clone(),
      handleB: handleB.clone(),
    );
  }

  @override
  bool contains(Offset position) {
    return SketchHelpers.distanceToLineSegment(position,
            Offset(handleA.x, handleA.y), Offset(handleB.x, handleB.y)) <
        thickness / 2 + 10;
  }

  @override
  void draw(Canvas canvas, EntityState state) {
    var paint = Paint()..color = Colors.black;
    if (state == EntityState.focused) {
      paint.color = const Color(0xFFA7C1F7);
    }
    paint.strokeWidth = thickness;

    canvas.drawLine(
      Offset(handleA.x, handleA.y),
      Offset(handleB.x, handleB.y),
      paint,
    );

    handleA.draw(canvas, state);
    handleB.draw(canvas, state);
  }

  @override
  void move(double deltaX, double deltaY) {
    handleA.move(deltaX, deltaY);
    handleB.move(deltaX, deltaY);
  }

  static double getAngle(InternalWall entity) {
    return atan2(entity.handleB.y - entity.handleA.y,
        entity.handleB.x - entity.handleA.x);
  }

  void rotate(double angle, String handleId) {
    // Choose the handle to rotate based on the id
    if (handleId == handleA.id) {
      // If rotating handleA, rotate handleB (relative to handleA)
      _rotateHandle(handleB, angle, handleA);
    } else if (handleId == handleB.id) {
      // If rotating handleB, rotate handleA (relative to handleB)
      _rotateHandle(handleA, angle, handleB);
    }
  }

  // Helper method to rotate a handle around the other
  void _rotateHandle(
      DragHandle handleToMove, double angle, DragHandle pivotHandle) {
    double dx = handleToMove.x - pivotHandle.x;
    double dy = handleToMove.y - pivotHandle.y;

    // Apply rotation formula
    double newX = pivotHandle.x + dx * cos(angle) - dy * sin(angle);
    double newY = pivotHandle.y + dx * sin(angle) + dy * cos(angle);

    // Update the handle's position
    handleToMove.x = newX;
    handleToMove.y = newY;

    // Maintain the length by adjusting the other handle (if necessary)
    double currentLength = length;
    double newLength =
        currentLength; // The length should stay the same after rotation.

    // Recalculate handle B position based on the new length and the new angle
    if (handleToMove == handleA) {
      double dx = handleB.x - handleA.x;
      double dy = handleB.y - handleA.y;
      double angleB = atan2(dy, dx);
      handleB.x = handleA.x + cos(angleB) * newLength;
      handleB.y = handleA.y + sin(angleB) * newLength;
    } else {
      double dx = handleA.x - handleB.x;
      double dy = handleA.y - handleB.y;
      double angleA = atan2(dy, dx);
      handleA.x = handleB.x + cos(angleA) * newLength;
      handleA.y = handleB.y + sin(angleA) * newLength;
    }
  }
}
