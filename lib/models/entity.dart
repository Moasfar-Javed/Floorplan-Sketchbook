import 'dart:ui';

enum EntityState {
  normal,
  focused,
}

abstract class Entity {
  String id;
  double x;
  double y;

  Entity({
    required this.id,
    required this.x,
    required this.y,
  });

  void move(double deltaX, double deltaY) {
    x += deltaX;
    y += deltaY;
  }

  void draw(Canvas canvas, EntityState state);

  bool contains(Offset position);

  bool isEqual(Entity other) {
    return id == other.id && runtimeType == other.runtimeType;
  }
}