
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dumppi/src/features/map/logic/forecast_provider.dart';

class LayerSettingsDialog extends StatelessWidget {
  const LayerSettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E).withAlpha(230),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Layer Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Snowfall Opacity',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 10),
                Consumer<ForecastProvider>(
                  builder: (context, provider, _) {
                    return Row(
                      children: [
                        const Icon(Icons.opacity, color: Colors.white54, size: 20),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(0xFF0DB9F2),
                              inactiveTrackColor: Colors.white10,
                              thumbColor: Colors.white,
                              overlayColor: const Color(0xFF0DB9F2).withAlpha(50),
                            ),
                            child: Slider(
                              value: provider.heatmapOpacity,
                              min: 0.0,
                              max: 1.0,
                              onChanged: (value) => provider.setHeatmapOpacity(value),
                            ),
                          ),
                        ),
                        Text(
                          '${(provider.heatmapOpacity * 100).toInt()}%',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
