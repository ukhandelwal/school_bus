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
  // State
  final RxList<Stop> stops = <Stop>[].obs;
  final RxBool isTripActive = false.obs;
  final Rx<LatLng> currentLocation = const LatLng(26.9239, 75.8267).obs; // Patrika Gate
  final RxInt currentStopIndex = 1.obs; // start at second stop
  final RxList<LatLng> routePoints = <LatLng>[].obs;
  final RxBool isLoadingRoute = false.obs;

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
      _refreshRoute();
    } catch (_) {
      // keep default if error
    }
  }

  void startTrip() {
    if (isTripActive.value) return;
    isTripActive.value = true;

    _locationSub = _locationService.getLocationStream().listen((pos) {
      if (!isTripActive.value) return;
      currentLocation.value = LatLng(pos.latitude, pos.longitude);
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
    if (stops.length > 1) {
      stops[1].status = StopStatus.next;
    }
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
        // Promote statuses
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

  void _debouncedRefreshRoute() {
    _routeDebounce?.cancel();
    _routeDebounce = Timer(const Duration(seconds: 3), _refreshRoute);
  }

  Future<void> _refreshRoute() async {
    // Build waypoints: current location + remaining stops (current/next/upcoming)
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
}
