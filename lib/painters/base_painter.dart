import 'package:flutter/material.dart';
import 'package:sketchbook/models/entities/entity.dart';
import 'package:sketchbook/models/enums/entity_state.dart';
import 'package:sketchbook/models/grid.dart';
import 'package:sketchbook/models/entities/wall.dart';
import 'package:sketchbook/sketch_helpers.dart';

class BasePainter extends CustomPainter {
  final Entity? selectedEntity;
  final Grid grid;

  BasePainter({
    required this.grid,
    required this.selectedEntity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = const Color(0xFFD3E0FB).withOpacity(0.5);
    canvas.drawRect(const Offset(0, 0) & size, backgroundPaint);

    Path? wallsPath = _getWallsPath();

    if (wallsPath != null) {
      final whitePaint = Paint()..color = Colors.white;

      canvas.save();
      canvas.clipPath(wallsPath);
      canvas.drawRect(const Offset(0, 0) & size, whitePaint);
      canvas.restore();
    }

    final gridPaint = Paint()
      ..color = const Color(0xFFD3E0FB)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    _drawGrid(canvas, size, gridPaint);

    final sortedEntities = grid.entities
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    for (var entity in sortedEntities) {
      entity.draw(
        canvas,
        SketchHelpers.isSelected(selectedEntity, entity, grid)
            ? SketchHelpers.isRelativePerpendicular(
                    selectedEntity, entity, grid)
                ? EntityState.relativePerpendicular
                : EntityState.focused
            : EntityState.normal,
      );
    }
  }

  Path? _getWallsPath() {
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

  void _drawGrid(Canvas canvas, Size size, Paint paint) {
    for (double x = 0; x <= size.width; x += grid.cellSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += grid.cellSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
