import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dumppi/src/features/resorts/logic/resort_provider.dart';
import 'package:dumppi/src/features/map/logic/forecast_provider.dart';
import 'package:dumppi/src/features/resorts/ui/widgets/slope_aspect_rose.dart';

/// Bottom sheet showing forecast details for the selected resort.
class ResortDetailSheet extends StatefulWidget {
  const ResortDetailSheet({super.key});

  @override
  State<ResortDetailSheet> createState() => _ResortDetailSheetState();
}

class _ResortDetailSheetState extends State<ResortDetailSheet> {
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  @override
  Widget build(BuildContext context) {
    return Consumer2<ResortProvider, ForecastProvider>(
      builder: (context, resortProvider, forecastProvider, _) {
        final resort = resortProvider.selectedResort;
        if (resort == null) return const SizedBox.shrink();

        return DraggableScrollableSheet(
          controller: _sheetController,
          initialChildSize: 0.5,
          minChildSize: 0.2,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D12),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border(top: BorderSide(color: Colors.white.withAlpha(26))),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              resort.id == 'custom_point' 
                                  ? 'Point Forecast'
                                  : resort.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                            ),
                            Text(
                              resort.id == 'custom_point'
                                  ? 'Coordinates: ${resort.lat.toStringAsFixed(3)}, ${resort.lng.toStringAsFixed(3)}'
                                  : '${resort.country.toUpperCase()} • ${resort.baseAlt}M - ${resort.topAlt}M',
                              style: const TextStyle(
                                color: Color(0xFF0DB9F2),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          if (resort.id != 'custom_point')
                            IconButton(
                              icon: Icon(
                                resort.isFavorite ? Icons.star : Icons.star_border,
                                color: resort.isFavorite ? Colors.amber : Colors.white70,
                              ),
                              onPressed: () => resortProvider.toggleFavorite(resort),
                            ),
                          if (resort.isCustom)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _confirmDelete(context, resortProvider, resort.id),
                            ),
                          IconButton(
                            icon: const Icon(Icons.fullscreen, color: Color(0xFF0DB9F2)),
                            onPressed: () {
                              _sheetController.animateTo(
                                0.95, 
                                duration: const Duration(milliseconds: 300), 
                                curve: Curves.easeOutCubic,
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white70),
                            onPressed: () => resortProvider.selectResort(null),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  if (resort.id == 'custom_point') ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showSaveStashDialog(context, resortProvider, resort.lat, resort.lng),
                      icon: const Icon(Icons.bookmark_add_outlined),
                      label: const Text('Save as Secret Stash'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF64B5F6).withAlpha(40),
                        foregroundColor: const Color(0xFF64B5F6),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Enhanced Stats (New Phase 6)
                  if (!resort.isCustom && resort.id != 'custom_point') ...[
                    _buildQuickStats(context, resort),
                    const SizedBox(height: 32),
                    if (resort.slopeAspectData != null) ...[
                      SlopeAspectRose(aspectData: resort.slopeAspectData!),
                      const SizedBox(height: 32),
                    ],
                  ],
                  
                  if (resortProvider.isForecastLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(60),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (resortProvider.selectedForecast != null) ...[
                    _buildElevationSelector(context, resortProvider),
                    const SizedBox(height: 32),
                    
                    Text(
                      '7-Day Powder Outlook (${resortProvider.currentElevation}m)',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDailyGrid(context, resortProvider),
                    
                    const SizedBox(height: 32),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Hourly Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _formatSelectedDate(resortProvider),
                          style: const TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildHourlyList(resortProvider),
                  ] else
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text(
                          'Unable to load forecast data',
                          style: TextStyle(color: Colors.white38),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickStats(BuildContext context, dynamic resort) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _statItem(Icons.height, 'Vertical', '${resort.verticalDrop}m'),
        _statItem(Icons.straighten, 'Runs', resort.downhillRunsKm != null ? '${resort.downhillRunsKm}km' : '--'),
        _statItem(Icons.architecture, 'Lifts', resort.lifts?.total.toString() ?? '--'),
      ],
    );
  }

  Widget _statItem(IconData icon, String label, String value) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(13)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF0DB9F2), size: 20),
          const SizedBox(height: 8),
          Text(
            value, 
            style: const TextStyle(
              color: Colors.white, 
              fontWeight: FontWeight.w900, 
              fontSize: 15,
            ),
          ),
          Text(
            label.toUpperCase(), 
            style: const TextStyle(
              color: Colors.white38, 
              fontSize: 8, 
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElevationSelector(BuildContext context, ResortProvider provider) {
    final levels = [
      {'id': 'base', 'label': 'BASE'},
      {'id': 'mid', 'label': 'MID'},
      {'id': 'top', 'label': 'TOP'},
      {'id': 'compare', 'label': 'COMPARE'},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(13)),
      ),
      child: Row(
        children: levels.map((level) {
          final isSelected = provider.selectedAltitude == level['id'];
          return Expanded(
            child: GestureDetector(
              onTap: () => provider.setAltitude(level['id']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0DB9F2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    level['label']!,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white38,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // (Helper methods like _confirmDelete, _showSaveStashDialog, _buildDailyGrid, _buildHourlyList, etc. remain the same but included for complete file rewrite)
  // ... (Abbreviated for prompt size but ensuring they are there in the actual write)

  Future<void> _showSaveStashDialog(BuildContext context, ResortProvider provider, double lat, double lng) async {
    final controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          title: const Text('New Secret Stash', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Name',
              labelStyle: TextStyle(color: Colors.white70),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  provider.saveCustomPoint(controller.text, lat, lng);
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, ResortProvider provider, String id) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          title: const Text('Delete Stash?', style: TextStyle(color: Colors.white)),
          content: const Text('This will permanently remove this secret point.', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                provider.deleteCustomStash(id);
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDailyGrid(BuildContext context, ResortProvider provider) {
    final mainForecast = provider.selectedForecast;
    if (mainForecast == null) return const SizedBox.shrink();
    
    final daily = mainForecast['daily'] as Map<String, dynamic>;
    final dates = daily['time'] as List<dynamic>;
    
    return SizedBox(
      height: provider.isCompareMode ? 280 : 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final isSelected = provider.selectedDayIndex == index;
          final date = DateTime.parse(dates[index] as String);
          final dayName = index == 0 ? 'Today' : _getDayName(date.weekday);

          if (provider.isCompareMode) {
            return _buildCompareCard(context, provider, index, dayName, isSelected);
          }

          final snowfall = daily['snowfall_sum'] as List<dynamic>;
          final tempMax = daily['temperature_2m_max'] as List<dynamic>;
          final tempMin = daily['temperature_2m_min'] as List<dynamic>;
          final wind = daily['windspeed_10m_max'] as List<dynamic>;
          final gusts = daily['windgusts_10m_max'] as List<dynamic>;
          final windDir = daily['winddirection_10m_dominant'] as List<dynamic>;
          final visibility = daily['visibility_mean'] as List<dynamic>;
          final visKm = (visibility[index] as num) / 1000;

          final highlight = _getQualityHighlight(snowfall[index] as num, wind[index] as num, visKm);

          return GestureDetector(
            onTap: () => provider.setDayIndex(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 150,
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFF0DB9F2).withAlpha(26) 
                    : Colors.white.withAlpha(8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected 
                      ? const Color(0xFF0DB9F2) 
                      : (highlight.color?.withAlpha(128) ?? Colors.white.withAlpha(13)),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Stack(
                children: [
                   Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          dayName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                        ),
                      ),
                      const Divider(color: Colors.white10, height: 16),
                      
                      _metricRow(Icons.ac_unit, '${snowfall[index]} cm Snow', Colors.blue.shade300),
                      _metricRow(Icons.thermostat, '${tempMin[index]}°C to ${tempMax[index]}°C', Colors.orangeAccent),
                      _metricRow(Icons.visibility, '${visKm.toStringAsFixed(0)}km Vis', _getVisibilityColor(visKm)),
                      
                      const SizedBox(height: 8),
                      const Text('Wind', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                      _metricRow(
                        Icons.air,
                        'Avg: ${wind[index]} m/s',
                        _getWindColor(wind[index] as num),
                      ),
                      _metricRow(
                        Icons.bolt,
                        'Gust: ${gusts[index]} m/s',
                        _getWindColor(gusts[index] as num),
                      ),
                      
                      const Spacer(),
                      Row(
                        children: [
                          Transform.rotate(
                            angle: (windDir[index] as num).toDouble() * (3.14159 / 180),
                            child: const Icon(Icons.navigation, size: 10, color: Colors.white38),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getCardinalDirection(windDir[index] as num),
                            style: const TextStyle(fontSize: 10, color: Colors.white38),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (highlight.icon != null)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Icon(highlight.icon, size: 14, color: highlight.color),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompareCard(BuildContext context, ResortProvider provider, int index, String dayName, bool isSelected) {
    final allForecasts = provider.multiAltitudeForecast!['forecasts'] as Map<String, dynamic>;
    
    return GestureDetector(
      onTap: () => provider.setDayIndex(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 180,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF0DB9F2).withAlpha(26) 
              : Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0DB9F2) : Colors.white.withAlpha(13),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(dayName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const Divider(color: Colors.white10, height: 16),
            
            _compareRow('TOP', allForecasts['top'], index, const Color(0xFF7B61FF)), // Purple accent for mountain peak
            const SizedBox(height: 8),
            _compareRow('MID', allForecasts['mid'], index, const Color(0xFF0DB9F2)), // Cyan for mid
            const SizedBox(height: 8),
            _compareRow('BASE', allForecasts['base'], index, Colors.white38), // White for base
          ],
        ),
      ),
    );
  }

  Widget _compareRow(String label, dynamic forecast, int dayIdx, Color color) {
    final daily = forecast['daily'] as Map<String, dynamic>;
    final snow = daily['snowfall_sum'][dayIdx] as num;
    final tempMax = daily['temperature_2m_max'][dayIdx] as num;
    final tempMin = daily['temperature_2m_min'][dayIdx] as num;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(26)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 32,
            child: Text(
              label, 
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.ac_unit, size: 10, color: Colors.white54),
              const SizedBox(width: 4),
              Text(
                '${snow.toStringAsFixed(1)} cm',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Text(
            '${tempMin.round()}…${tempMax.round()}°',
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyList(ResortProvider provider) {
    final forecast = provider.selectedForecast;
    if (forecast == null) return const SizedBox.shrink();
    final hourly = forecast['hourly'] as Map<String, dynamic>;
    final times = hourly['time'] as List<dynamic>;
    final temps = hourly['temperature_2m'] as List<dynamic>;
    final snowfall = hourly['snowfall'] as List<dynamic>;
    final winds = hourly['windspeed_10m'] as List<dynamic>;
    final gusts = hourly['windgusts_10m'] as List<dynamic>;
    final directions = hourly['winddirection_10m'] as List<dynamic>;
    final visibility = hourly['visibility'] as List<dynamic>;

    final startIdx = provider.selectedDayIndex * 24;

    return Column(
      children: List.generate(24, (i) {
        final idx = startIdx + i;
        if (idx >= times.length) return const SizedBox.shrink();

        final timeStr = times[idx] as String;
        final time = DateTime.parse(timeStr);
        final hour = time.hour.toString().padLeft(2, '0');
        final visKm = (visibility[idx] as num) / 1000;
        final highlight = _getQualityHighlight(snowfall[idx] as num, winds[idx] as num, visKm);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              if (highlight.color != null)
                Container(
                  width: 4,
                  height: 60, // approximate height, Row/IntrinsicHeight would be better but fixed is safer here
                  color: highlight.color,
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    children: [
              Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Row(
                      children: [
                        Text(
                          '$hour:00',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 13),
                        ),
                        if (highlight.icon != null) ...[
                          const SizedBox(width: 4),
                          Icon(highlight.icon, size: 10, color: highlight.color),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.thermostat, size: 12, color: Colors.orangeAccent),
                        const SizedBox(width: 4),
                        Text('${temps[idx]}°C', style: const TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.ac_unit, size: 12, color: Colors.blueAccent),
                        const SizedBox(width: 4),
                        Text('${snowfall[idx]} cm', style: const TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.visibility, size: 12, color: Colors.cyanAccent),
                        const SizedBox(width: 4),
                        Text('${visKm.toStringAsFixed(0)}km', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const SizedBox(width: 53),
                  const Text('Wind:', style: TextStyle(color: Colors.white30, fontSize: 11)),
                  const SizedBox(width: 8),
                  Text('${winds[idx]}', style: TextStyle(color: _getWindColor(winds[idx] as num), fontSize: 12, fontWeight: FontWeight.bold)),
                  const Text(' m/s', style: TextStyle(color: Colors.white38, fontSize: 10)),
                  const SizedBox(width: 12),
                  const Text('Gust:', style: TextStyle(color: Colors.white30, fontSize: 11)),
                  const SizedBox(width: 8),
                  Text('${gusts[idx]}', style: TextStyle(color: _getWindColor(gusts[idx] as num), fontSize: 12, fontWeight: FontWeight.bold)),
                  const Text(' m/s', style: TextStyle(color: Colors.white38, fontSize: 10)),
                  const Spacer(),
                  Transform.rotate(
                    angle: (directions[idx] as num).toDouble() * (3.14159 / 180),
                    child: const Icon(Icons.navigation, size: 12, color: Colors.white38),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getCardinalDirection(directions[idx] as num),
                    style: const TextStyle(fontSize: 11, color: Colors.white38),
                  ),
                ],
              ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _metricRow(IconData icon, String value, Color color, {double? rotation}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (rotation != null)
            Transform.rotate(
              angle: rotation * (3.14159 / 180),
              child: Icon(icon, size: 12, color: color),
            )
          else
            Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getWindColor(num speed) {
    if (speed < 5) return Colors.greenAccent;
    if (speed < 10) return Colors.amberAccent;
    if (speed < 15) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Color _getVisibilityColor(num km) {
    if (km > 10) return Colors.blue.shade200; // Good
    if (km > 5) return Colors.amberAccent; // Fair
    if (km > 1.5) return Colors.orangeAccent; // Poor
    return Colors.redAccent; // Dangerous
  }

  String _getCardinalDirection(num degrees) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((degrees + 22.5) % 360) / 45;
    return directions[index.toInt() % 8];
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }

  String _formatSelectedDate(ResortProvider provider) {
    final forecast = provider.selectedForecast;
    if (forecast == null) return '';
    final daily = forecast['daily'] as Map<String, dynamic>;
    final dates = daily['time'] as List<dynamic>;
    if (provider.selectedDayIndex >= dates.length) return '';
    
    final date = DateTime.parse(dates[provider.selectedDayIndex] as String);
    return '${date.day}.${date.month}.';
  }

  _DayQualityHighlight _getQualityHighlight(num snow, num wind, num vis) {
    if (snow > 10 && wind < 5 && vis > 10) {
      return const _DayQualityHighlight(Colors.amber, Icons.wb_sunny); // Bluebird
    }
    if (snow > 5) {
      return const _DayQualityHighlight(Colors.blueAccent, Icons.ac_unit); // Powder
    }
    if (wind > 15 || vis < 1.0) {
      return const _DayQualityHighlight(Colors.redAccent, Icons.warning_amber); // Danger
    }
    if (wind > 10 || vis < 5.0) {
      return const _DayQualityHighlight(Colors.orangeAccent, Icons.info_outline); // Caution
    }
    return const _DayQualityHighlight(null, null);
  }
}

class _DayQualityHighlight {
  const _DayQualityHighlight(this.color, this.icon);
  final Color? color;
  final IconData? icon;
}
