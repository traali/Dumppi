/// Resort model representing a ski resort or a custom saved point.
library;

/// Detailed lift statistics for a resort.
class LiftStats {
  const LiftStats({
    this.gondolas = 0,
    this.chairlifts = 0,
    this.surfaceLifts = 0,
  });

  factory LiftStats.fromJson(Map<String, dynamic> json) {
    return LiftStats(
      gondolas: json['gondolas'] as int? ?? 0,
      chairlifts: json['chairlifts'] as int? ?? 0,
      surfaceLifts: json['surface_lifts'] as int? ?? 0,
    );
  }

  final int gondolas;
  final int chairlifts;
  final int surfaceLifts;

  int get total => gondolas + chairlifts + surfaceLifts;

  Map<String, dynamic> toJson() {
    return {
      'gondolas': gondolas,
      'chairlifts': chairlifts,
      'surface_lifts': surfaceLifts,
    };
  }
}

/// Model for a ski resort or custom point with metadata and location.
class Resort {
  const Resort({
    required this.id,
    required this.name,
    required this.country,
    required this.lat,
    required this.lng,
    required this.baseAlt,
    required this.topAlt,
    this.downhillRunsKm,
    this.lifts,
    this.slopeAspectData,
    this.isFavorite = false,
    this.isCustom = false,
  });

  factory Resort.fromJson(Map<String, dynamic> json) {
    return Resort(
      id: json['id'] as String,
      name: json['name'] as String,
      country: json['country'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      baseAlt: json['base_alt'] as int,
      topAlt: json['top_alt'] as int,
      downhillRunsKm: (json['downhill_runs_km'] as num?)?.toDouble(),
      lifts: json['lifts'] != null 
          ? LiftStats.fromJson(json['lifts'] as Map<String, dynamic>) 
          : null,
      slopeAspectData: (json['slope_aspect_data'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      isFavorite: json['isFavorite'] as bool? ?? false,
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }

  final String id;
  final String name;
  final String country;
  final double lat;
  final double lng;
  final int baseAlt;
  final int topAlt;
  
  /// Total length of downhill runs in km.
  final double? downhillRunsKm;
  
  /// Lift counts.
  final LiftStats? lifts;
  
  /// Distribution of slope aspects (N, NE, E, SE, S, SW, W, NW).
  /// Typically 8 values sum to 1.0.
  final List<double>? slopeAspectData;

  final bool isFavorite;
  final bool isCustom;

  int get verticalDrop => topAlt - baseAlt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'country': country,
      'lat': lat,
      'lng': lng,
      'base_alt': baseAlt,
      'top_alt': topAlt,
      'downhill_runs_km': downhillRunsKm,
      'lifts': lifts?.toJson(),
      'slope_aspect_data': slopeAspectData,
      'isFavorite': isFavorite,
      'isCustom': isCustom,
    };
  }

  Resort copyWith({
    String? id,
    String? name,
    String? country,
    double? lat,
    double? lng,
    int? baseAlt,
    int? topAlt,
    double? downhillRunsKm,
    LiftStats? lifts,
    List<double>? slopeAspectData,
    bool? isFavorite,
    bool? isCustom,
  }) {
    return Resort(
      id: id ?? this.id,
      name: name ?? this.name,
      country: country ?? this.country,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      baseAlt: baseAlt ?? this.baseAlt,
      topAlt: topAlt ?? this.topAlt,
      downhillRunsKm: downhillRunsKm ?? this.downhillRunsKm,
      lifts: lifts ?? this.lifts,
      slopeAspectData: slopeAspectData ?? this.slopeAspectData,
      isFavorite: isFavorite ?? this.isFavorite,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}
