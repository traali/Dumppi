/// Color definitions for the snowfall heatmap.
///
/// Matches the reference image: cyan → blue → purple → orange → red.
library;

import 'package:flutter/material.dart';

/// Color scale for snowfall visualization.
class HeatmapColors {
  HeatmapColors._();

  /// Color stops matching the reference image.
  static const List<ColorStop> colorStops = [
    ColorStop(0, Color(0xFF00F0FF)),   // 0cm - Neon Cyan
    ColorStop(2, Color(0xFF00D1FF)),   // 2cm
    ColorStop(5, Color(0xFF007AEE)),   // 5cm - Blue
    ColorStop(10, Color(0xFF5D5FEF)),  // 10cm - Indigo
    ColorStop(20, Color(0xFF7B61FF)),  // 20cm - Purple
    ColorStop(40, Color(0xFFB524E4)),  // 40cm - Neon Purple
    ColorStop(70, Color(0xFFE94EE4)),  // 70cm - Deep Neon Pink
    ColorStop(100, Color(0xFFF000FF)), // 100+cm - Magenta
  ];

  /// Get interpolated color for a snowfall value.
  static Color colorForSnowfall(double snowfallCm) {
    if (snowfallCm <= 0) return Colors.transparent;

    // Find the two stops to interpolate between
    ColorStop lower = colorStops.first;
    ColorStop upper = colorStops.last;

    for (var i = 0; i < colorStops.length - 1; i++) {
      if (snowfallCm >= colorStops[i].cm && snowfallCm < colorStops[i + 1].cm) {
        lower = colorStops[i];
        upper = colorStops[i + 1];
        break;
      }
    }

    // If at or above maximum, return max color
    if (snowfallCm >= colorStops.last.cm) {
      return colorStops.last.color;
    }

    // Interpolate
    final t = (snowfallCm - lower.cm) / (upper.cm - lower.cm);
    return Color.lerp(lower.color, upper.color, t) ?? lower.color;
  }
}

/// A color stop definition.
class ColorStop {
  const ColorStop(this.cm, this.color);

  final double cm;
  final Color color;
}
