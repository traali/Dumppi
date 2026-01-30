// ignore_for_file: avoid_print

import 'package:latlong2/latlong.dart';
import 'package:dumppi/src/infrastructure/api/open_meteo_client.dart';
import 'package:dumppi/src/features/map/data/alpine_grid.dart';

void main() async {
  print('🏔️ Generating Fixtures for Alpine Powder...');
  
  // Force RECORD_MODE via client logic (we might need to tweak client to allow this easily e.g. constructor arg,
  // but for now we rely on the fact that we can't easily pass --dart-define here without running the script WITH it.
  // Actually, let's just use the client. But wait, the client reads the flag in constructor.
  // We can't easily inject the flag without modifying the client constructor again to accept an override,
  // or running this script with `dart run --define=RECORD_MODE=true`.
  
  print('Requires running with: dart run --define=RECORD_MODE=true scripts/generate_fixtures.dart');
  
  // Create client (Interceptor will check environment)
  final client = OpenMeteoClient();
  
  print('Fetching generic Alps grid...');
  try {
    // Fetch generic points to populate cache
    await for (final _ in client.fetchSnowfallForGrid(AlpineGrid.points)) {
      // Consuming stream to trigger recording
    }
    print('✅ Alps Grid fixtures generated.');
  } catch (e) {
    print('❌ Error fetching grid: $e');
  }

  print('Fetching detailed resort forecasts...');
  // Add a few major resorts
  final resorts = [
    const LatLng(45.9237, 6.8694), // Chamonix
    const LatLng(46.0207, 7.7491), // Zermatt
    const LatLng(47.1193, 10.1303), // St. Anton
  ];

  for (final resort in resorts) {
    try {
      await client.fetchResortForecast(resort.latitude, resort.longitude, baseAlt: 1000, topAlt: 2500);
      print('✅ Fixture for ${resort.latitude},${resort.longitude} generated.');
    } catch (e) {
      print('❌ Error fetching resort: $e');
    }
  }
}
