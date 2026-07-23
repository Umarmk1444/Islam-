import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'mosque_model.dart';

class OverpassService {
  static const String _baseUrl = 'https://overpass-api.de/api/interpreter';

  Future<List<Mosque>> fetchMosquesAround(LatLng center, double radius) async {
    final query = '''
      [out:json][timeout:15];
      (
        node["amenity"="place_of_worship"]["religion"="islam"](around:$radius,${center.latitude},${center.longitude});
        way["amenity"="place_of_worship"]["religion"="islam"](around:$radius,${center.latitude},${center.longitude});
        relation["amenity"="place_of_worship"]["religion"="islam"](around:$radius,${center.latitude},${center.longitude});
      );
      out center;
    ''';

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        body: {'data': query},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List elements = data['elements'] ?? [];
        return elements.map((e) {
          final double lat = e['type'] == 'node' ? (e['lat'] ?? 0.0) : (e['center']?['lat'] ?? 0.0);
          final double lon = e['type'] == 'node' ? (e['lon'] ?? 0.0) : (e['center']?['lon'] ?? 0.0);
          final name = e['tags']?['name'] ?? e['tags']?['name:en'] ?? e['tags']?['name:ar'] ?? 'Unknown Mosque';
          return Mosque(
            id: e['id'].toString(),
            name: name,
            lat: lat,
            lon: lon,
          );
        }).toList();
      }
    } catch (e) {
      // Return empty list on failure
    }
    return [];
  }
}
