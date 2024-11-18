import 'package:flutter/material.dart';
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
  final Offset cameraOffset;

  BasePainter({
    required this.grid,
    required this.selectedEntity,
    required this.cameraOffset,
  });

  @override
  void paint(Canvas canvas, Size size) async {
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

    final sortedEntities = grid.entities
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    for (var entity in sortedEntities) {
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
      }
    }
    return false;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
