/// Legend widget for snowfall color scale.
library;

import 'package:flutter/material.dart';

import 'heatmap_colors.dart';

/// Floating legend showing the color scale.
class LegendWidget extends StatelessWidget {
  const LegendWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E).withAlpha(220),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Snowfall Accumulation',
            style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                '0cm',
                style: TextStyle(fontSize: 10, color: Colors.white38),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      colors: HeatmapColors.colorStops.map((s) => s.color).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '100+',
                style: TextStyle(fontSize: 10, color: Colors.white38),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Safety Indicators',
            style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _legendItem(Colors.greenAccent, 'Safe/Clear'),
              _legendItem(Colors.orangeAccent, 'Caution'),
              _legendItem(Colors.redAccent, 'Danger'),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Applies to Wind & Visibility',
            style: TextStyle(fontSize: 8, color: Colors.white24, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.white38)),
      ],
    );
  }
}
