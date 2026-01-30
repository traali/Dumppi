/// Provider for managing resort data and selection.
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';

import 'package:dumppi/src/infrastructure/api/open_meteo_client.dart';
import 'package:dumppi/src/infrastructure/api/overpass_client.dart'; // Import
import 'package:flutter_map/flutter_map.dart'; // For LatLngBounds
import '../data/resort_model.dart';

/// State management for resorts.
class ResortProvider extends ChangeNotifier {
  ResortProvider();

  List<Resort> _resorts = [];
  List<Resort> get resorts => _resorts;

  Resort? _selectedResort;
  Resort? get selectedResort => _selectedResort;

  Map<String, dynamic>? _multiAltitudeForecast;
  Map<String, dynamic>? get multiAltitudeForecast => _multiAltitudeForecast;

  Map<String, dynamic>? get selectedForecast {
    if (_multiAltitudeForecast == null) return null;
    final forecasts = _multiAltitudeForecast!['forecasts'] as Map<String, dynamic>;
    if (_selectedAltitude == 'compare') return forecasts['top'] as Map<String, dynamic>; // Default to top for hourly/charts in compare mode
    return forecasts[_selectedAltitude] as Map<String, dynamic>;
  }

  String _selectedAltitude = 'base'; // 'base', 'mid', 'top'
  String get selectedAltitude => _selectedAltitude;

  int? get currentElevation {
    if (_multiAltitudeForecast == null) return null;
    final elevations = _multiAltitudeForecast!['elevations'] as Map<String, dynamic>;
    return elevations[_selectedAltitude] as int?;
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isForecastLoading = false;
  bool get isForecastLoading => _isForecastLoading;

  int _selectedDayIndex = 0;
  int get selectedDayIndex => _selectedDayIndex;

  LatLng? _userLocation;
  LatLng? get userLocation => _userLocation;

  Set<String> _favoriteIds = {};
  List<Resort> _customStashes = [];

  // API Safety
  DateTime? _lastScanTime;
  String? _error;
  String? get error => _error;

  final OpenMeteoClient _client = OpenMeteoClient();

  /// Load resorts from the local JSON asset and storage.
  Future<void> loadResorts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load favorites
      _favoriteIds = (prefs.getStringList('favorite_resorts') ?? []).toSet();
      
      // Load custom stashes
      final customData = prefs.getStringList('custom_stashes') ?? [];
      _customStashes = customData
          .map((s) => Resort.fromJson(json.decode(s) as Map<String, dynamic>))
          .toList();

      // Load base resorts from assets
      final String response = await rootBundle.loadString('assets/data/resorts.json');
      final List<dynamic> assetData = await json.decode(response) as List;
      final assetResorts = assetData.map((e) {
        final r = Resort.fromJson(e as Map<String, dynamic>);
        return r.copyWith(isFavorite: _favoriteIds.contains(r.id));
      }).toList();

      // Merge asset resorts and custom stashes
      _resorts = [...assetResorts, ..._customStashes];
      
      _sortResorts();
      
    } catch (e) {
      debugPrint('Error loading resorts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _sortResorts() {
    _resorts.sort((a, b) {
      if (a.isFavorite && !b.isFavorite) return -1;
      if (!a.isFavorite && b.isFavorite) return 1;
      return a.name.compareTo(b.name);
    });
  }

  /// Toggle favorite status of a resort.
  Future<void> toggleFavorite(Resort resort) async {
    final isFav = _favoriteIds.contains(resort.id);
    if (isFav) {
      _favoriteIds.remove(resort.id);
    } else {
      _favoriteIds.add(resort.id);
    }

    // Update in memory
    _resorts = _resorts.map((r) {
      if (r.id == resort.id) {
        return r.copyWith(isFavorite: !isFav);
      }
      return r;
    }).toList();

    if (_selectedResort?.id == resort.id) {
      _selectedResort = _selectedResort!.copyWith(isFavorite: !isFav);
    }

    _sortResorts();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_resorts', _favoriteIds.toList());
  }

  /// Save a custom point as a "Secret Stash".
  Future<void> saveCustomPoint(String name, double lat, double lng) async {
    final id = 'stash_${DateTime.now().millisecondsSinceEpoch}';
    final newStash = Resort(
      id: id,
      name: name,
      country: 'Secret Stash',
      lat: lat,
      lng: lng,
      baseAlt: 0,
      topAlt: 0,
      isCustom: true,
      isFavorite: true,
    );

    _favoriteIds.add(id);
    _customStashes.add(newStash);
    _resorts.add(newStash);
    _sortResorts();
    
    // Select the newly saved stash
    selectResort(newStash);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_resorts', _favoriteIds.toList());
    await prefs.setStringList(
      'custom_stashes',
      _customStashes.map((s) => json.encode(s.toJson())).toList(),
    );
  }

  /// Delete a custom stash.
  Future<void> deleteCustomStash(String id) async {
    _customStashes.removeWhere((s) => s.id == id);
    _favoriteIds.remove(id);
    _resorts.removeWhere((r) => r.id == id);
    
    if (_selectedResort?.id == id) {
      _selectedResort = null;
    }

    _sortResorts();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_resorts', _favoriteIds.toList());
    await prefs.setStringList(
      'custom_stashes',
      _customStashes.map((s) => json.encode(s.toJson())).toList(),
    );
  }

  /// Select a resort and fetch its forecast.
  void selectResort(Resort? resort) {
    _selectedResort = resort;
    _multiAltitudeForecast = null;
    _selectedDayIndex = 0;
    _selectedAltitude = 'base';
    notifyListeners();

    if (resort != null) {
      _fetchEnrichedForecast(resort);
    }
  }

  Future<void> _fetchEnrichedForecast(Resort resort) async {
    _isForecastLoading = true;
    notifyListeners();

    try {
      Resort activeResort = resort;

      // Deferred Elevation Enrichment
      if (resort.baseAlt == 0) {
        final groundEle = await ElevationFetcher.fetchElevation(_client.dio, resort.lat, resort.lng);
        if (groundEle > 0) {
          final newBase = groundEle.round();
          final newTop = resort.topAlt == 500 ? newBase + 500 : (resort.topAlt == 0 ? newBase + 800 : resort.topAlt);
          activeResort = resort.copyWith(baseAlt: newBase, topAlt: newTop);
          
          // Update in master list if possible
          _resorts = _resorts.map((r) => r.id == resort.id ? activeResort : r).toList();
          _selectedResort = activeResort;
          // notifyListeners() is called in finally or here if needed, but we keep going.
        }
      }

      _multiAltitudeForecast = await _client.fetchResortForecast(
        activeResort.lat, 
        activeResort.lng, 
        baseAlt: activeResort.baseAlt, 
        topAlt: activeResort.topAlt,
      );
    } catch (e) {
      debugPrint('Error fetching forecast: $e');
    } finally {
      _isForecastLoading = false;
      notifyListeners();
    }
  }

  /// Select an arbitrary point (for zoom-to-click) and fetch forecast.
  void selectPoint(double lat, double lng, {String name = 'Custom Point', String country = 'Map Selection'}) {
    final pointResort = Resort(
      id: 'custom_point',
      name: name,
      country: country,
      lat: lat,
      lng: lng,
      baseAlt: 0,
      topAlt: 0,
    );
    _selectedResort = pointResort;
    _multiAltitudeForecast = null;
    _selectedDayIndex = 0;
    _selectedAltitude = 'base';
    notifyListeners();

    _fetchEnrichedForecast(pointResort);
  }

  /// Locate the user and updates the internal state.
  Future<Position?> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    } 

