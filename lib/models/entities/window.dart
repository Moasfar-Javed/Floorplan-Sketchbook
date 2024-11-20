import 'package:flutter/material.dart';
import 'package:sketchbook/extensions.dart';
import 'package:sketchbook/models/entities/drag_handle.dart';
import 'package:sketchbook/models/entities/entity.dart';
import 'package:sketchbook/models/entities/wall.dart';
import 'package:sketchbook/models/enums/direction_state.dart';
import 'package:sketchbook/models/enums/entity_state.dart';
import 'package:sketchbook/models/enums/z_index.dart';
import 'package:sketchbook/sketch_helpers.dart';

class Window extends Entity {
  final double thickness;
  DragHandle handleA;
  DragHandle handleB;
  DirectionState directionState = DirectionState.vertical;

  Window({
    required super.id,
    required this.thickness,
    required this.handleA,
    required this.handleB,
  }) : super(
          x: handleA.x,
          y: (handleA.y + handleB.y) / 2,
          zIndex: ZIndex.window.value,
        );

  @override
  bool contains(Offset position) {
    return SketchHelpers.distanceToLineSegment(position,
            Offset(handleA.x, handleA.y), Offset(handleB.x, handleB.y)) <
        thickness / 2 + 20;
  }

  double get length => (handleB.x - handleA.x).abs();

  @override
  void draw(Canvas canvas, EntityState state) {
    var paint = Paint()..color = Colors.white;
    var bgPaint = Paint()..color = Colors.black;
    var middlePaint = Paint()..color = Colors.black;
    middlePaint.strokeWidth = 2;

    bgPaint.strokeWidth = thickness + 3;
    paint.strokeWidth = thickness;

    if (state == EntityState.focused) {
      paint.color = const Color(0xFFD3E0FB);
      bgPaint.color = const Color(0xFF2463EB);
      middlePaint.color = const Color(0xFF2463EB);
    }

    // Calculate direction vector from handleA to handleB
    Offset direction = Offset(handleB.x - handleA.x, handleB.y - handleA.y);

    // Normalize the direction to get a unit vector
    double length = direction.distance;
    Offset unitDirection = direction / length;

    // Extend the background line by 2px in both directions
    Offset extendedHandleA = Offset(
      handleA.x - unitDirection.dx * 2,
      handleA.y - unitDirection.dy * 2,
    );
    Offset extendedHandleB = Offset(
      handleB.x + unitDirection.dx * 2,
      handleB.y + unitDirection.dy * 2,
    );

    // Draw the extended background line (thicker)
    canvas.drawLine(
      extendedHandleA,
      extendedHandleB,
      bgPaint,
    );

    // Draw the regular line (normal thickness)
    canvas.drawLine(
      Offset(handleA.x, handleA.y),
      Offset(handleB.x, handleB.y),
      paint,
    );

    // Draw the middle line
    canvas.drawLine(
      handleA.position(),
      handleB.position(),
      middlePaint,
    );

    // Draw the handles
    handleA.draw(canvas, state);
    handleB.draw(canvas, state);
  }

  @override
  void move(double deltaX, double deltaY) {
    handleA.move(deltaX, deltaY);
    handleB.move(deltaX, deltaY);
  }

  void snapToClosestWall(List<Wall> walls) {
    double originalLength = length;
    if (walls.isEmpty) return;

    // Calculate the midpoint and direction vector of the window
    Offset windowMidpoint = Offset(
      (handleA.x + handleB.x) / 2,
      (handleA.y + handleB.y) / 2,
    );
    Offset windowDirection = Offset(
      handleB.x - handleA.x,
      handleB.y - handleA.y,
    ).normalize();

    // Check if the window is already on a wall
    for (Wall wall in walls) {
      Offset wallDirection = Offset(
        wall.handleB.x - wall.handleA.x,
        wall.handleB.y - wall.handleA.y,
      ).normalize();

      double distanceToWall = SketchHelpers.distanceToLineSegment(
        windowMidpoint,
        Offset(wall.handleA.x, wall.handleA.y),
        Offset(wall.handleB.x, wall.handleB.y),
      );

      // If the midpoint is close enough and the directions match, do nothing
      if (distanceToWall < 0.001 &&
          (wallDirection - windowDirection).distance < 0.001) {
        return;
      }
    }

    // Find the closest wall
    Wall? closestWall;
    double minDistance = double.infinity;

    for (Wall wall in walls) {
      double distance = SketchHelpers.distanceToLineSegment(
        windowMidpoint,
        Offset(wall.handleA.x, wall.handleA.y),
        Offset(wall.handleB.x, wall.handleB.y),
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestWall = wall;
      }
    }

    if (closestWall == null) return;

    // Calculate the wall's unit direction vector
    Offset wallDirection = Offset(
      closestWall.handleB.x - closestWall.handleA.x,
      closestWall.handleB.y - closestWall.handleA.y,
    );
    double wallLength = wallDirection.distance;
    Offset unitWallDirection = wallDirection / wallLength;

    // Project the window midpoint onto the closest wall line
    Offset wallStart = Offset(closestWall.handleA.x, closestWall.handleA.y);
    double projectionLength =
        ((windowMidpoint - wallStart).dx * unitWallDirection.dx +
            (windowMidpoint - wallStart).dy * unitWallDirection.dy);

    Offset projectedPoint = wallStart + unitWallDirection * projectionLength;
    double halfLength = originalLength / 2;

    // Adjust handles based on the projected midpoint and wall direction
    handleA.x = projectedPoint.dx - unitWallDirection.dx * halfLength;
    handleA.y = projectedPoint.dy - unitWallDirection.dy * halfLength;

    handleB.x = projectedPoint.dx + unitWallDirection.dx * halfLength;
    handleB.y = projectedPoint.dy + unitWallDirection.dy * halfLength;

    // Verify and correct the length if necessary
    double adjustedLength =
        Offset(handleA.x - handleB.x, handleA.y - handleB.y).distance;

    if ((adjustedLength - originalLength).abs() > 0.001) {
      double lengthCorrectionFactor = originalLength / adjustedLength;
      handleA.x = projectedPoint.dx -
          unitWallDirection.dx * halfLength * lengthCorrectionFactor;
      handleA.y = projectedPoint.dy -
          unitWallDirection.dy * halfLength * lengthCorrectionFactor;

      handleB.x = projectedPoint.dx +
          unitWallDirection.dx * halfLength * lengthCorrectionFactor;
      handleB.y = projectedPoint.dy +
          unitWallDirection.dy * halfLength * lengthCorrectionFactor;
    }

    // // Update window position to reflect the new center
    x = (handleA.x + handleB.x) / 2;
    y = (handleA.y + handleB.y) / 2;
  }
}
