import 'package:flutter/material.dart';
import 'package:sketchbook/models/entities/entity.dart';
import 'package:sketchbook/models/enums/entity_state.dart';
import 'package:sketchbook/models/enums/handle_type.dart';
import 'package:sketchbook/models/enums/parent_entity.dart';
import 'package:sketchbook/models/enums/z_index.dart';

class DragHandle extends Entity {
  static const double handleSize = 8;
  final HandleType handleType;
  final ParentEntity parentEntity;

  DragHandle({
    required super.id,
    required super.x,
    required super.y,
    required this.parentEntity,
    this.handleType = HandleType.colored,
  }) : super(
          zIndex: ZIndex.dragHandle.value,
        );

  @override
  bool contains(Offset position) {
    double hitAreaRadius =
        handleSize + (parentEntity == ParentEntity.window ? 5 : 20);
    return (position - Offset(x, y)).distance <= hitAreaRadius;
  }

  @override
  void draw(Canvas canvas, EntityState state) {
    final paint = Paint()
      ..color = state == EntityState.focused
          ? Colors.pink
          : handleType == HandleType.transparent
              ? Colors.transparent
              : Colors.green;

    canvas.drawCircle(Offset(x, y), handleSize, paint);
  }
}
