import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:dumppi/src/features/resorts/logic/resort_provider.dart';

/// Renders markers for each ski resort and custom stash in the dataset.
class ResortMarkerLayer extends StatelessWidget {
  const ResortMarkerLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ResortProvider>(
      builder: (context, provider, _) {
        return MarkerLayer(
          markers: provider.resorts.map((resort) {
            final isSelected = provider.selectedResort?.id == resort.id;
            
            return Marker(
              point: LatLng(resort.lat, resort.lng),
              width: 44,
              height: 44,
              child: GestureDetector(
                onTap: () => provider.selectResort(resort),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        resort.isCustom ? Icons.adjust : Icons.location_on,
                        color: isSelected 
                            ? Colors.redAccent 
                            : (resort.isFavorite ? Colors.amber : Colors.white),
                        size: 34,
                        shadows: const [
                          Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      if (resort.isFavorite && !resort.isCustom && !isSelected)
                        const Positioned(
                          top: 0,
                          right: 0,
                          child: Icon(Icons.star, color: Colors.amber, size: 14),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
