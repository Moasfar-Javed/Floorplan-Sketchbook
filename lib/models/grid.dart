import 'dart:ui' as ui;

import 'package:sketchbook/models/entities/door.dart';
import 'package:sketchbook/models/entities/drag_handle.dart';
import 'package:sketchbook/models/entities/entity.dart';
import 'package:sketchbook/models/entities/equipment.dart';
import 'package:sketchbook/models/entities/internal_wall.dart';
import 'package:sketchbook/models/entities/moisture_point.dart';
import 'package:sketchbook/models/entities/wall.dart';
import 'package:sketchbook/models/entities/window.dart';
import 'package:sketchbook/models/enums/entity_instance.dart';

class Grid {
  final double width;
  final double height;
  final double cellSize;
  List<Entity> entities;

  Grid({
    required this.width,
    required this.height,
    required this.cellSize,
    List<Entity>? entities,
  }) : entities = entities ?? [];

  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'height': height,
      'cellSize': cellSize,
      'entities': entities.map((e) => e.toJson()).toList()
    };
  }

  factory Grid.fromJson(
    Map<String, dynamic> json,
    ui.Image doorAssetImage,
    ui.Image doorAssetActiveImage,
    ui.Image mpAssetImage,
    ui.Image mpAssetActiveImage,
    ui.Image equipmentAssetImage,
    ui.Image equipmentAssetActiveImage,
  ) {
    final grid = Grid(
      width: json['width'],
      height: json['height'],
      cellSize: json['cellSize'],
      entities: _generateEntities(
        json['entities'],
        doorAssetImage,
        doorAssetActiveImage,
        mpAssetImage,
        mpAssetActiveImage,
        equipmentAssetImage,
        equipmentAssetActiveImage,
      ),
    );

    return grid;
  }

  static List<Entity> _generateEntities(
    List<dynamic> json,
    ui.Image doorAssetImage,
    ui.Image doorAssetActiveImage,
    ui.Image mpAssetImage,
    ui.Image mpAssetActiveImage,
    ui.Image equipmentAssetImage,
    ui.Image equipmentAssetActiveImage,
  ) {
    List<Entity> entities = [];
    List<dynamic> wallsData = json
        .where((e) =>
            EntityInstance.fromValue(e['instanceType']) == EntityInstance.wall)
        .toList();
    List<DragHandle> wallHandles = wallsData.expand((wall) {
      // Extract handleA and handleB from each wall and return them as a list
      return [
        DragHandle.fromJson(wall['handleA']),
        DragHandle.fromJson(wall['handleB']),
      ];
    }).toList();
    Set<String> seenIds = {};
    List<DragHandle> uniqueWallHandles = wallHandles.where((handle) {
      if (seenIds.contains(handle.id)) {
        return false; // Skip duplicates
      } else {
        seenIds.add(handle.id);
        return true;
      }
    }).toList();

    for (final data in json) {
      switch (EntityInstance.fromValue(data['instanceType'])) {
        case EntityInstance.moisturePoint:
          entities.add(
            MoisturePoint.fromJson(
              data,
              mpAssetImage,
              mpAssetActiveImage,
            ),
          );
        case EntityInstance.equipment:
          entities.add(
            Equipment.fromJson(
              data,
              equipmentAssetImage,
              equipmentAssetActiveImage,
            ),
          );
        case EntityInstance.window:
          entities.add(
            Window.fromJson(data),
          );
        case EntityInstance.door:
          entities.add(
            Door.fromJson(
              data,
              doorAssetImage,
              doorAssetActiveImage,
            ),
          );
        case EntityInstance.dragHandle:
        // Skip these they get rendered with walls, internal walls and windows themselves
        case EntityInstance.wall:
          entities.add(
            Wall.fromJson(
              data,
              uniqueWallHandles
                  .firstWhere((e) => e.id == data['handleA']['id']),
              uniqueWallHandles
                  .firstWhere((e) => e.id == data['handleB']['id']),
            ),
          );
        case EntityInstance.internalWall:
          entities.add(
            InternalWall.fromJson(data),
          );
      }
    }

    return entities;
  }

  void addEntity(Entity newEntity) {
    entities.add(newEntity);
  }

  void addAllEntity(List<Entity> newEntities) {
    entities.addAll(newEntities);
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
