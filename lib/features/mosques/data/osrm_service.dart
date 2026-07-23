import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OsrmRouteData {
  final double distanceMeters;
  final double durationSeconds;

  OsrmRouteData({required this.distanceMeters, required this.durationSeconds});
}

class OsrmService {
  static const String _baseUrl = 'http://router.project-osrm.org/route/v1';

  /// Fetches routing data from OSRM. 
  /// Profile can be 'driving' or 'foot'.
  Future<OsrmRouteData?> getRoute({
    required LatLng start,
    required LatLng end,
    String profile = 'driving',
  }) async {
    final url = '$_baseUrl/$profile/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=false';
    
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          return OsrmRouteData(
            distanceMeters: (route['distance'] ?? 0).toDouble(),
            durationSeconds: (route['duration'] ?? 0).toDouble(),
          );
        }
      }
    } catch (e) {
      // Return null on failure, prompting graceful fallback
    }
    return null;
  }
}
