import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

import '../../features/map/data/grid_forecast.dart';


/// Client for Open-Meteo weather API.
class OpenMeteoClient {
  OpenMeteoClient() : _dio = Dio(BaseOptions(
    baseUrl: 'https://api.open-meteo.com/v1/',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  )) {
    // Default to REPLAY mode. Run with --dart-define=RECORD_MODE=true to record.
    // NOTE: Recording requires running on Desktop (Windows/Mac/Linux) to write to disk.
    // const isRecord = bool.fromEnvironment('RECORD_MODE', defaultValue: false);
    // _dio.interceptors.add(FixtureInterceptor(isRecordMode: isRecord));
  }

  final Dio _dio;
  Dio get dio => _dio;

  /// Fetch 9-day snowfall and wind data for a grid (2 past + 7 forecast).
  /// Optimized for "Burst Mode": Batch 90, Concurrency 2, Throttle 100ms.
  /// Returns a Stream to allow progressive UI updates.
  Stream<List<GridForecast>> fetchSnowfallForGrid(List<LatLng> points) async* {
    const batchSize = 90; 
    const concurrency = 2;
    const throttleDelay = Duration(milliseconds: 100);
    
    final batches = <List<LatLng>>[];
    for (var i = 0; i < points.length; i += batchSize) {
      batches.add(points.skip(i).take(batchSize).toList());
    }

    // Process in chunks of 'concurrency'
    for (var i = 0; i < batches.length; i += concurrency) {
      if (i > 0) {
        await Future<void>.delayed(throttleDelay);
      }

      final end = (i + concurrency < batches.length) ? i + concurrency : batches.length;
      final currentBatches = batches.sublist(i, end);

      // Fire concurrent requests
      final results = await Future.wait(
        currentBatches.map((batch) => _fetchBatchWithRetry(batch).catchError((Object e) {
          developer.log('Burst Mode Error in batch: $e');
          return <GridForecast>[];
        }))
      );

      for (final batchResults in results) {
        if (batchResults.isNotEmpty) {
          yield batchResults;
        }
      }

      // If any request failed with 429, respect it and stop the burst
      if (results.any((r) => r.isEmpty && _lastErrorWasRateLimit)) {
        break;
      }
    }
  }

  bool _lastErrorWasRateLimit = false;


  Future<List<GridForecast>> _fetchBatchWithRetry(
    List<LatLng> batch, {
    int retries = 3,
    int backoffSeconds = 2,
  }) async {
    try {
      return await _fetchBatch(batch);
    } on OpenMeteoException catch (e) {
      if (e.message.contains('429') && retries > 0) {
        developer.log('Rate limited. Retrying in $backoffSeconds seconds...');
        await Future<void>.delayed(Duration(seconds: backoffSeconds));
        return _fetchBatchWithRetry(batch, retries: retries - 1, backoffSeconds: backoffSeconds * 2);
      }
      rethrow;
    }
  }

