import 'dart:math';

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
      Entity? selectedEntity, Entity wall, Grid grid,
      {double tolerance = 3.0}) {
    if (wall is! Wall || selectedEntity is Wall) return false;

    for (var otherWall in grid.entities.whereType<Wall>()) {
      if (wall.hashCode == otherWall.hashCode) continue; // skip self

      final vectorA = Offset(
        wall.handleB.x - wall.handleA.x,
        wall.handleB.y - wall.handleA.y,
      );
      final vectorB = Offset(
        otherWall.handleB.x - otherWall.handleA.x,
        otherWall.handleB.y - otherWall.handleA.y,
      );

      final dotProduct =
          (vectorA.dx * vectorB.dx + vectorA.dy * vectorB.dy).abs();
      if (dotProduct < tolerance) {
        return true; // perpendicular within tolerance
      }
    }
    return false;
  }

  static Offset? findExactPerpendicularOffset(
      Offset targetOffset, List<Offset> matchOffsets,
      {double tolerance = 3.0}) {
    Offset? resultOffset;
    double shortestDistance = double.infinity;

    for (var offset in matchOffsets) {
      // Skip points that are already directly aligned (horizontally or vertically)
      if (offset.dx == targetOffset.dx || offset.dy == targetOffset.dy) {
        continue;
      }

      // Check for collinearity (including diagonal lines) between targetOffset and offset
      for (var nextOffset in matchOffsets) {
        if (nextOffset == offset) continue;

        // Check for collinearity using the cross product approach
        double dx1 = offset.dx - targetOffset.dx;
        double dy1 = offset.dy - targetOffset.dy;
        double dx2 = nextOffset.dx - targetOffset.dx;
        double dy2 = nextOffset.dy - targetOffset.dy;

        double crossProduct = dx1 * dy2 - dy1 * dx2;

        // If the cross product is close to 0, the points are collinear (including diagonal)
        if (crossProduct.abs() <= tolerance) {
          // Now check if targetOffset lies between the two collinear points
          bool isBetweenX = (targetOffset.dx >= offset.dx &&
                  targetOffset.dx <= nextOffset.dx) ||
              (targetOffset.dx >= nextOffset.dx &&
                  targetOffset.dx <= offset.dx);

          bool isBetweenY = (targetOffset.dy >= offset.dy &&
                  targetOffset.dy <= nextOffset.dy) ||
              (targetOffset.dy >= nextOffset.dy &&
                  targetOffset.dy <= offset.dy);

          if (isBetweenX && isBetweenY) {
            // If targetOffset lies between offset and nextOffset, it's part of the line segment
            return targetOffset;
          }
        }
      }

      // Perpendicular projection logic (same as before)
      bool isWithinTolerance =
          (offset.dx - targetOffset.dx).abs() <= tolerance ||
              (offset.dy - targetOffset.dy).abs() <= tolerance;

      if (isWithinTolerance) {
        // exact perpendicular projection
        Offset projectedOffset;
        if ((offset.dx - targetOffset.dx).abs() <= tolerance) {
          // vertically
          projectedOffset = Offset(offset.dx, targetOffset.dy);
        } else {
          // horizontally
          projectedOffset = Offset(targetOffset.dx, offset.dy);
        }

        final distance = (targetOffset - projectedOffset).distance;

        if (distance < shortestDistance) {
          shortestDistance = distance;
          resultOffset = projectedOffset;
        }
      }
    }

    return resultOffset;
  }

  static Path? getWallsPath(Grid grid) {
    Path path = Path();

    bool firstWall = true;
    Set<int> visitedWalls = <int>{}; // To track which walls have been visited

    Wall? currentWall = grid.entities
        .whereType<Wall>()
        .firstOrNull; // Get the first wall to start from

    if (currentWall != null) {
      while (currentWall != null &&
          visitedWalls.length < grid.entities.whereType<Wall>().length + 1) {
        if (firstWall) {
          // Start the path at the first wall's handleA
          path.moveTo(currentWall.handleA.x, currentWall.handleA.y);
          visitedWalls
              .add(currentWall.hashCode); // Mark current wall as visited
          firstWall = false;
        } else {
          // Otherwise continue from the last handleB
          path.lineTo(currentWall.handleA.x, currentWall.handleA.y);
        }

        // Try to find the next wall by checking for a shared handle
        Wall? nextWall;
        if (currentWall.handleA.id == currentWall.handleB.id) {
          break; // If we encounter a self-loop, exit
        }

        // Try to find a wall that has handleB as handleA
        nextWall = grid.entities
            .whereType<Wall>()
            .where((entity) =>
                !visitedWalls.contains(entity.hashCode) &&
                (entity.handleA.id == currentWall?.handleB.id ||
                    entity.handleB.id == currentWall?.handleB.id))
            .firstOrNull;

        if (nextWall != null) {
          // Move to the next wall
          currentWall = nextWall;
          visitedWalls
              .add(currentWall.hashCode); // Mark the next wall as visited
        } else {
          break; // Exit if no next wall is found
        }
      }
    }

    path.close(); // Close the path to form the boundary
    return path;
  }

  static double inWallToWallAngle(InternalWall internalWall, Wall wall) {
    // Get the coordinates of the handles for both the internal wall and the wall
    double x1 = internalWall.handleA.x;
    double y1 = internalWall.handleA.y;
    double x2 = internalWall.handleB.x;
    double y2 = internalWall.handleB.y;
    double x3 = wall.handleA.x;
    double y3 = wall.handleA.y;
    double x4 = wall.handleB.x;
    double y4 = wall.handleB.y;

    // Compute the vectors for both wall segments
    double dx1 = x2 - x1;
    double dy1 = y2 - y1;
    double dx2 = x4 - x3;
    double dy2 = y4 - y3;

    // Compute the dot product and magnitudes of the vectors
    double dotProduct = dx1 * dx2 + dy1 * dy2;
    double magnitude1 = sqrt(dx1 * dx1 + dy1 * dy1);
    double magnitude2 = sqrt(dx2 * dx2 + dy2 * dy2);

    // Calculate the cosine of the angle between the two vectors
    double cosAngle = dotProduct / (magnitude1 * magnitude2);

    // Ensure that the cosine value is within the valid range for acos
    cosAngle = cosAngle.clamp(-1.0, 1.0);

    // Calculate the angle in radians and convert to degrees
    double angleInRadians = acos(cosAngle);
    double angleInDegrees = angleInRadians * 180 / pi;

    return angleInDegrees;
  }

  static double handleDistanceFromWall(DragHandle dragHandle, Wall wall) {
    // Get the two handles of the wall
    Offset wallHandleA = Offset(wall.handleA.x, wall.handleA.y);
    Offset wallHandleB = Offset(wall.handleB.x, wall.handleB.y);

    // Get the position of the dragHandle
    Offset dragPosition = Offset(dragHandle.x, dragHandle.y);

    // Function to calculate the distance from the dragHandle to the wall
    double calculateDistanceFromWall(
        Offset handle, Offset wallA, Offset wallB) {
      // Calculate the vector from wallA to wallB (direction of the wall)
      Offset wallVector = wallB - wallA;
      // Calculate the vector from wallA to the handle
      Offset handleVector = handle - wallA;

      // Project handleVector onto wallVector (perpendicular projection)
      double projection =
          (handleVector.dx * wallVector.dx + handleVector.dy * wallVector.dy) /
              (wallVector.dx * wallVector.dx + wallVector.dy * wallVector.dy);

      // Clamp the projection to ensure it falls within the line segment [wallA, wallB]
      projection = projection.clamp(0.0, 1.0);

      // Find the closest point on the wall
      Offset closestPoint = wallA + (wallVector * projection);

      // Return the distance from the handle to the closest point on the wall
      return (handle - closestPoint).distance;
    }

    // Calculate and return the distance from the dragHandle to the wall
    return calculateDistanceFromWall(dragPosition, wallHandleA, wallHandleB);
  }

  static double inWallDistanceFromWall(InternalWall internalWall, Wall wall) {
    // Get the coordinates of the handles for both the internal wall and the wall
    double x1 = internalWall.handleA.x;
    double y1 = internalWall.handleA.y;
    double x2 = internalWall.handleB.x;
    double y2 = internalWall.handleB.y;
    double x3 = wall.handleA.x;
    double y3 = wall.handleA.y;
    double x4 = wall.handleB.x;
    double y4 = wall.handleB.y;

    // Compute the vectors for the lines of both wall segments
    double dx1 = x2 - x1;
    double dy1 = y2 - y1;
    double dx2 = x4 - x3;
    double dy2 = y4 - y3;

    // Calculate the determinant to check if the lines are parallel
    double determinant = dx1 * dy2 - dy1 * dx2;

    if (determinant == 0) {
      // The lines are parallel, so we compute the perpendicular distance from one segment to the other
      return _distanceToLine(x1, y1, x3, y3, x4, y4);
    } else {
      // The lines are not parallel, compute the intersection point and the distance
      double t1 = ((x3 - x1) * dy2 - (y3 - y1) * dx2) / determinant;
      double t2 = ((x3 - x1) * dy1 - (y3 - y1) * dx1) / determinant;

      // If t1 and t2 are between 0 and 1, there is an intersection within the line segments
      if (t1 >= 0 && t1 <= 1 && t2 >= 0 && t2 <= 1) {
        // If the intersection is within the bounds, return 0 (there's no need for distance calculation)
        return 0;
      } else {
        // If there's no intersection within the bounds, return the minimum distance from the endpoints
        return _minDistanceToEndpoints(x1, y1, x2, y2, x3, y3, x4, y4);
      }
    }
  }

  static double windowDistanceFromWall(Window internalWall, Wall wall) {
    // Get the coordinates of the handles for both the internal wall and the wall
    double x1 = internalWall.handleA.x;
    double y1 = internalWall.handleA.y;
    double x2 = internalWall.handleB.x;
    double y2 = internalWall.handleB.y;
    double x3 = wall.handleA.x;
    double y3 = wall.handleA.y;
    double x4 = wall.handleB.x;
    double y4 = wall.handleB.y;

    // Compute the vectors for the lines of both wall segments
    double dx1 = x2 - x1;
    double dy1 = y2 - y1;
    double dx2 = x4 - x3;
    double dy2 = y4 - y3;

    // Calculate the determinant to check if the lines are parallel
    double determinant = dx1 * dy2 - dy1 * dx2;

    if (determinant == 0) {
      // The lines are parallel, so we compute the perpendicular distance from one segment to the other
      return _distanceToLine(x1, y1, x3, y3, x4, y4);
    } else {
      // The lines are not parallel, compute the intersection point and the distance
      double t1 = ((x3 - x1) * dy2 - (y3 - y1) * dx2) / determinant;
      double t2 = ((x3 - x1) * dy1 - (y3 - y1) * dx1) / determinant;

      // If t1 and t2 are between 0 and 1, there is an intersection within the line segments
      if (t1 >= 0 && t1 <= 1 && t2 >= 0 && t2 <= 1) {
        // If the intersection is within the bounds, return 0 (there's no need for distance calculation)
        return 0;
      } else {
        // If there's no intersection within the bounds, return the minimum distance from the endpoints
        return _minDistanceToEndpoints(x1, y1, x2, y2, x3, y3, x4, y4);
      }
    }
  }

