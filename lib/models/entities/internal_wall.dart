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
  void move(double deltaX, double deltaY) {
    handleA.move(deltaX, deltaY);
    handleB.move(deltaX, deltaY);
  }

  static double getAngle(InternalWall entity) {
    return atan2(entity.handleB.y - entity.handleA.y,
        entity.handleB.x - entity.handleA.x);
  }
}
