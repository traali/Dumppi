import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Interceptor that records API responses to local JSON files and replays them.
class FixtureInterceptor extends Interceptor {
  FixtureInterceptor({this.isRecordMode = false});

  /// If true, live calls are made and saved to fixtures.
  /// If false, requests are intercepted and served from fixtures.
  final bool isRecordMode;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _handleRequest(options, handler);
  }

  Future<void> _handleRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (isRecordMode) {
      // Pass through to live network
      return super.onRequest(options, handler);
    }

    try {
      final fixtureFile = _getFixtureFile(options);

      if (await fixtureFile.exists()) {
        final jsonString = await fixtureFile.readAsString();
        final json = jsonDecode(jsonString);

        if (json is Map<String, dynamic> &&
            json.containsKey('response') &&
            json['response'] is Map) {
          final responseData = json['response']['body'];
          final statusCode = json['response']['status'] as int? ?? 200;
          
          // Mimic network delay for realism (optional, keep short)
          // await Future.delayed(const Duration(milliseconds: 100));

          handler.resolve(
            Response(
              requestOptions: options,
              data: responseData,
              statusCode: statusCode,
              statusMessage: 'OK (Fixture)',
            ),
          );
          return;
        }
      }

      // If fixture doesn't exist, we must fail in REPLAY mode.
      // If fixture doesn't exist, fallback to live network.
      debugPrint('Fixture not found: ${fixtureFile.path}. Falling back to live network.');
      return super.onRequest(options, handler);
    } catch (e) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: 'Error reading fixture: $e',
        ),
      );
    }
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    _handleResponse(response, handler);
  }

  Future<void> _handleResponse(Response<dynamic> response, ResponseInterceptorHandler handler) async {
    if (isRecordMode) {
      try {
        final fixtureFile = _getFixtureFile(response.requestOptions);
        
        // Ensure directory exists
        if (!await fixtureFile.parent.exists()) {
          await fixtureFile.parent.create(recursive: true);
        }

        final fixtureData = {
          'meta': {
            'url': response.requestOptions.uri.toString(),
            'method': response.requestOptions.method,
            'timestamp': DateTime.now().toIso8601String(),
          },
          'response': {
            'status': response.statusCode,
            'body': response.data,
          }
        };

        const encoder = JsonEncoder.withIndent('  ');
        await fixtureFile.writeAsString(encoder.convert(fixtureData));
        debugPrint('Saved fixture: ${fixtureFile.path}');
        
      } catch (e) {
        debugPrint('Failed to save fixture: $e');
      }
    }
    super.onResponse(response, handler);
  }

  File _getFixtureFile(RequestOptions options) {
    // Hash the request to generate a unique filename
    // We include method, path, and query parameters.
    final key = '${options.method}:${options.uri}';
    final bytes = utf8.encode(key);
    final hash = md5.convert(bytes).toString();

    // Determine subfolder based on host or path segments
    // For OpenMeteo, we can just dump in fixtures/open_meteo/
    final pathSegments = options.uri.pathSegments;
    final category = pathSegments.isNotEmpty ? pathSegments.first : 'root';
    
    // Note: This path assumes strict project structure. 
    // In a real device scenario, we might need to use path_provider.
    // However, for "Development" aimed at committing fixtures, strict paths work on host.
    // If running on emulator/device, this fails without host file access.
    // Assuming development runs on desktop target (Windows/Mac/Linux) for recording.
    return File('fixtures/open_meteo/$category/$hash.json');
  }
}