// Function to calculate the perpendicular distance from a point to a line
  static double _distanceToLine(
      double x1, double y1, double x2, double y2, double x3, double y3) {
    // Distance from point (x1, y1) to the line segment (x2, y2) - (x3, y3)
    return ((y3 - y2) * x1 - (x3 - x2) * y1 + x3 * y2 - y3 * x2).abs() /
        sqrt(pow(y3 - y2, 2) + pow(x3 - x2, 2));
  }

// Function to calculate the minimum distance between two line segments (endpoints)
  static double _minDistanceToEndpoints(double x1, double y1, double x2,
      double y2, double x3, double y3, double x4, double y4) {
    // Distance from a point to a line
    double dist1 = _distanceToLine(x1, y1, x3, y3, x4, y4);
    double dist2 = _distanceToLine(x2, y2, x3, y3, x4, y4);
    double dist3 = _distanceToLine(x3, y3, x1, y1, x2, y2);
    double dist4 = _distanceToLine(x4, y4, x1, y1, x2, y2);

    // Return the minimum of these distances
    return [dist1, dist2, dist3, dist4].reduce((a, b) => a < b ? a : b);
  }

  static double calculateAvailableLengthWithinBounds(
      Offset startPoint, double angle, Grid grid) {
    Path? wallsPath = SketchHelpers.getWallsPath(grid);
    if (wallsPath == null) return 0;

    double maxLength = 0;
    for (double length = 0; length <= 1000; length += 1) {
      // Increment by small steps
      Offset testPoint = Offset(startPoint.dx + length * cos(angle),
          startPoint.dy + length * sin(angle));
      if (!isPointInsidePath(testPoint, wallsPath, grid)) {
        maxLength = length;
        break;
      }
      maxLength = length;
    }
    return maxLength;
  }

  static bool isPointInsidePath(Offset point, Path? wallsPath, Grid grid) {
    wallsPath ??= SketchHelpers.getWallsPath(grid);
    return wallsPath?.contains(point) ?? false;
  }

  static Offset getClosestPointOnWall(DragHandle dragHandle, Wall wall) {
    // Get the two handles of the wall
    Offset wallHandleA = Offset(wall.handleA.x, wall.handleA.y);
    Offset wallHandleB = Offset(wall.handleB.x, wall.handleB.y);

    // Calculate the vector from wallHandleA to wallHandleB
    Offset wallVector = wallHandleB - wallHandleA;

    // Calculate the vector from wallHandleA to the dragHandle
    Offset dragVector = Offset(dragHandle.x, dragHandle.y) - wallHandleA;

    // Project dragVector onto wallVector (perpendicular projection)
    double projection =
        (dragVector.dx * wallVector.dx + dragVector.dy * wallVector.dy) /
            (wallVector.dx * wallVector.dx + wallVector.dy * wallVector.dy);

    // Clamp the projection to ensure it falls within the line segment [wallHandleA, wallHandleB]
    projection = projection.clamp(0.0, 1.0);

    // Find the closest point on the wall
    Offset closestPoint = wallHandleA + (wallVector * projection);

    return closestPoint;
  }
}
