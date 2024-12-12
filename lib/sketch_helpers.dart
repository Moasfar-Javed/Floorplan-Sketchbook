import 'package:flutter/material.dart';
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
import 'package:sketchbook/models/enums/unit.dart';
import 'package:sketchbook/models/grid.dart';
import 'dart:ui' as ui;

class SketchHelpers {
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
    const squareSide = 200.0;

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

  static Offset closestPointOnLineSegment(
      Offset point, Offset lineStart, Offset lineEnd) {
    Offset line = lineEnd - lineStart;
    double lineLengthSquared = line.dx * line.dx + line.dy * line.dy;

    if (lineLengthSquared == 0.0) return lineStart;

    double t =
        ((point - lineStart).dx * line.dx + (point - lineStart).dy * line.dy) /
            lineLengthSquared;
    t = t.clamp(0.0, 1.0); // Clamp t to the segment [0, 1]

    return Offset(lineStart.dx + t * line.dx, lineStart.dy + t * line.dy);
  }

  static void fitDragHandles(
      BuildContext context,
      Grid grid,
      AnimationController animationController,
      TransformationController transformationController,
      {bool animate = true}) {
    final viewportSize = MediaQuery.of(context).size;

    // Extract all drag handles from grid entities
    final dragHandles = grid.entities
        .whereType<Wall>()
        .toList()
        .expand((entity) => [entity.handleA, entity.handleB]);

    // Define the bounding rectangle for all drag handles
    final dragHandlesBounds = Rect.fromLTRB(
      dragHandles
          .map((handle) => handle.x)
          .reduce((a, b) => a < b ? a : b), // Minimum x
      dragHandles
          .map((handle) => handle.y)
          .reduce((a, b) => a < b ? a : b), // Minimum y
      dragHandles
          .map((handle) => handle.x)
          .reduce((a, b) => a > b ? a : b), // Maximum x
      dragHandles
          .map((handle) => handle.y)
          .reduce((a, b) => a > b ? a : b), // Maximum y
    );

    // Calculate the center of the bounding rectangle
    final dragHandlesCenter = Offset(
      dragHandlesBounds.left + dragHandlesBounds.width / 2,
      dragHandlesBounds.top + dragHandlesBounds.height / 2,
    );

    // Calculate the required scale to fit the bounding rectangle within the viewport
    final scaleX = viewportSize.width / dragHandlesBounds.width;
    final scaleY = viewportSize.height / dragHandlesBounds.height;
    final scale = (scaleX < scaleY ? scaleX : scaleY) *
        0.6; // Add padding (90% of max scale)

    // Calculate the translation needed to center the bounding rectangle
    final viewportCenter =
        Offset(viewportSize.width / 2, viewportSize.height / 2);
    final translation = viewportCenter - dragHandlesCenter * scale;

    // Create the target transformation matrix
    final targetMatrix = Matrix4.identity()
      ..translate(translation.dx, translation.dy)
      ..scale(scale);

    if (animate) {
      final currentMatrix = transformationController.value;
      final matrixTween = Matrix4Tween(begin: currentMatrix, end: targetMatrix);

      animationController.reset();
      animationController.addListener(() {
        transformationController.value =
            matrixTween.evaluate(animationController);
      });
      animationController.forward();
    } else {
      transformationController.value = targetMatrix;
    }
  }

  static void centerCanvas(
      Size canvasSize,
      BuildContext context,
      AnimationController animationController,
      TransformationController transformationController,
      {bool animate = true}) {
    final canvasCenter = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final viewportSize = MediaQuery.of(context).size;

    // Calculate the top-left of the viewport center
    final viewportCenter =
        Offset(viewportSize.width / 2, viewportSize.height / 2);

    // Calculate the translation needed to center the canvas
    final translation = viewportCenter - canvasCenter;

    // Create the target transformation matrix
    final targetMatrix = Matrix4.identity()
      ..translate(translation.dx, translation.dy)
      ..scale(1.0);

    if (animate) {
      final currentMatrix = transformationController.value;
      final matrixTween = Matrix4Tween(begin: currentMatrix, end: targetMatrix);

      animationController.reset();
      animationController.addListener(() {
        transformationController.value =
            matrixTween.evaluate(animationController);
      });
      animationController.forward();
    } else {
      transformationController.value = targetMatrix;
    }
  }

