import 'package:latlong2/latlong.dart';

/// Forecast data for a single point on the grid.
class GridForecast {
  const GridForecast({
    required this.point,
    required this.dailySnowfall,
    required this.dailyWindDirection,
    required this.hourlyWindDirection,
    required this.hourlyWindSpeed,
  });

  final LatLng point;
  
  /// Index 0-1: History (-2, -1 days)
  /// Index 2: Today (Index 0 in old logic)
  /// Index 3-8: Forecast (+1 to +6 days)
  final List<double> dailySnowfall;
  
  /// Dominant wind direction for each day (9 days)
  final List<double> dailyWindDirection;

  /// Hourly data (9 days * 24 hours = 216 entries)
  final List<double> hourlyWindDirection;
  final List<double> hourlyWindSpeed;
}
