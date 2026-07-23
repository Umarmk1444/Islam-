import 'dart:convert';
import 'package:latlong2/latlong.dart';

class Mosque {
  final String id;
  final String name;
  final double lat;
  final double lon;

  // Calculated offline via Haversine (meters)
  double? approxDistanceMeters;

  // Fetched via OSRM
  double? osrmDistanceMeters;
  double? osrmWalkingDurationSeconds;
  double? osrmDrivingDurationSeconds;

  bool isFavorite;

  Mosque({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    this.approxDistanceMeters,
    this.osrmDistanceMeters,
    this.osrmWalkingDurationSeconds,
    this.osrmDrivingDurationSeconds,
    this.isFavorite = false,
  });

  LatLng get latLng => LatLng(lat, lon);

  // Preferred distance for display
  double get displayDistanceMeters => osrmDistanceMeters ?? approxDistanceMeters ?? 0.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'lat': lat,
      'lon': lon,
      'isFavorite': isFavorite,
    };
  }

  factory Mosque.fromMap(Map<String, dynamic> map) {
    return Mosque(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unknown Mosque',
      lat: double.tryParse(map['lat']?.toString() ?? '0') ?? 0.0,
      lon: double.tryParse(map['lon']?.toString() ?? '0') ?? 0.0,
      isFavorite: map['isFavorite'] == true || map['isFavorite'] == 1,
    );
  }

  String toJson() => json.encode(toMap());

  factory Mosque.fromJson(String source) => Mosque.fromMap(json.decode(source));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Mosque && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
