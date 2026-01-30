import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import 'package:dumppi/src/features/map/logic/forecast_provider.dart';
import 'package:dumppi/src/features/map/ui/widgets/heatmap_layer.dart';
import 'package:dumppi/src/features/map/ui/widgets/legend_widget.dart';
import 'package:dumppi/src/features/map/ui/widgets/day_slider.dart';
import 'package:dumppi/src/features/map/ui/widgets/wind_vector_layer.dart';
import 'package:dumppi/src/features/resorts/ui/widgets/resort_marker_layer.dart';
import 'package:dumppi/src/features/resorts/ui/widgets/resort_detail_sheet.dart';
import 'package:dumppi/src/features/resorts/logic/resort_provider.dart';
import 'package:dumppi/src/features/settings/ui/about_dialog_widget.dart';
import 'package:dumppi/src/features/map/ui/widgets/layer_settings_dialog.dart';

/// Main map screen showing snowfall heatmap and wind vectors.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  double _currentZoom = 6.0; // Initial zoom
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final resortProvider = context.read<ResortProvider>();
      final forecastProvider = context.read<ForecastProvider>();
      
      resortProvider.addListener(_onResortError);
      resortProvider.addListener(_onResortSelectedChanged);
      forecastProvider.addListener(_onForecastError);
      
      // Trigger initial fetch for visible map area immediately
      // We use a small delay to ensure the MapController has projected correctly
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          forecastProvider.fetchForBounds(_mapController.camera.visibleBounds, _currentZoom);
        }
      });
      
      // Attempt to locate user on start
      resortProvider.determinePosition();
    });
  }

  void _onResortError() {
    final provider = context.read<ResortProvider>();
    if (provider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!), 
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onForecastError() {
    final provider = context.read<ForecastProvider>();
    if (provider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!), 
          backgroundColor: Colors.redAccent, 
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onResortSelectedChanged() {
    final selectedResort = context.read<ResortProvider>().selectedResort;
    if (selectedResort != null && mounted) {
      _mapController.move(LatLng(selectedResort.lat, selectedResort.lng), 10.0);
      setState(() => _currentZoom = 10.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<ForecastProvider, ResortProvider>(
        builder: (context, forecastProvider, resortProvider, _) {
          return Stack(
            children: [
              // Map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const LatLng(46.5, 10.0), // Alps center
                  initialZoom: _currentZoom,
                  minZoom: 4.0,
                  maxZoom: 14.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                  onPositionChanged: (camera, isGesture) {
                    if (camera.zoom != _currentZoom) {
                      setState(() => _currentZoom = camera.zoom);
                    }

                    // Phase 3: Dynamic Loading with Debounce
                    // Only fetch if zoom is high enough to care about local details
                    if (camera.zoom > 8.0) {
                      _debounceTimer?.cancel();
                      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                        if (mounted) {
                          context.read<ForecastProvider>().fetchForBounds(camera.visibleBounds, camera.zoom);
                        }
                      });
                    }
                  },
                  onTap: (tapPosition, point) {
                    if (_currentZoom > 10.0) {
                      resortProvider.selectPoint(point.latitude, point.longitude);
                    }
                  },
                ),
                children: [
                  // Light Base Map
                  TileLayer(
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.alpinepowder.alpine_powder',
                  ),
                  // Pistes Overlay
                  TileLayer(
                    urlTemplate: 'https://tiles.opensnowmap.org/pistes/{z}/{x}/{y}.png',
                  ),
                  // Snowfall Heatmap
                  HeatmapLayer(
                    dayIndex: forecastProvider.currentMetricIndex,
                    zoom: _currentZoom,
                  ),
                  // Wind Vectors
                  const WindVectorLayer(),
                  // User Location Marker
                  if (resortProvider.userLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: resortProvider.userLocation!,
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () => resortProvider.selectPoint(
                              resortProvider.userLocation!.latitude, 
                              resortProvider.userLocation!.longitude,
                              name: 'My Location',
                              country: 'GPS Position',
                            ),
                            child: const _UserLocationMarker(),
                          ),
                        ),
                      ],
                    ),
                  // Resorts & Stashes
                  const ResortMarkerLayer(),
                ],
              ),

              // Loading Indicator
              if (forecastProvider.isLoading)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                  ),
                ),

              // Sidebar Controls
              Positioned(
                top: 60,
                left: 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(13),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withAlpha(26)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _controlButton(
                            icon: forecastProvider.isShowingHistory ? Icons.history : Icons.upcoming,
                            label: forecastProvider.isShowingHistory ? 'History' : 'Forecast',
                            isActive: forecastProvider.isShowingHistory,
                            onPressed: () => forecastProvider.toggleViewMode(!forecastProvider.isShowingHistory),
                          ),
                          const SizedBox(height: 16),
                          _controlButton(
                            icon: Icons.layers,
                            label: 'Layers',
                            isActive: false,
                            onPressed: () {
                              showDialog<void>(
                                context: context,
                                builder: (context) => const LayerSettingsDialog(),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _controlButton(
                            icon: Icons.air,
                            label: 'Wind',
                            isActive: forecastProvider.showWindVectors,
                            onPressed: () => forecastProvider.toggleWindVectors(),
                          ),
                          const SizedBox(height: 16),
                          if (_currentZoom > 10.0) ...[
                            _controlButton(
                              icon: Icons.radar,
                              label: 'Scan Area',
                              isActive: resortProvider.isLoading,
                              onPressed: () {
                                 final bounds = _mapController.camera.visibleBounds;
                                 resortProvider.scanForResorts(bounds).then((_) {
                                   if (context.mounted) {
                                     ScaffoldMessenger.of(context).showSnackBar(
                                       const SnackBar(content: Text('Scan complete!')),
                                     );
                                   }
                                 });
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                          _controlButton(
                            icon: Icons.info_outline,
                            label: 'About',
                            isActive: false,
                            onPressed: () {
                              showDialog<void>(
                                context: context,
                                builder: (context) => const AboutDialogWidget(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Refresh & Zoom & Location Controls
              Positioned(
                top: 60,
                right: 16,
                child: Column(
                  children: [
                    _glassFab(
                      heroTag: 'refresh',
                      icon: Icons.refresh,
                      onPressed: () => forecastProvider.refresh(),
                    ),
                    const SizedBox(height: 16),
                    _glassFab(
                      heroTag: 'my_location',
                      icon: Icons.my_location,
                      onPressed: () async {
                        try {
                          final pos = await resortProvider.determinePosition();
                          if (pos != null) {
                            _mapController.move(LatLng(pos.latitude, pos.longitude), 10.0);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        }
                      },
                      iconColor: const Color(0xFF0DB9F2),
                    ),
                    const SizedBox(height: 16),
                    _glassFab(
                      heroTag: 'zoom_in',
                      icon: Icons.add,
                      onPressed: () {
                        _mapController.move(_mapController.camera.center, _currentZoom + 1);
                        setState(() => _currentZoom += 1);
                      },
                    ),
                    const SizedBox(height: 8),
                    _glassFab(
                      heroTag: 'zoom_out',
                      icon: Icons.remove,
                      onPressed: () {
                        _mapController.move(_mapController.camera.center, _currentZoom - 1);
                        setState(() => _currentZoom -= 1);
                      },
                    ),
                  ],
                ),
              ),

              // Legend
              const Positioned(
                bottom: 120,
                right: 16,
                child: LegendWidget(),
              ),

              // Day Slider
              const Positioned(
                bottom: 30,
                left: 16,
                right: 16,
                child: DaySlider(),
              ),

              // Detail Sheet
              const ResortDetailSheet(),
            ],
          );
        },
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              color: isActive ? const Color(0xFF0DB9F2) : Colors.white70,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? const Color(0xFF0DB9F2) : Colors.white54, 
                fontSize: 9, 
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassFab({
    required String heroTag,
    required IconData icon,
    required VoidCallback onPressed,
    Color? iconColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: FloatingActionButton.small(
          heroTag: heroTag,
          backgroundColor: Colors.white.withAlpha(13),
          elevation: 0,
          onPressed: onPressed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withAlpha(26)),
          ),
          child: Icon(icon, color: iconColor ?? Colors.white70),
        ),
      ),
    );
  }
}

class _UserLocationMarker extends StatefulWidget {
  const _UserLocationMarker();

  @override
  State<_UserLocationMarker> createState() => _UserLocationMarkerState();
}

class _UserLocationMarkerState extends State<_UserLocationMarker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ScaleTransition(
          scale: Tween(begin: 1.0, end: 2.0).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOut),
          ),
          child: FadeTransition(
            opacity: Tween(begin: 0.5, end: 0.0).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOut),
            ),
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(50),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
