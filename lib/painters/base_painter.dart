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

    Path? wallsPath = SketchHelpers.getWallsPath(grid);

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
