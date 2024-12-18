import 'dart:ui';

import 'package:sketchbook/models/enums/entity_state.dart';
import 'package:undo_redo/undo_redo.dart';

abstract class Entity with CloneableMixin<Entity> {
  String id;
  double x;
  double y;
  int zIndex;

  Entity({
    required this.id,
    required this.x,
    required this.y,
    required this.zIndex,
  });

  //returns a deep copy for undo/redo
  @override
  Entity clone();

  void move(double deltaX, double deltaY) {
    x += deltaX;
    y += deltaY;
  }

  void snap(double offsetX, double offsetY) {
    x = offsetX;
    y = offsetY;
  }

  Offset position() {
    return Offset(x, y);
  }

  void draw(Canvas canvas, EntityState state, double gridScaleFactor);

  bool contains(Offset position);

  bool isEqual(Entity other) {
    return id == other.id && runtimeType == other.runtimeType;
  }

  Map<String, dynamic> toJson();

  // Implemented on each entitiy basis due to diff params
  // Entity fromJson();
}