    final position = await Geolocator.getCurrentPosition();
    _userLocation = LatLng(position.latitude, position.longitude);
    notifyListeners();
    return position;
  }

  /// Change the selected day for hourly breakdown.
  void setDayIndex(int index) {
    _selectedDayIndex = index;
    notifyListeners();
  }

  /// Change the selected altitude level.
  void setAltitude(String level) {
    if (['base', 'mid', 'top', 'compare'].contains(level)) {
      _selectedAltitude = level;
      notifyListeners();
    }
  }

  bool get isCompareMode => _selectedAltitude == 'compare';

  // --- Dynamic Fetching (OSM) ---

  final OverpassClient _osmClient = OverpassClient();

  /// Scans the current map bounds for resorts using OpenStreetMap.
  /// 
  /// Protected by Rate Limiting (1 request per 10s) and Area Size checks.
  Future<void> scanForResorts(LatLngBounds bounds) async {
    // 1. Rate Limiting
    if (_lastScanTime != null && DateTime.now().difference(_lastScanTime!).inSeconds < 10) {
      debugPrint('Scan ignored: Rate limit active.');
      return; 
    }

    // 2. Area Size Check (Prevent massive queries)
    // Approx conversion: 1 deg lat = 111km. 1 deg lon = 111km * cos(lat).
    final dLat = (bounds.north - bounds.south).abs();
    final dLon = (bounds.east - bounds.west).abs();
    
    // Using simple degree check for safety:
    // If area > 5.0 square degrees (approx large region), reject.
    // 5.0 sq deg is roughly equivalent to a 200km x 200km area in the Alps.
    final areaSqDeg = dLat * dLon;
    
    const maxSqDegrees = 5.0;


    if (areaSqDeg > maxSqDegrees) {
      debugPrint('Scan ignored: Area too large ($areaSqDeg sq deg > $maxSqDegrees). Zoom in.');
      return;
    }

    _isLoading = true;
    _error = null; // Clear previous errors
    notifyListeners();

    try {
      final newResorts = await _osmClient.fetchResortsInBounds(bounds);
      _lastScanTime = DateTime.now(); // Update success time
      
      int addedCount = 0;
      for (var r in newResorts) {
        final alreadyExists = _resorts.any((existing) => 
            existing.id == r.id || 
            existing.name.toLowerCase() == r.name.toLowerCase());
            
        if (!alreadyExists) {
          _resorts.add(r);
          addedCount++;
        }
      }
      
      debugPrint('OSM Scan complete. Discovery only (Optimized).');

      if (addedCount > 0) {
        _sortResorts();
        debugPrint('Added $addedCount resorts from OSM scan.');
      }
    } catch (e) {
      debugPrint('Scan failed: $e');
      _error = 'Scan failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper for cos check if needed, but math library usage is preferred if imported.
  // Since we don't have dart:math imported, we used the square degree heuristic.

}
