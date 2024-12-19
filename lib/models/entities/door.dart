import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:sketchbook/models/entities/entity.dart';
import 'package:sketchbook/models/enums/entity_instance.dart';
import 'package:sketchbook/models/enums/entity_state.dart';
import 'package:sketchbook/models/enums/z_index.dart';

class Door extends Entity {
  final double size = 40;
  final ui.Image doorAsset;
  final ui.Image doorActiveAsset;
  double rotation;
  Offset adjustedPadding;
  bool flipHorizontal;

  Door({
    required super.id,
    required super.x,
    required super.y,
    required this.doorAsset,
    required this.doorActiveAsset,
    this.rotation = 0,
    this.adjustedPadding = Offset.zero,
    this.flipHorizontal = false,
  }) : super(
          zIndex: ZIndex.door.value,
        );

  factory Door.fromJson(
    Map<String, dynamic> json,
    ui.Image assetImage,
    ui.Image assetActiveImage,
  ) {
    return Door(
      id: json['id'],
      x: json['x'],
      y: json['y'],
      doorAsset: assetImage,
      doorActiveAsset: assetActiveImage,
      rotation: json['rotation'],
      adjustedPadding: json['adjustedPadding'],
      flipHorizontal: json['flipHorizontal'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'instanceType': EntityInstance.door.value,
      'x': x,
      'y': y,
      'zIndex': zIndex,
      'rotation': rotation,
      'flipHorizontal': flipHorizontal,
      'adjustedPadding': adjustedPadding,
    };
  }

  @override
  Door clone() {
    return Door(
      id: id,
      x: x,
      y: y,
      doorAsset: doorAsset,
      doorActiveAsset: doorActiveAsset,
      rotation: rotation,
    );
  }

  @override
  bool contains(Offset position) {
    double hitAreaRadius = size;
    return (position - Offset(x, y)).distance <= hitAreaRadius;
  }

  @override
  void draw(Canvas canvas, EntityState state, double gridScaleFactor) {
    final paint = Paint();
    final asset = state == EntityState.focused ? doorActiveAsset : doorAsset;
    final imageWidth = asset.width.toDouble();
    final imageHeight = asset.height.toDouble();

    final scaleX = size / imageWidth;
    final scaleY = size / imageHeight;

    final matrix = Matrix4.identity()
      ..translate(x + adjustedPadding.dx, y + adjustedPadding.dy)
      ..rotateZ(rotation)
      ..scale(scaleX, scaleY)
      ..translate(-imageWidth / 2, -imageHeight / 2);

    if (flipHorizontal) {
      matrix
        ..translate(size / 1, 0)
        ..scale(-1.0, 1.0)
        ..translate(-size / 1.5, 0);
    }

    canvas.save();
    canvas.transform(matrix.storage);
    canvas.drawImage(
      asset,
      const Offset(0, 0),
      paint,
    );

    canvas.restore();
  }

  void flip() {
    flipHorizontal = !flipHorizontal;
  }

  void transform({
    double? x,
    double? y,
    double? angle,
    Offset? adjustmentPadding,
  }) {
    super.x = x ?? super.x;
    super.y = y ?? super.y;
    rotation = angle ?? rotation;
    adjustedPadding = adjustmentPadding ?? adjustedPadding;
  }
}
