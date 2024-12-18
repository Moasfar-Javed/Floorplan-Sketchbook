import 'dart:math';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sketchbook/models/entities/entity.dart';
import 'package:sketchbook/models/enums/entity_instance.dart';
import 'package:sketchbook/models/enums/entity_state.dart';
import 'package:sketchbook/models/enums/z_index.dart';

class Equipment extends Entity {
  double size = 50;
  final ui.Image equipmentAsset;
  final ui.Image activeEquipmentAsset;
  String label;

  Equipment(
      {required super.id,
      required super.x,
      required super.y,
      required this.equipmentAsset,
      required this.activeEquipmentAsset,
      required this.label,
      this.size = 40})
      : super(
          zIndex: ZIndex.equipment.value,
        );

  factory Equipment.fromJson(
    Map<String, dynamic> json,
    ui.Image assetImage,
    ui.Image assetActiveImage,
  ) {
    return Equipment(
      id: json['id'],
      x: json['x'],
      y: json['y'],
      size: json['size'],
      label: json['label'],
      equipmentAsset: assetImage,
      activeEquipmentAsset: assetActiveImage,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'instanceType': EntityInstance.equipment.value,
      'x': x,
      'y': y,
      'zIndex': zIndex,
      'size': size,
      'label': label,
    };
  }

  @override
  Equipment clone() {
    return Equipment(
      id: id,
      x: x,
      y: y,
      equipmentAsset: equipmentAsset,
      activeEquipmentAsset: activeEquipmentAsset,
      label: label,
    );
  }

  @override
  bool contains(Offset position) {
    double hitAreaRadius = size + 10;
    return (position - Offset(x, y)).distance <= hitAreaRadius;
  }

  @override
  void draw(Canvas canvas, EntityState state, double gridScaleFactor) {
    final paint = Paint();
    final asset =
        state == EntityState.focused ? activeEquipmentAsset : equipmentAsset;

    double baseSize = max(size, size / gridScaleFactor);

    final imageWidth = asset.width.toDouble();
    final imageHeight = asset.height.toDouble();

    // Scale the equipment size based on the new base size
    final scaleX = baseSize / imageWidth;
    final scaleY = baseSize / imageHeight;

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

    // Adjust label text style based on the scale factor
    final textStyle = TextStyle(
      color: Colors.black,
      fontSize: max(14, 14 / gridScaleFactor),
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

    // Adjust label position considering the new scaled size
    final labelOffset = Offset(x + baseSize / 2 + 5, y - paragraph.height / 2);
    canvas.drawParagraph(paragraph, labelOffset);
  }

  void updateValue(String? newLabel) {
    label = newLabel ?? label;
  }
}
