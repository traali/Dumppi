import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/alpine_grid.dart';
import '../data/grid_forecast.dart';
import 'package:dumppi/src/infrastructure/api/open_meteo_client.dart';

/// Manages snowfall forecast data and map visualization states.
class ForecastProvider with ChangeNotifier {
  ForecastProvider();

  final OpenMeteoClient _client = OpenMeteoClient();
  
  /// Cache of forecasts by coordinate "lat,lon"
  final Map<String, GridForecast> _forecastCache = {};
  
  /// Exposed list for the UI
  List<GridForecast> get forecasts => _forecastCache.values.toList();

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String _cacheKey(LatLng p) => '${p.latitude.toStringAsFixed(4)},${p.longitude.toStringAsFixed(4)}';

  String? _error;
  String? get error => _error;
  
  /// Current resolution being targeted
  GridResolution _currentResolution = GridResolution.overview;
  GridResolution get currentResolution => _currentResolution;

  /// 0 = Today, 1 = Tomorrow, ..., 6 = +6 days
  int _selectedDay = 0;
  int get selectedDay => _selectedDay;

  /// If true, we show historical data from the last 2 days.
  /// 0 = -2 days ago, 1 = -1 day ago.
  bool _isShowingHistory = false;
  bool get isShowingHistory => _isShowingHistory;
  
  int _historyDay = 1; // Default to yesterday
  int get historyDay => _historyDay;

  /// Whether to show wind vector overlay
  bool _showWindVectors = false;
  bool get showWindVectors => _showWindVectors;

  /// Whether to show snowfall heatmap
  bool _showHeatmap = true;
  bool get showHeatmap => _showHeatmap;

  /// Opacity of the heatmap (0.0 to 1.0)
  double _heatmapOpacity = 1.0;
  double get heatmapOpacity => _heatmapOpacity;

  DateTime _lastFetch = DateTime(2000);
  bool _isFetchingBounds = false;
  LatLngBounds? _lastFetchedBounds;
  DateTime _rateLimitResetAt = DateTime(2000);

  Future<void> _loadForecasts({bool forceRefresh = false}) async {
    // Cache for 1 hour
    if (!forceRefresh && DateTime.now().difference(_lastFetch).inHours < 1 && _forecastCache.isNotEmpty) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await for (final chunk in _client.fetchSnowfallForGrid(AlpineGrid.points)) {
        for (final f in chunk) {
          _forecastCache[_cacheKey(f.point)] = f;
        }
        _lastFetch = DateTime.now();
        notifyListeners(); // Progressive update
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading forecasts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSelectedDay(int day) {
    _selectedDay = day;
    _isShowingHistory = false;
    notifyListeners();
  }

  void setHistoryDay(int day) {
    _historyDay = day;
    _isShowingHistory = true;
    notifyListeners();
  }

  void toggleViewMode(bool showHistory) {
    _isShowingHistory = showHistory;
    notifyListeners();
  }

  void toggleWindVectors() {
    _showWindVectors = !_showWindVectors;
    notifyListeners();
  }

  void toggleHeatmap() {
    _showHeatmap = !_showHeatmap;
    notifyListeners();
  }

  void setHeatmapOpacity(double value) {
    _heatmapOpacity = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// Get the correct index for the daily lists (snowfall, wind)
  /// -1 = Cumulative Forecast (Sum of all 7 days)
  int get currentMetricIndex {
    if (_isShowingHistory) {
      return _historyDay; // 0 or 1
    } else {
      // If selectedDay is -1, it represents "Total"
      if (_selectedDay == -1) return -1;
      return _selectedDay + 2; // Shifting by 2 to skip history
    }
  }

  /// Returns the accumulation for the selected day/mode for a specific point.
  double getSnowfallForPoint(LatLng point) {
    try {
      final forecast = _forecastCache[_cacheKey(point)];
      if (forecast == null) return 0.0;
      
      final idx = currentMetricIndex;
      
      if (idx == -1) {
        // Forecast sum (Skip first 2 history indices)
        return forecast.dailySnowfall.sublist(2).reduce((a, b) => a + b);
      }
      
      if (idx >= 0 && idx < forecast.dailySnowfall.length) {
        return forecast.dailySnowfall[idx];
      }
      return 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  /// Fetch forecasts for the specific map bounds.
  Future<void> fetchForBounds(LatLngBounds bounds, double zoom) async {
    if (_isFetchingBounds) return;
    if (DateTime.now().isBefore(_rateLimitResetAt)) return;

    final targetRes = GridResolution.fromZoom(zoom);
    _currentResolution = targetRes;

    // View overlap check: if we already fetched a similar area, skip
    if (_lastFetchedBounds != null && targetRes == _currentResolution) {
      final oldCenter = _lastFetchedBounds!.center;
      final newCenter = bounds.center;
      final dist = (oldCenter.latitude - newCenter.latitude).abs() + (oldCenter.longitude - newCenter.longitude).abs();
      
      final threshold = (bounds.north - bounds.south) * 0.15;
      if (dist < threshold && 
          (bounds.north - bounds.south - (_lastFetchedBounds!.north - _lastFetchedBounds!.south)).abs() < threshold) {
        return;
      }
    }

    _isFetchingBounds = true;
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Generate grid points for the view at target resolution
      final neededPoints = AlpineGrid.generateForBounds(bounds, targetRes);
      
      // 2. Filter out points we already have in cache
      final newPoints = neededPoints.where((p) {
        return !_forecastCache.containsKey(_cacheKey(p));
      }).toList();

      if (newPoints.isNotEmpty) {
        // Limit chunk size to avoid massive requests (Open-Meteo free tier)
        if (newPoints.length > 450) {
          newPoints.removeRange(450, newPoints.length);
        }

        await for (final chunk in _client.fetchSnowfallForGrid(newPoints)) {
          for (final f in chunk) {
            _forecastCache[_cacheKey(f.point)] = f;
          }
          _lastFetch = DateTime.now();
          _lastFetchedBounds = bounds;
          notifyListeners(); // Progressive update for visible area
        }
      }
    } catch (e) {
      debugPrint('Error fetching bounds: $e');
      _error = 'Failed to load area data: $e';
      if (e.toString().contains('429')) {
        _rateLimitResetAt = DateTime.now().add(const Duration(seconds: 30));
        _error = 'Rate limit hit. Pausing updates for 30s.';
      }
    } finally {
      _isFetchingBounds = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh data manually
  Future<void> refresh() async {
    _lastFetch = DateTime(2000);
    _forecastCache.clear();
    await _loadForecasts(forceRefresh: true);
  }

  /// Compatibility getter for legacy HeatmapLayer
  List<double> get snowfallList => _forecastCache.values.map((f) => f.dailySnowfall[currentMetricIndex]).toList();
  
  /// Helper for MapScreen
  Future<void> loadForecasts({bool forceRefresh = false}) => _loadForecasts(forceRefresh: forceRefresh);
}
