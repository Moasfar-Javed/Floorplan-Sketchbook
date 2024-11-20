import 'package:flutter/material.dart';

extension OffsetExtensions on Offset {
  Offset normalize() {
    double magnitude = distance;
    if (magnitude == 0) return this; // Avoid division by zero
    return this / magnitude;
  }
}
