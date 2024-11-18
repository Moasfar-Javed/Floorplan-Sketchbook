import 'package:flutter/services.dart';
import 'package:sketchbook/main.dart';
import 'package:sketchbook/models/entities/door.dart';
import 'package:sketchbook/models/entities/drag_handle.dart';
import 'package:sketchbook/models/entities/entity.dart';
import 'package:sketchbook/models/entities/equipment.dart';
import 'package:sketchbook/models/entities/internal_wall.dart';
import 'package:sketchbook/models/entities/moisture_point.dart';
import 'package:sketchbook/models/entities/wall.dart';
import 'package:sketchbook/models/entities/window.dart';
import 'package:sketchbook/models/enums/parent_entity.dart';
import 'package:sketchbook/models/grid.dart';
import 'dart:ui' as ui;

class SketchHelpers {
  // Helper method to calculate the distance from a point to a line segment
  static double distanceToLineSegment(
      Offset point, Offset lineStart, Offset lineEnd) {
    // Handle the case where the line start and end are the same point (no distance)
    if (lineStart == lineEnd) {
      return (point - lineStart).distance;
    }

    // Project the point onto the line defined by lineStart and lineEnd
    double lineLength = (lineEnd - lineStart).distance;
    double t = ((point.dx - lineStart.dx) * (lineEnd.dx - lineStart.dx) +
            (point.dy - lineStart.dy) * (lineEnd.dy - lineStart.dy)) /
        (lineLength * lineLength);

    // Clamp t to stay within the bounds of the line segment
    t = t.clamp(0.0, 1.0);

    // Calculate the point on the line closest to the given point
    Offset closestPoint = Offset(
      lineStart.dx + t * (lineEnd.dx - lineStart.dx),
      lineStart.dy + t * (lineEnd.dy - lineStart.dy),
    );

    // Return the distance from the point to the closest point on the line segment
    return (point - closestPoint).distance;
  }

  static Entity? getEntityAtPosition(Offset position, Grid grid) {
    return SketchHelpers.getDragHandleAtPosition(position, grid) ??
        SketchHelpers.getWindowAtPosition(position, grid) ??
        SketchHelpers.getInternalWallAtPosition(position, grid) ??
        SketchHelpers.getDoorAtPosition(position, grid) ??
        SketchHelpers.getEquipmentAtPosition(position, grid) ??
        SketchHelpers.getMoisturePointAtPosition(position, grid) ??
        SketchHelpers.getWallAtPosition(position, grid);
  }

  static DragHandle? getDragHandleAtPosition(Offset position, Grid grid) {
    final adjustedPosition = position;
    for (var entity in grid.entities) {
      if (entity is Wall) {
        if (entity.handleA.contains(adjustedPosition)) {
          return entity.handleA;
        } else if (entity.handleB.contains(adjustedPosition)) {
          return entity.handleB;
        }
      } else if (entity is InternalWall) {
        if (entity.handleA.contains(adjustedPosition)) {
          return entity.handleA;
        } else if (entity.handleB.contains(adjustedPosition)) {
          return entity.handleB;
        }
      } else if (entity is Window) {
        if (entity.handleA.contains(adjustedPosition)) {
          return entity.handleA;
        } else if (entity.handleB.contains(adjustedPosition)) {
          return entity.handleB;
        }
      }
    }
    return null;
  }

  static Wall? getWallAtPosition(Offset position, Grid grid) {
    for (var entity in grid.entities) {
      if (entity is Wall && entity.contains(position)) {
        return entity;
      }
    }
    return null;
  }

  static InternalWall? getInternalWallAtPosition(Offset position, Grid grid) {
    for (var entity in grid.entities) {
      if (entity is InternalWall && entity.contains(position)) {
        return entity;
      }
    }
    return null;
  }

  static Window? getWindowAtPosition(Offset position, Grid grid) {
    for (var entity in grid.entities) {
      if (entity is Window && entity.contains(position)) {
        return entity;
      }
    }
    return null;
  }

  static Door? getDoorAtPosition(Offset position, Grid grid) {
    for (var entity in grid.entities) {
      if (entity is Door && entity.contains(position)) {
        return entity;
      }
    }
    return null;
  }

  static MoisturePoint? getMoisturePointAtPosition(Offset position, Grid grid) {
    for (var entity in grid.entities) {
      if (entity is MoisturePoint && entity.contains(position)) {
        return entity;
      }
    }
    return null;
  }

  static Equipment? getEquipmentAtPosition(Offset position, Grid grid) {
    for (var entity in grid.entities) {
      if (entity is Equipment && entity.contains(position)) {
        return entity;
      }
    }
    return null;
  }

  static Future<ui.Image> loadImage(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(byteData.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  static void generateInitialSquare(Grid grid, Size canvasSize) {
    final centerX = canvasSize.width / 2;
    final centerY = canvasSize.height / 2;
    const squareSide = 300.0;

    final topLeft = Offset(centerX - squareSide / 2, centerY - squareSide / 2);
    final topRight = Offset(centerX + squareSide / 2, centerY - squareSide / 2);
    final bottomRight =
        Offset(centerX + squareSide / 2, centerY + squareSide / 2);
    final bottomLeft =
        Offset(centerX - squareSide / 2, centerY + squareSide / 2);

    final topLeftHandle = DragHandle(
      id: generateGuid(),
      x: topLeft.dx,
      y: topLeft.dy,
      parentEntity: ParentEntity.wall,
    );
    final topRightHandle = DragHandle(
      id: generateGuid(),
      x: topRight.dx,
      y: topRight.dy,
      parentEntity: ParentEntity.wall,
    );
    final bottomRightHandle = DragHandle(
      id: generateGuid(),
      x: bottomRight.dx,
      y: bottomRight.dy,
      parentEntity: ParentEntity.wall,
    );
    final bottomLeftHandle = DragHandle(
      id: generateGuid(),
      x: bottomLeft.dx,
      y: bottomLeft.dy,
      parentEntity: ParentEntity.wall,
    );

    final wall1 = Wall(
      id: generateGuid(),
      thickness: 10,
      handleA: topLeftHandle,
      handleB: topRightHandle,
    );

    final wall2 = Wall(
      id: generateGuid(),
      thickness: 10,
      handleA: topRightHandle,
      handleB: bottomRightHandle,
    );

    final wall3 = Wall(
      id: generateGuid(),
      thickness: 10,
      handleA: bottomRightHandle,
      handleB: bottomLeftHandle,
    );

    final wall4 = Wall(
      id: generateGuid(),
      thickness: 10,
      handleA: bottomLeftHandle,
      handleB: topLeftHandle,
    );

    // Add walls to the grid
    grid.addAllEntity([
      wall1,
      wall2,
      wall3,
      wall4,
    ]);
    grid.snapEntityToGrid(wall1);
    grid.snapEntityToGrid(wall2);
    grid.snapEntityToGrid(wall3);
    grid.snapEntityToGrid(wall4);
  }
}
