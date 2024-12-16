import 'package:flutter/material.dart';
import 'package:sketchbook/models/entities/entity.dart';
import 'package:sketchbook/models/enums/entity_instance.dart';
import 'package:sketchbook/models/enums/entity_state.dart';
import 'package:sketchbook/models/enums/handle_type.dart';
import 'package:sketchbook/models/enums/parent_entity.dart';
import 'package:sketchbook/models/enums/z_index.dart';

class DragHandle extends Entity {
  double size;
  final HandleType handleType;
  final ParentEntity parentEntity;

  DragHandle({
    required super.id,
    required super.x,
    required super.y,
    required this.parentEntity,
    this.handleType = HandleType.colored,
    this.size = 6,
  }) : super(
          zIndex: ZIndex.dragHandle.value,
        );

  factory DragHandle.fromJson(
    Map<String, dynamic> json,
  ) {
    return DragHandle(
      id: json['id'],
      x: json['x'],
      y: json['y'],
      size: json['size'],
      parentEntity: ParentEntity.fromValue(json['parentEntity']),
      handleType: HandleType.fromValue(json['handleType']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'instanceType': EntityInstance.dragHandle.value,
      'x': x,
      'y': y,
      'zIndex': zIndex,
      'size': size,
      'parentEntity': parentEntity.value,
      'handleType': handleType.value,
    };
  }

  @override
  DragHandle clone() {
    return DragHandle(
      id: id,
      x: x,
      y: y,
      parentEntity: parentEntity,
      size: size,
      handleType: handleType,
    );
  }

  @override
  bool contains(Offset position) {
    double hitAreaRadius =
        size + (parentEntity == ParentEntity.window ? 5 : 20);
    return (position - Offset(x, y)).distance <= hitAreaRadius;
  }

  @override
  void draw(Canvas canvas, EntityState state) {
    final paint = Paint()
      ..color = handleType == HandleType.transparent
          ? Colors.transparent
          : Colors.white;

    canvas.drawCircle(Offset(x, y), size, paint);
  }

  void setPosition(double newX, double newY) {
    x = newX;
    y = newY;
  }
}
