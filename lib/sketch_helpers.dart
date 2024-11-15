import 'package:flutter/material.dart';
import 'package:sketchbook/models/entities/drag_handle.dart';
import 'package:sketchbook/models/entities/internal_wall.dart';
import 'package:sketchbook/models/entities/wall.dart';
import 'package:sketchbook/models/grid.dart';

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

  static DragHandle? getDragHandleAtPosition(Offset position, Grid grid) {
    final adjustedPosition = position;
    for (var entity in grid.entities) {
      if (entity is Wall) {
        if (entity.handleA.contains(adjustedPosition)) {
          return entity.handleA;
        } else if (entity.handleB.contains(adjustedPosition)) {
          return entity.handleB;
        }
      }
    }
    return null;
  }

  // Method to get a Wall entity at position
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
}