  /// Converts a distance in pixels to the specified unit and returns a formatted string.
  static String distancePxToUnit(double distanceInPx, Unit unit) {
    const inchesPerPixel = oneCellToInches / cellSizeUnitPx;
    final distanceInInches = distanceInPx * inchesPerPixel;

    String formatNumber(double value) {
      value = double.parse(
          value.toStringAsFixed(1)); // Round to 1 decimal place first.

      if (value % 1 == 0) {
        // Whole number, no decimal part.
        return value.toInt().toString();
      } else {
        // Retain one decimal place for non-whole numbers.
        return value.toString();
      }
    }

    switch (unit) {
      case Unit.inches:
        return "${formatNumber(distanceInInches)}\""; // Example: 62"
      case Unit.feetAndInches:
        final feet = distanceInInches ~/ 12; // Whole feet.
        final inches = distanceInInches % 12;
        return feet > 0
            ? "$feet' ${formatNumber(inches)}\"" // Example: 5' 2.5"
            : "${formatNumber(inches)}\""; // Example: 11.5"
      case Unit.metric:
        final distanceInMeters =
            distanceInInches * 0.0254; // Convert inches to meters.
        return "${formatNumber(distanceInMeters)} m"; // Example: 1.59 m
      default:
        throw ArgumentError("Unsupported unit: $unit");
    }
  }

  static bool isSelected(Entity? selectedEntity, Entity entity, Grid grid) {
    if (selectedEntity != null) {
      if (selectedEntity is DragHandle && entity is Wall) {
        if (entity.handleA.isEqual(selectedEntity) ||
            entity.handleB.isEqual(selectedEntity)) {
          return true;
        }
      } else if (selectedEntity is Wall && selectedEntity.isEqual(entity)) {
        return true;
      } else if (selectedEntity is DragHandle && entity is InternalWall) {
        if (entity.handleA.isEqual(selectedEntity) ||
            entity.handleB.isEqual(selectedEntity)) {
          return true;
        }
      } else if (selectedEntity is InternalWall &&
          selectedEntity.isEqual(entity)) {
        return true;
      } else if (selectedEntity is DragHandle && entity is Window) {
        if (entity.handleA.isEqual(selectedEntity) ||
            entity.handleB.isEqual(selectedEntity)) {
          return true;
        }
      } else if (selectedEntity is Equipment &&
          selectedEntity.isEqual(entity)) {
        return true;
      } else if (selectedEntity is Window && selectedEntity.isEqual(entity)) {
        return true;
      } else if (selectedEntity is Door && selectedEntity.isEqual(entity)) {
        return true;
      }
    }
    return false;
  }

  static bool isRelativePerpendicular(
      Entity? selectedEntity, Entity wall, Grid grid) {
    if (wall is! Wall || selectedEntity is Wall) return false;
    for (var otherWall in grid.entities.whereType<Wall>()) {
      if (wall.hashCode == otherWall.hashCode) continue; // Skip self

      // Compute vectors
      final vectorA = Offset(
        wall.handleB.x - wall.handleA.x,
        wall.handleB.y - wall.handleA.y,
      );
      final vectorB = Offset(
        otherWall.handleB.x - otherWall.handleA.x,
        otherWall.handleB.y - otherWall.handleA.y,
      );

      // Check for perpendicularity
      if ((vectorA.dx * vectorB.dx + vectorA.dy * vectorB.dy).abs() < 1e-5) {
        return true;
      }
    }
    return false;
  }
}
