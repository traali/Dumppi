/// Alpine grid points for snowfall queries.
///
/// Pre-defined static grid covering the European Alps and Norway.
library;

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Grid resolution tiers based on zoom level.
enum GridResolution {
  overview(0.50, 55000), // Zoom 5-7
  regional(0.10, 11000), // Zoom 8-10
  local(0.02, 2200);   // Zoom 11+

  final double step;
  final double stepMeters;
  const GridResolution(this.step, this.stepMeters);

  static GridResolution fromZoom(double zoom) {
    if (zoom <= 7.9) return overview;
    if (zoom <= 10.9) return regional;
    return local;
  }
}

/// Static grid of lat/lon points for Open-Meteo batch queries.
class AlpineGrid {
  AlpineGrid._();

  /// All grid points for the Alps and Norway (Overview Level).
  static List<LatLng> get points => [
        ..._westernAlps,
        ..._easternAlps,
        ..._norway,
      ];

  static final List<LatLng> _westernAlps = _generateGrid(
    latStart: 44.5,
    latEnd: 47.5,
    lonStart: 5.5,
    lonEnd: 10.5,
    spacing: GridResolution.overview.step,
  );

  static final List<LatLng> _easternAlps = _generateGrid(
    latStart: 46.0,
    latEnd: 48.0,
    lonStart: 10.5,
    lonEnd: 16.0,
    spacing: GridResolution.overview.step,
  );

  static final List<LatLng> _norway = _generateGrid(
    latStart: 59.0,
    latEnd: 70.0,
    lonStart: 6.0,
    lonEnd: 12.0,
    spacing: GridResolution.overview.step,
  );

  /// Generate grid points within the given bounds at specific resolution.
  static List<LatLng> generateForBounds(LatLngBounds bounds, GridResolution resolution) {
    return _generateGrid(
      latStart: bounds.south,
      latEnd: bounds.north,
      lonStart: bounds.west,
      lonEnd: bounds.east,
      spacing: resolution.step,
    );
  }

  /// Generate a grid of lat/lon points.
  static List<LatLng> _generateGrid({
    required double latStart,
    required double latEnd,
    required double lonStart,
    required double lonEnd,
    required double spacing,
  }) {
    final points = <LatLng>[];
    
    // We snap coordinates to the grid resolution to ensure consistency
    final startLat = (latStart / spacing).floor() * spacing;
    final endLat = (latEnd / spacing).ceil() * spacing;
    final startLon = (lonStart / spacing).floor() * spacing;
    final endLon = (lonEnd / spacing).ceil() * spacing;

    for (var lat = startLat; lat <= endLat + (spacing * 0.1); lat += spacing) {
      for (var lon = startLon; lon <= endLon + (spacing * 0.1); lon += spacing) {
        points.add(LatLng(
          double.parse(lat.toStringAsFixed(4)), 
          double.parse(lon.toStringAsFixed(4))
        ));
      }
    }
    return points;
  }
}

