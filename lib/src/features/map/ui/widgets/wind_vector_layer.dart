import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

import 'package:dumppi/src/features/map/logic/forecast_provider.dart';

/// Layer that renders directional wind vectors (arrows) on the map.
class WindVectorLayer extends StatelessWidget {
  const WindVectorLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ForecastProvider>(
      builder: (context, provider, _) {
        if (!provider.showWindVectors || provider.forecasts.isEmpty) {
          return const SizedBox.shrink();
        }

        final currentIndex = provider.currentMetricIndex;

        return MarkerLayer(
          markers: provider.forecasts.where((f) {
            final dayStart = currentIndex * 24;
            if (f.hourlyWindSpeed.length <= dayStart) return false;
            return f.hourlyWindSpeed[dayStart] > 0.5;
          }).map((f) {
            final windDir = f.dailyWindDirection[currentIndex];
            
            final dayStart = currentIndex * 24;
            final speeds = f.hourlyWindSpeed.sublist(dayStart, dayStart + 24);
            final avgSpeed = speeds.reduce((a, b) => a + b) / 24;

            return Marker(
              point: f.point,
              width: 40,
              height: 40,
              child: Transform.rotate(
                // Icons.north points UP (0 deg). 
                // Wind direction is FROM where it comes.
                // We want the arrow to point TO where it goes.
                // So if wind is 0 (from North), arrow should point 180 (South).
                angle: (windDir + 180) * (math.pi / 180),
                child: Opacity(
                  opacity: math.min(0.4 + (avgSpeed / 10), 0.9),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.north, // Using a simple arrow icon
                        size: math.min(14 + avgSpeed, 28),
                        color: _getWindColor(avgSpeed),
                        shadows: const [
                          Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
                        ],
                      ),
                      // Small tail to make it look like a vector
                      Container(
                        width: 2,
                        height: math.min(4 + avgSpeed / 2, 10),
                        color: _getWindColor(avgSpeed).withAlpha(150),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Color _getWindColor(double speed) {
    if (speed < 5) return Colors.green.shade700;
    if (speed < 10) return Colors.amber.shade800;
    if (speed < 15) return Colors.deepOrange;
    return Colors.red.shade900;
  }
}
