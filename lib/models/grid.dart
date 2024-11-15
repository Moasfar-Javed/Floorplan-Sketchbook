import 'package:sketchbook/models/entities/entity.dart';

class Grid {
  final double gridWidth;
  final double gridHeight;
  final double cellSize;
  final List<Entity> entities = [];

  Grid({
    required this.gridWidth,
    required this.gridHeight,
    required this.cellSize,
  });

  void addEntity(Entity entity) {
    entities.add(entity);
  }

  void removeEntity(Entity entity) {
    entities.remove(entity);
  }

  void snapEntityToGrid(Entity entity) {
    double snappedX = (entity.x / cellSize).round() * cellSize;
    double snappedY = (entity.y / cellSize).round() * cellSize;
    entity.move(snappedX - entity.x, snappedY - entity.y);
  }
}
