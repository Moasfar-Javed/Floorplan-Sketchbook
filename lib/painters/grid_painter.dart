import 'package:flutter/material.dart';
import 'package:sketchbook/models/entities/drag_handle.dart';
import 'package:sketchbook/models/entities/entity.dart';
import 'package:sketchbook/models/grid.dart';
import 'package:sketchbook/models/entities/wall.dart';

class GridPainter extends CustomPainter {
  final Entity? selectedEntity;
  final Grid grid;
  final Offset cameraOffset;

  GridPainter({
    required this.grid,
    required this.selectedEntity,
    required this.cameraOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(cameraOffset.dx, cameraOffset.dy);
    final Paint paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const double dashWidth = 4;
    const double dashSpace = 4;

    // Draw grid lines with snapping
    for (double x = 0; x <= size.width; x += grid.cellSize) {
      double startY = 0;
      while (startY < size.height) {
        canvas.drawLine(
          Offset(x, startY),
          Offset(x, startY + dashWidth),
          paint,
        );
        startY += dashWidth + dashSpace;
      }
    }

    for (double y = 0; y <= size.height; y += grid.cellSize) {
      double startX = 0;
      while (startX < size.width) {
        canvas.drawLine(
          Offset(startX, y),
          Offset(startX + dashWidth, y),
          paint,
        );
        startX += dashWidth + dashSpace;
      }
    }

    for (var entity in grid.entities) {
      entity.draw(
        canvas,
        _isSelected(entity) ? EntityState.focused : EntityState.normal,
      );
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
      }
    }
    return false;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
