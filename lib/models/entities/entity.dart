import 'dart:ui';

import 'package:sketchbook/models/enums/entity_state.dart';

abstract class Entity {
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

  void move(double deltaX, double deltaY) {
    x += deltaX;
    y += deltaY;
  }

  Offset position() {
    return Offset(x, y);
  }

  void draw(Canvas canvas, EntityState state);

  bool contains(Offset position);

  bool isEqual(Entity other) {
    return id == other.id && runtimeType == other.runtimeType;
  }

  Map<String, dynamic> toJson();

  // Implemented on each entitiy basis due to diff params 
  // Entity fromJson();
}
