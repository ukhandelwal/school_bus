import 'package:latlong2/latlong.dart';

class AppConstants {
  static const double stopProximityThreshold = 0.05; // 50 meters in kilometers
  static const int locationUpdateInterval = 5; // seconds
  static const double mapDefaultZoom = 15.0;

  // Jaipur center coordinates
  static const LatLng jaipurCenter = LatLng(26.9124, 75.7873);
}