  Future<List<GridForecast>> _fetchBatch(List<LatLng> batch) async {
    final latitudes = batch.map((p) => p.latitude.toStringAsFixed(2)).join(',');
    final longitudes = batch.map((p) => p.longitude.toStringAsFixed(2)).join(',');

    try {
      final response = await _dio.get<dynamic>(
        'forecast',
        queryParameters: {
          'latitude': latitudes,
          'longitude': longitudes,
          'past_days': 2,
          'daily': 'snowfall_sum,winddirection_10m_dominant',
          'hourly': 'winddirection_10m,windspeed_10m',
          'wind_speed_unit': 'ms',
          'timezone': 'auto',
        },
      );
      _lastErrorWasRateLimit = false;
      return _parseResponse(response.data, batch);
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        _lastErrorWasRateLimit = true;
        throw OpenMeteoException('429: Too many requests.');
      }
      _lastErrorWasRateLimit = false;
      throw OpenMeteoException('API request failed: ${e.message}');
    }
  }

  List<GridForecast> _parseResponse(dynamic data, List<LatLng> requestedPoints) {
    final forecasts = <GridForecast>[];
    if (data is List) {
      for (var i = 0; i < data.length; i++) {
        forecasts.add(_parseSingleLocation(data[i], requestedPoints[i]));
      }
    } else if (data is Map) {
      forecasts.add(_parseSingleLocation(data, requestedPoints.first));
    }
    return forecasts;
  }

  GridForecast _parseSingleLocation(dynamic json, LatLng point) {
    final daily = json['daily'] as Map<String, dynamic>?;
    final hourly = json['hourly'] as Map<String, dynamic>?;

    final snowfallList = (daily?['snowfall_sum'] as List<dynamic>?)
            ?.map((e) => (e as num?)?.toDouble() ?? 0.0)
            .toList() ?? [];
            
    final dailyWindDir = (daily?['winddirection_10m_dominant'] as List<dynamic>?)
            ?.map((e) => (e as num?)?.toDouble() ?? 0.0)
            .toList() ?? [];

    final hourlyWindDir = (hourly?['winddirection_10m'] as List<dynamic>?)
            ?.map((e) => (e as num?)?.toDouble() ?? 0.0)
            .toList() ?? [];

    final hourlyWindSpeed = (hourly?['windspeed_10m'] as List<dynamic>?)
            ?.map((e) => (e as num?)?.toDouble() ?? 0.0)
            .toList() ?? [];

    return GridForecast(
      point: point,
      dailySnowfall: snowfallList,
      dailyWindDirection: dailyWindDir,
      hourlyWindDirection: hourlyWindDir,
      hourlyWindSpeed: hourlyWindSpeed,
    );
  }

  /// Fetch detailed forecast for a resort at three altitudes: Base, Mid, and Top.
  Future<Map<String, dynamic>> fetchResortForecast(double lat, double lng, {
    required int baseAlt,
    required int topAlt,
  }) async {
    final midAlt = (baseAlt + topAlt) ~/ 2;
    final elevations = [baseAlt, midAlt, topAlt];

    try {
      final response = await _dio.get<dynamic>(
        'forecast',
        queryParameters: {
          // Send 3 identical coordinates with 3 different elevations
          'latitude': '$lat,$lat,$lat',
          'longitude': '$lng,$lng,$lng',
          'elevation': elevations.join(','),
          'daily': 'snowfall_sum,temperature_2m_max,temperature_2m_min,windspeed_10m_max,windgusts_10m_max,winddirection_10m_dominant',
          'hourly': 'visibility,cloudcover,temperature_2m,snowfall,windspeed_10m,winddirection_10m,windgusts_10m',
          'wind_speed_unit': 'ms',
          'forecast_days': 7,
          'timezone': 'auto',
        },
      );
      
      final dynamic rawData = response.data;
      final results = <String, Map<String, dynamic>>{};

      if (rawData is List) {
        // Multi-location response
        results['base'] = _processForecastData(rawData[0] as Map<String, dynamic>);
        results['mid'] = _processForecastData(rawData[1] as Map<String, dynamic>);
        results['top'] = _processForecastData(rawData[2] as Map<String, dynamic>);
      } else if (rawData is Map) {
        // Single location response (shouldn't happen with comma-separated params, 
        // but Open-Meteo sometimes returns a single Map if all results are identical or error occurs)
        final processed = _processForecastData(rawData as Map<String, dynamic>);
        results['base'] = processed;
        results['mid'] = processed;
        results['top'] = processed;
      }
      
      return {
        'elevations': {
          'base': baseAlt,
          'mid': midAlt,
          'top': topAlt,
        },
        'forecasts': results,
      };
    } on DioException catch (e) {
      throw OpenMeteoException('Failed to fetch detailed multi-altitude forecast: ${e.message}');
    }
  }

  Map<String, dynamic> _processForecastData(Map<String, dynamic> data) {
    final hourly = data['hourly'] as Map<String, dynamic>;
    final daily = data['daily'] as Map<String, dynamic>;
    
    final hourlyVisibility = (hourly['visibility'] as List<dynamic>).map((v) => (v as num).toDouble()).toList();
    final hourlyCloudcover = (hourly['cloudcover'] as List<dynamic>).map((v) => (v as num).toDouble()).toList();
    
    final dailyVisibility = <double>[];
    final dailyCloudcover = <double>[];
    
    for (var i = 0; i < 7; i++) {
      final dayStart = i * 24;
      final dayEnd = dayStart + 24;
      if (dayEnd <= hourlyVisibility.length) {
        dailyVisibility.add(hourlyVisibility.sublist(dayStart, dayEnd).reduce((a, b) => a + b) / 24);
        dailyCloudcover.add(hourlyCloudcover.sublist(dayStart, dayEnd).reduce((a, b) => a + b) / 24);
      }
    }
    
    daily['visibility_mean'] = dailyVisibility;
    daily['cloudcover_mean'] = dailyCloudcover;
    
    return data;
  }
}

class OpenMeteoException implements Exception {
  OpenMeteoException(this.message);
  final String message;
  @override
  String toString() => 'OpenMeteoException: $message';
}

/// Helper for fetching elevation data.
class ElevationFetcher {
  static Future<double> fetchElevation(Dio dio, double lat, double lng) async {
    final results = await fetchElevations(dio, [lat], [lng]);
    return results.isNotEmpty ? results.first : 0.0;
  }

  static Future<List<double>> fetchElevations(Dio dio, List<double> lats, List<double> lngs) async {
    if (lats.isEmpty) return [];
    
    try {
      final response = await dio.get<dynamic>(
        'https://elevation-api.open-meteo.com/v1/elevation',
        queryParameters: {
          'latitude': lats.map((l) => l.toStringAsFixed(4)).join(','),
          'longitude': lngs.map((l) => l.toStringAsFixed(4)).join(','),
        },
      );
      final data = response.data as Map<String, dynamic>;
      final elevations = data['elevation'] as List<dynamic>;
      return elevations.map((e) => (e as num).toDouble()).toList();
    } catch (e) {
      return List.filled(lats.length, 0.0);
    }
  }
}
