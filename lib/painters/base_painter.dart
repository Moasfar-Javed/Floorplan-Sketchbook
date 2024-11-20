import 'package:flutter/material.dart';
import 'package:sketchbook/models/entities/door.dart';
import 'package:sketchbook/models/entities/drag_handle.dart';
import 'package:sketchbook/models/entities/entity.dart';
import 'package:sketchbook/models/entities/equipment.dart';
import 'package:sketchbook/models/entities/internal_wall.dart';
import 'package:sketchbook/models/entities/window.dart';
import 'package:sketchbook/models/enums/entity_state.dart';
import 'package:sketchbook/models/grid.dart';
import 'package:sketchbook/models/entities/wall.dart';

class BasePainter extends CustomPainter {
  final Entity? selectedEntity;
  final Grid grid;

  BasePainter({
    required this.grid,
    required this.selectedEntity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // canvas.translate(cameraOffset.dx, cameraOffset.dy);

    // Step 1: Draw the outside area with grey (background)
    final backgroundPaint = Paint()
      ..color = const Color(0xFFD3E0FB).withOpacity(0.5);
    canvas.drawRect(const Offset(0, 0) & size, backgroundPaint);

    // Step 2: Define the walls' bounds and draw the inside area with white
    Path? wallsPath = _getWallsPath();

    if (wallsPath != null) {
      final whitePaint = Paint()..color = Colors.white;

      // Step 3: Clip the region inside the walls' bounds and paint it white
      canvas.save();
      canvas.clipPath(wallsPath);
      canvas.drawRect(const Offset(0, 0) & size, whitePaint);
      canvas.restore();
    }

    // Step 4: Draw the grid on top of the white area (optional)
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
        _isSelected(entity) ? EntityState.focused : EntityState.normal,
      );
    }
  }

  Path? _getWallsPath() {
    Path path = Path();

    bool firstWall = true;

    // Loop through all walls and construct a path
    for (var entity in grid.entities) {
      if (entity is Wall) {
        if (firstWall) {
          path.moveTo(entity.handleA.x, entity.handleA.y);
          firstWall = false;
        }
        path.lineTo(entity.handleB.x, entity.handleB.y);
      }
    }

    path.close(); // Close the path to form the boundary
    return path;
  }

  // Step 4 Helper: Draw the grid lines
  void _drawGrid(Canvas canvas, Size size, Paint paint) {
    for (double x = 0; x <= size.width; x += grid.cellSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += grid.cellSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  bool _isSelected(Entity entity) {
    if (selectedEntity != null) {
      if (selectedEntity is DragHandle && entity is Wall) {
        if (entity.handleA.isEqual(selectedEntity!) ||
            entity.handleB.isEqual(selectedEntity!)) {
          return true;
        }
      } else if (selectedEntity is Wall && selectedEntity!.isEqual(entity)) {
        return true;
      } else if (selectedEntity is DragHandle && entity is InternalWall) {
        if (entity.handleA.isEqual(selectedEntity!) ||
            entity.handleB.isEqual(selectedEntity!)) {
          return true;
        }
      } else if (selectedEntity is InternalWall &&
          selectedEntity!.isEqual(entity)) {
        return true;
      } else if (selectedEntity is DragHandle && entity is Window) {
        if (entity.handleA.isEqual(selectedEntity!) ||
            entity.handleB.isEqual(selectedEntity!)) {
          return true;
        }
      } else if (selectedEntity is Equipment &&
          selectedEntity!.isEqual(entity)) {
        return true;
      } else if (selectedEntity is Window && selectedEntity!.isEqual(entity)) {
        return true;
      } else if (selectedEntity is Door && selectedEntity!.isEqual(entity)) {
        return true;
      }
    }
    return false;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
