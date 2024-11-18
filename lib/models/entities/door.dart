import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:sketchbook/models/entities/entity.dart';
import 'package:sketchbook/models/enums/entity_state.dart';
import 'package:sketchbook/models/enums/z_index.dart';

class Door extends Entity {
  static const double size = 40;
  final ui.Image doorAsset;
  double rotation = 0;

  Door({
    required super.id,
    required super.x,
    required super.y,
    required this.doorAsset,
  }) : super(
          zIndex: ZIndex.door.value,
        );

  @override
  bool contains(Offset position) {
    const double hitAreaRadius = size + 10;
    return (position - Offset(x, y)).distance <= hitAreaRadius;
  }

  @override
  void draw(Canvas canvas, EntityState state) {
    final paint = Paint();
    final imageWidth = doorAsset.width.toDouble();
    final imageHeight = doorAsset.height.toDouble();
    final scaleX = size / imageWidth;
    final scaleY = size / imageHeight;

    final matrix = Matrix4.identity()
      ..translate(x, y)
      ..rotateZ(rotation)
      ..scale(scaleX, scaleY)
      ..translate(-imageWidth / 2, -imageHeight / 2);

    canvas.save();
    canvas.transform(matrix.storage);
    canvas.drawImage(
      doorAsset,
      const Offset(0, 0),
      paint,
    );

    canvas.restore();
  }

  void rotateClockwise() {
    rotation += pi / 2;
    if (rotation >= 2 * pi) {
      rotation -= 2 * pi;
    }
  }

  void rotateCounterclockwise() {
    rotation -= pi / 2; // 90 degrees in radians (pi / 2)
    if (rotation < 0) {
      rotation += 2 * pi;
    }
  }
}
