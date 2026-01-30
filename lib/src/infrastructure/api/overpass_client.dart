import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart'; // For LatLngBounds

import '../../features/resorts/data/resort_model.dart';

class OverpassClient {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://overpass-api.de/api/interpreter';

  /// Fetches ski resorts (winter_sports areas) within the given bounding box.
  Future<List<Resort>> fetchResortsInBounds(LatLngBounds bounds) async {
    // Overpass API expects: (south, west, north, east)
    final bbox = '${bounds.south},${bounds.west},${bounds.north},${bounds.east}';

    // Query for relations, ways, and nodes tagged as winter_sports
    // Also fetch all aerialways (lifts) in the same bbox to count them
    // And fetch peak nodes to estimate top altitude
    final query = '''
      [out:json][timeout:60];
      (
        node["landuse"="winter_sports"]($bbox);
        way["landuse"="winter_sports"]($bbox);
        relation["landuse"="winter_sports"]($bbox);
        node["sport"="skiing"]["name"]($bbox);
        
        // Fetch all lifts in the area
        node["aerialway"]($bbox);
        way["aerialway"]($bbox);
        
        // Fetch peaks to estimate max elevation
        node["natural"="peak"]($bbox);
      );
      out center;
    ''';

    try {
      final response = await _dio.get<String>(
        _baseUrl,
        queryParameters: {'data': query},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = json.decode(response.data!) as Map<String, dynamic>;
        return _parseOverpassResponse(data);
      } else {
        throw Exception('Overpass API returned status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching from Overpass: $e');
      rethrow;
    }
  }

  List<Resort> _parseOverpassResponse(Map<String, dynamic> data) {
    final elements = data['elements'] as List<dynamic>?;
    if (elements == null) return [];

    final rawResorts = <dynamic>[];
    final aerialways = <dynamic>[];
    final peaks = <dynamic>[];

    for (final el in elements) {
      final tags = el['tags'] as Map<String, dynamic>? ?? {};
      if (tags.containsKey('landuse') && tags['landuse'] == 'winter_sports' || tags.containsKey('sport') && tags['sport'] == 'skiing') {
        if (tags.containsKey('name')) rawResorts.add(el);
      } else if (tags.containsKey('aerialway')) {
        aerialways.add(el);
      } else if (tags.containsKey('natural') && tags['natural'] == 'peak') {
        peaks.add(el);
      }
    }

    final resorts = <Resort>[];

    for (final el in rawResorts) {
      try {
        final tags = el['tags'] as Map<String, dynamic>;
        
        // Extract center point
        double lat;
        double lng;

        if (el['type'] == 'node') {
          lat = (el['lat'] as num).toDouble();
          lng = (el['lon'] as num).toDouble();
        } else {
          final center = el['center'];
          if (center != null) {
            lat = (center['lat'] as num).toDouble();
            lng = (center['lon'] as num).toDouble();
          } else {
            continue;
          }
        }

        final name = tags['name'] as String;
        final cleanName = name.split('(').first.trim();
        
        // Find elevation if present in tags
        final int baseAlt = _parseElevation(tags['ele']);
        int topAlt = baseAlt;

        // Try to find the highest peak within 5km of the resort center
        for (final peak in peaks) {
          final pTags = peak['tags'] as Map<String, dynamic>;
          final pLat = (peak['lat'] as num).toDouble();
          final pLon = (peak['lon'] as num).toDouble();
          
          // Simple distance check if peak info available
          final distSq = (lat - pLat) * (lat - pLat) + (lng - pLon) * (lng - pLon);
          if (distSq < 0.0025) { // Approx 5km
            final pEle = _parseElevation(pTags['ele']);
            if (pEle > topAlt) topAlt = pEle;
          }
        }

        // Count lifts in proximity
        int gondolas = 0;
        int chairs = 0;
        int surface = 0;

        for (final lift in aerialways) {
          final lTags = lift['tags'] as Map<String, dynamic>;
          final type = lTags['aerialway'] as String;
          
          double? lLat;
          double? lLon;
          if (lift['type'] == 'node') {
            lLat = (lift['lat'] as num).toDouble();
            lLon = (lift['lon'] as num).toDouble();
          } else if (lift['center'] != null) {
            lLat = (lift['center']['lat'] as num).toDouble();
            lLon = (lift['center']['lon'] as num).toDouble();
          }

          if (lLat != null && lLon != null) {
            final distSq = (lat - lLat) * (lat - lLat) + (lng - lLon) * (lng - lLon);
            if (distSq < 0.001) { // Approx 3km radius for lifts
              if (type.contains('gondola') || type.contains('cable_car')) {
                gondolas++;
              } else if (type.contains('chair_lift')) {
                chairs++;
              } else if (type.contains('drag_lift') || type.contains('t-bar') || type.contains('j-bar') || type.contains('platter')) {
                surface++;
              }
            }
          }
        }

        resorts.add(Resort(
          id: 'osm_${el['id']}',
          name: cleanName,
          country: 'OSM Scan',
          lat: lat,
          lng: lng,
          baseAlt: baseAlt,
          topAlt: topAlt > baseAlt ? topAlt : baseAlt + 500, // Fallback vertical if unknown
          lifts: LiftStats(
            gondolas: gondolas,
            chairlifts: chairs,
            surfaceLifts: surface,
          ),
        ));
      } catch (e) {
        continue;
      }
    }

    return resorts;
  }

  int _parseElevation(dynamic ele) {
    if (ele == null) return 0;
    if (ele is int) return ele;
    if (ele is double) return ele.round();
    if (ele is String) {
      final clean = ele.replaceAll(RegExp(r'[^0-9]'), '');
      return int.tryParse(clean) ?? 0;
    }
    return 0;
  }
}
