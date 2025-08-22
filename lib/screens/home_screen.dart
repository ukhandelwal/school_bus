import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:latlong2/latlong.dart';

import '../constants/app_constants.dart';
import '../models/stop_model.dart';
import '../services/location_service.dart';
import '../services/mock_data_service.dart';
import '../widgets/bus_map_widget.dart';
import '../widgets/stop_list_widget.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<Stop> _stops;

  // Change this line in the _HomeScreenState class:
  LatLng _currentLocation = LatLng(26.9239, 75.8267); // Patrika Gate, Jaipur

  // And update the initial stop index:
  int _currentStopIndex = 1; // Start at Patrika Gate (second stop)
  bool _isTripActive = false;
  StreamSubscription<Position>? _locationSubscription;
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadMockData();
    _getInitialLocation();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  void _loadMockData() {
    setState(() {
      _stops = MockDataService.getMockStops();
    });
  }

  Future<void> _getInitialLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      print('Error getting initial location: $e');
    }
  }

  void _startTrip() {
    setState(() {
      _isTripActive = true;
    });

    // Start listening to location updates
    _locationSubscription = _locationService.getLocationStream().listen(
      (Position position) {
        if (_isTripActive) {
          setState(() {
            _currentLocation = LatLng(position.latitude, position.longitude);
          });

          // Update map center to follow the bus
          _mapController.move(
            LatLng(position.latitude, position.longitude),
            _mapController.camera.zoom,
          );

          // Check if we're approaching any stops
          _checkStopProximity();
        }
      },
      onError: (error) {
        print('Location stream error: $error');
      },
    );
  }

  void _checkStopProximity() {
    for (int i = 0; i < _stops.length; i++) {
      final stop = _stops[i];
      final distanceKm = _calculateDistance(
        _currentLocation.latitude,
        _currentLocation.longitude,
        stop.latitude,
        stop.longitude,
      );

      // Only react if stop not yet completed/current
      if (distanceKm < AppConstants.stopProximityThreshold &&
          (stop.status == StopStatus.upcoming ||
              stop.status == StopStatus.next)) {
        setState(() {
          // Mark previous current as completed
          if (_currentStopIndex >= 0 && _currentStopIndex < _stops.length) {
            _stops[_currentStopIndex].status = StopStatus.completed;
          }

          // Mark this one as current
          stop.status = StopStatus.current;
          _currentStopIndex = i;

          // Mark next
          if (i + 1 < _stops.length) {
            _stops[i + 1].status = StopStatus.next;
          }

          // Reset any later ones to upcoming to avoid multiple 'next'
          for (int j = i + 2; j < _stops.length; j++) {
            _stops[j].status = StopStatus.upcoming;
          }
        });

        _showStopApproachingNotification(stop.name);
        break;
      }
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const int earthRadius = 6371; // Earth's radius in kilometers

    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;

    return distance;
  }

  double _toRadians(double degree) {
    return degree * (pi / 180);
  }

  void _showStopApproachingNotification(String stopName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Approaching $stopName'),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _pauseTrip() {
    setState(() {
      _isTripActive = false;
    });
    _locationSubscription?.pause();
  }

  void _resumeTrip() {
    setState(() {
      _isTripActive = true;
    });
    _locationSubscription?.resume();
  }

  void _endTrip() {
    setState(() {
      _isTripActive = false;
      _currentStopIndex = 0;
    });

    _locationSubscription?.cancel();
    _resetStops();

    // Return to first stop location
    if (_stops.isNotEmpty) {
      setState(() {
        _currentLocation = LatLng(_stops[0].latitude, _stops[0].longitude);
      });
      _mapController.move(
        LatLng(_stops[0].latitude, _stops[0].longitude),
        _mapController.camera.zoom,
      );
    }
  }

  void _resetStops() {
    for (var i = 0; i < _stops.length; i++) {
      _stops[i].status = i == 0 ? StopStatus.current : StopStatus.upcoming;
    }
    if (_stops.length > 1) {
      _stops[1].status = StopStatus.next;
    }
  }

  void _onStopSelected(Stop stop) {
    final index = _stops.indexWhere((s) => s.id == stop.id);
    if (index != -1) {
      setState(() {
        _currentStopIndex = index;
        _currentLocation = LatLng(stop.latitude, stop.longitude);

        // Update map center
        _mapController.move(
          LatLng(stop.latitude, stop.longitude),
          _mapController.camera.zoom,
        );

        // Update stop statuses
        for (var i = 0; i < _stops.length; i++) {
          if (i < index) {
            _stops[i].status = StopStatus.completed;
          } else if (i == index) {
            _stops[i].status = StopStatus.current;
          } else if (i == index + 1) {
            _stops[i].status = StopStatus.next;
          } else {
            _stops[i].status = StopStatus.upcoming;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Jaipur School Bus Tracker'),
        backgroundColor: Colors.blue[700],
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadMockData),
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: _getInitialLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          BusMapWidget(
            stops: _stops,
            currentLocation: _currentLocation,
            mapController: _mapController, // This is important
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: StopListWidget(
              stops: _stops,
              onStopSelected: _onStopSelected,
            ),
          ),
          Positioned(
            top: 50,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  onPressed: _isTripActive ? _pauseTrip : _startTrip,
                  child: Icon(_isTripActive ? Icons.pause : Icons.play_arrow),
                  mini: true,
                ),
                SizedBox(height: 8),
                if (_isTripActive)
                  FloatingActionButton(
                    onPressed: _endTrip,
                    child: Icon(Icons.stop),
                    mini: true,
                    backgroundColor: Colors.red,
                  ),
              ],
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.directions_bus, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Trip in Progress',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 60,
            left: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue[700],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Jaipur, Rajasthan',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Lat: ${_currentLocation.latitude.toStringAsFixed(4)}\n'
                'Lng: ${_currentLocation.longitude.toStringAsFixed(4)}',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
