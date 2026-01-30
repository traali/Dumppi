/// Heatmap layer for snowfall visualization.
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

import '../../logic/forecast_provider.dart';
import '../../data/alpine_grid.dart';
import 'heatmap_colors.dart';

/// Custom layer that renders snowfall as colored circles.
/// Circles scale with the map (larger when zooming in).
class HeatmapLayer extends StatelessWidget {
  const HeatmapLayer({
    required this.dayIndex,
    required this.zoom,
    super.key,
  });

  final int dayIndex;
  final double zoom;

  @override
  Widget build(BuildContext context) {
    return Consumer<ForecastProvider>(
      builder: (context, provider, _) {
        if (provider.forecasts.isEmpty) return const SizedBox.shrink();
        if (!provider.showHeatmap) return const SizedBox.shrink();

        // 1. Determine Grid Resolution and Scaling based on Zoom (from Spec)
        final resolution = GridResolution.fromZoom(zoom);
        final double overlapRatio = zoom >= 11 ? 0.60 : 0.75;
        
        // Final radius in meters as per spec: Radius = Grid Step * Overlap
        final double finalRadius = resolution.stepMeters * overlapRatio;

        // 2. Default Opacity from Spec
        // Zoom < 8: 0.6, Zoom >= 8: 0.4
        final double specOpacity = zoom < 8 ? 0.6 : 0.4;
        
        // Combine with user's manual opacity slider
        final double combinedOpacity = specOpacity * provider.heatmapOpacity;

        return CircleLayer(
          circles: provider.forecasts.map((forecast) {
            double snowfall = 0.0;
            
            if (dayIndex == -1) {
              // Cumulative forecast sum (indices 2 to 8)
              if (forecast.dailySnowfall.length > 2) {
                snowfall = forecast.dailySnowfall.sublist(2).reduce((a, b) => a + b);
              }
            } else if (dayIndex >= 0 && dayIndex < forecast.dailySnowfall.length) {
              snowfall = forecast.dailySnowfall[dayIndex];
            }

            // Spec 3.3: 0 cm Transparent
            if (snowfall <= 0.0) {
              return CircleMarker(
                point: forecast.point,
                radius: 0,
                color: Colors.transparent,
              );
            }

            final int finalAlpha = (combinedOpacity * 255).round().clamp(0, 255);

            return CircleMarker(
              point: forecast.point,
              radius: finalRadius,
              useRadiusInMeter: true,
              color: HeatmapColors.colorForSnowfall(snowfall)
                  .withAlpha(finalAlpha),
              borderColor: Colors.transparent,
              borderStrokeWidth: 0,
            );
          }).toList(),
        );
      },
    );
  }
}
