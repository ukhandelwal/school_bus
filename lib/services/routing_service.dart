import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RoutingService {
  static const String _baseUrl = 'https://router.project-osrm.org/route/v1/driving/';

  static Future<List<LatLng>> getRouteCoordinates(List<LatLng> waypoints) async {
    if (waypoints.length < 2) return [];

    // Format waypoints for OSRM API
    String coordinates = waypoints.map((point) => '${point.longitude},${point.latitude}').join(';');

    final url = '$_baseUrl$coordinates?overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final geometry = data['routes'][0]['geometry'];

        if (geometry['type'] == 'LineString') {
          // Decode the polyline coordinates
          final coordinates = geometry['coordinates'] as List;
          return coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();
        }
      }
    } catch (e) {
      print('Error fetching route: $e');
    }

    // Fallback: return direct path if routing fails
    return waypoints;
  }
}