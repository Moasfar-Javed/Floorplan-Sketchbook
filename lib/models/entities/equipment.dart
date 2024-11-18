import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sketchbook/models/entities/entity.dart';
import 'package:sketchbook/models/enums/entity_state.dart';
import 'package:sketchbook/models/enums/z_index.dart';

class Equipment extends Entity {
  static const double size = 40;
  final ui.Image equipmentAsset;
  final ui.Image activeEquipmentAsset;
  String label;

  Equipment({
    required super.id,
    required super.x,
    required super.y,
    required this.equipmentAsset,
    required this.activeEquipmentAsset,
    required this.label,
  }) : super(
          zIndex: ZIndex.equipment.value,
        );

  @override
  bool contains(Offset position) {
    const double hitAreaRadius = size + 10;
    return (position - Offset(x, y)).distance <= hitAreaRadius;
  }

  @override
  void draw(Canvas canvas, EntityState state) {
    final paint = Paint();
    final asset =
        state == EntityState.focused ? activeEquipmentAsset : equipmentAsset;
    final imageWidth = asset.width.toDouble();
    final imageHeight = asset.height.toDouble();
    final scaleX = size / imageWidth;
    final scaleY = size / imageHeight;

    final matrix = Matrix4.identity()
      ..translate(x, y)
      ..scale(scaleX, scaleY)
      ..translate(-imageWidth / 2, -imageHeight / 2);

    canvas.save();
    canvas.transform(matrix.storage);
    canvas.drawImage(
      asset,
      const Offset(0, 0),
      paint,
    );

    canvas.restore();

    const textStyle = TextStyle(
      color: Colors.black,
      fontSize: 14,
    );
    final paragraphStyle = ParagraphStyle(
      textAlign: TextAlign.left,
      maxLines: 1,
    );

    final paragraphBuilder = ParagraphBuilder(paragraphStyle)
      ..pushStyle(textStyle.getTextStyle())
      ..addText(label);

    final paragraph = paragraphBuilder.build()
      ..layout(const ParagraphConstraints(width: 100));

    final labelOffset = Offset(x + size / 2 + 5, y - paragraph.height / 2);
    canvas.drawParagraph(paragraph, labelOffset);
  }

  void updateValue(String? newLabel) {
    label = newLabel ?? label;
  }
}
