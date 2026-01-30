/// Day slider for selecting forecast or history day.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/forecast_provider.dart';

/// Slider to select a specific day. Adapts labels for history/forecast mode.
class DaySlider extends StatelessWidget {
  const DaySlider({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ForecastProvider>(
      builder: (context, provider, _) {
        final List<String> labels = provider.isShowingHistory 
          ? ['-2d', 'Yesterday'] 
          : ['Total', 'Today', '+1', '+2', '+3', '+4', '+5', '+6'];

        final int currentIndex = provider.isShowingHistory 
          ? provider.historyDay 
          : (provider.selectedDay + 1); // Shifting by 1 because -1 is the first index

        return Card(
          color: const Color(0xFF1E1E2E).withAlpha(220),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                // Toggle snowfall layer visibility
                IconButton(
                  icon: Icon(
                    provider.showHeatmap ? Icons.visibility : Icons.visibility_off,
                    color: provider.showHeatmap ? Colors.white : Colors.white38,
                    size: 20,
                  ),
                  onPressed: () => provider.toggleHeatmap(),
                  tooltip: provider.showHeatmap ? 'Hide Snowfall' : 'Show Snowfall',
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: labels.map((label) {
                          final index = labels.indexOf(label);
                          final isSelected = index == currentIndex;
                          return Text(
                            label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : Colors.white38,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 4),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.blueAccent,
                          inactiveTrackColor: Colors.white10,
                          thumbColor: Colors.white,
                          overlayColor: Colors.blue.withAlpha(50),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: currentIndex.toDouble(),
                          min: 0,
                          max: (labels.length - 1).toDouble(),
                          divisions: labels.length - 1,
                          onChanged: (value) {
                            if (provider.isShowingHistory) {
                              provider.setHistoryDay(value.toInt());
                            } else {
                              provider.setSelectedDay(value.toInt() - 1);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
