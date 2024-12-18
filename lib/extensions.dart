import 'package:flutter/material.dart';

extension OffsetExtensions on Offset {
  Offset normalize() {
    double magnitude = distance;
    if (magnitude == 0) return this;
    return this / magnitude;
  }

  double dot(Offset other) {
    return dx * other.dx + dy * other.dy;
  }

  Offset scale(double factor) {
    return Offset(dx * factor, dy * factor);
  }
}
