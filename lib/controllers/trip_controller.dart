import 'dart:async';
import 'dart:math';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../constants/app_constants.dart';
import '../models/stop_model.dart';
import '../services/location_service.dart';
import '../services/mock_data_service.dart';
import '../services/routing_service.dart';

class TripController extends GetxController {
  final RxList<Stop> stops = <Stop>[].obs;
  final RxBool isTripActive = false.obs;
  final Rx<LatLng> currentLocation = const LatLng(26.9239, 75.8267).obs; // Patrika Gate default
  final RxInt currentStopIndex = 1.obs;
  final RxList<LatLng> routePoints = <LatLng>[].obs;
  final RxBool isLoadingRoute = false.obs;

  // Heading in degrees (0..360, 0 = North)
  final RxDouble headingDeg = 0.0.obs;
  LatLng? _lastLocation;

  final LocationService _locationService = LocationService();
  StreamSubscription<Position>? _locationSub;
  Timer? _routeDebounce;

  @override
  void onInit() {
    super.onInit();
    loadMockData();
    _initLocation();
  }

  @override
  void onClose() {
    _routeDebounce?.cancel();
    _locationSub?.cancel();
    super.onClose();
  }

  void loadMockData() {
    stops.assignAll(MockDataService.getMockStops());
    _refreshRoute();
  }

  Future<void> _initLocation() async {
    try {
      final pos = await _locationService.getCurrentLocation();
      currentLocation.value = LatLng(pos.latitude, pos.longitude);
      _updateHeadingFromPosition(pos);
      _refreshRoute();
    } catch (_) {}
  }

  void startTrip() {
    if (isTripActive.value) return;
    isTripActive.value = true;

    _locationSub = _locationService.getLocationStream().listen((pos) {
      if (!isTripActive.value) return;

      final newLoc = LatLng(pos.latitude, pos.longitude);
      currentLocation.value = newLoc;

      _updateHeadingFromPosition(pos, fallbackFromLast: true);

      _checkStopProximity();
      _debouncedRefreshRoute();
    }, onError: (_) {});
  }

  void pauseTrip() {
    isTripActive.value = false;
    _locationSub?.pause();
  }

  void resumeTrip() {
    isTripActive.value = true;
    _locationSub?.resume();
  }

  void endTrip() {
    isTripActive.value = false;
    _locationSub?.cancel();
    _resetStops();
    if (stops.isNotEmpty) {
      currentLocation.value = LatLng(stops.first.latitude, stops.first.longitude);
    }
    _refreshRoute();
  }

  void _resetStops() {
    for (int i = 0; i < stops.length; i++) {
      stops[i].status = i == 0 ? StopStatus.current : StopStatus.upcoming;
    }
    if (stops.length > 1) stops[1].status = StopStatus.next;
    currentStopIndex.value = 0;
    stops.refresh();
  }

  void onStopSelected(Stop stop) {
    final index = stops.indexWhere((s) => s.id == stop.id);
    if (index == -1) return;

    currentStopIndex.value = index;
    currentLocation.value = LatLng(stop.latitude, stop.longitude);

    for (int i = 0; i < stops.length; i++) {
      if (i < index) {
        stops[i].status = StopStatus.completed;
      } else if (i == index) {
        stops[i].status = StopStatus.current;
      } else if (i == index + 1) {
        stops[i].status = StopStatus.next;
      } else {
        stops[i].status = StopStatus.upcoming;
      }
    }
    stops.refresh();
    _refreshRoute();
  }

  void _checkStopProximity() {
    for (int i = 0; i < stops.length; i++) {
      final stop = stops[i];
      final distanceKm = _haversineKm(
        currentLocation.value.latitude,
        currentLocation.value.longitude,
        stop.latitude,
        stop.longitude,
      );

      if (distanceKm < AppConstants.stopProximityThreshold &&
          (stop.status == StopStatus.upcoming || stop.status == StopStatus.next)) {
        if (currentStopIndex.value >= 0 && currentStopIndex.value < stops.length) {
          stops[currentStopIndex.value].status = StopStatus.completed;
        }

        stop.status = StopStatus.current;
        currentStopIndex.value = i;

        if (i + 1 < stops.length) {
          stops[i + 1].status = StopStatus.next;
        }
        for (int j = i + 2; j < stops.length; j++) {
          stops[j].status = StopStatus.upcoming;
        }

        stops.refresh();
        _refreshRoute();
        break;
      }
    }
  }

  void _debouncedRefreshRoute() {
    _routeDebounce?.cancel();
    _routeDebounce = Timer(const Duration(seconds: 3), _refreshRoute);
  }

  Future<void> _refreshRoute() async {
    final remaining = stops.where((s) =>
    s.status == StopStatus.current ||
        s.status == StopStatus.next ||
        s.status == StopStatus.upcoming).toList();

    if (remaining.isEmpty) {
      routePoints.clear();
      return;
    }

    final waypoints = <LatLng>[
      currentLocation.value,
      ...remaining.map((s) => LatLng(s.latitude, s.longitude)),
    ];

    isLoadingRoute.value = true;
    final points = await RoutingService.getRouteCoordinates(waypoints);
    routePoints.assignAll(points);
    isLoadingRoute.value = false;
  }

  // ----- Heading helpers -----

  void _updateHeadingFromPosition(Position pos, {bool fallbackFromLast = false}) {
    final newLoc = LatLng(pos.latitude, pos.longitude);

    double newHeading = pos.heading; // degrees, -1 if not available
    if (newHeading.isNaN || newHeading < 0.0 || newHeading == 0.0) {
      if (fallbackFromLast && _lastLocation != null &&
          (_lastLocation!.latitude != newLoc.latitude || _lastLocation!.longitude != newLoc.longitude)) {
        newHeading = _bearingDegrees(_lastLocation!, newLoc);
      }
    }

    final normalized = _normalizeDegrees(newHeading);
    headingDeg.value = _smoothHeading(headingDeg.value, normalized);
    _lastLocation = newLoc;
  }

  double _normalizeDegrees(double d) {
    if (d.isNaN) return 0.0;
    d = d % 360.0;
    if (d < 0) d += 360.0;
    return d;
  }

  // Smoothly interpolate heading to avoid jitter
  double _smoothHeading(double prev, double next, {double alpha = 0.25}) {
    double delta = ((next - prev + 540) % 360) - 180; // shortest angular distance
    return (prev + alpha * delta + 360) % 360;
  }

  // Bearing from point A to B in degrees (0..360, 0 = North)
  double _bearingDegrees(LatLng from, LatLng to) {
    final lat1 = _degToRad(from.latitude);
    final lat2 = _degToRad(to.latitude);
    final dLon = _degToRad(to.longitude - from.longitude);
    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    final brng = atan2(y, x);
    var deg = (brng * 180.0 / pi);
    deg = (deg + 360.0) % 360.0;
    return deg;
  }

  // ----- Math helpers -----

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _degToRad(double deg) => deg * (pi / 180.0);
}
