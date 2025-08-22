import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/stop_model.dart';
import 'dart:async';
import '../services/routing_service.dart'; // Add this import

class BusMapWidget extends StatefulWidget {
  final List<Stop> stops;
  final LatLng currentLocation;
  final MapController mapController;

  const BusMapWidget({
    Key? key,
    required this.stops,
    required this.currentLocation,
    required this.mapController,
  }) : super(key: key);

  @override
  _BusMapWidgetState createState() => _BusMapWidgetState();
}

class _BusMapWidgetState extends State<BusMapWidget> {
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;
  bool _satellite = false;

  @override
  void initState() {
    super.initState();
    _fetchRoute();
  }

  @override
  void didUpdateWidget(covariant BusMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.currentLocation != widget.currentLocation) {
      // Follow bus
      widget.mapController.move(
        widget.currentLocation,
        widget.mapController.camera.zoom,
      );
      // Recompute route from new current location
      _fetchRoute();
    }

    if (oldWidget.stops != widget.stops) {
      _fetchRoute();
    }
  }


  // bus_map_widget.dart
  Future<void> _fetchRoute() async {
    // Need at least one stop remaining to route to
    final remainingStops = widget.stops
        .where(
          (s) =>
              s.status == StopStatus.current ||
              s.status == StopStatus.next ||
              s.status == StopStatus.upcoming,
        )
        .toList();

    if (remainingStops.length < 1) {
      setState(() {
        _routePoints = [];
      });
      return;
    }

    setState(() => _isLoadingRoute = true);

    // Start from current device location, then go through remaining stops
    final waypoints = <LatLng>[
      widget.currentLocation,
      ...remainingStops.map((s) => LatLng(s.latitude, s.longitude)),
    ];

    final routeCoordinates = await RoutingService.getRouteCoordinates(
      waypoints,
    );
    setState(() {
      _routePoints = routeCoordinates;
      _isLoadingRoute = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: widget.mapController,
          options: MapOptions(
            initialCenter: widget.currentLocation,
            initialZoom: 15.0,
          ),
          children: [
            TileLayer(
              urlTemplate: _satellite == true
                  ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                  : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.school_bus_tracker',
            ),
            MarkerLayer(markers: _buildStopMarkers() + _buildBusMarker()),
            if (_routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    color: Colors.blue.withOpacity(0.7),
                    strokeWidth: 4.0,
                  ),
                ],
              ),
          ],
        ),

        Positioned(
          top: 100,
          right: 12,
          child: FloatingActionButton(
            heroTag: 'map_type_toggle',
            mini: true,
            onPressed: () => setState(() => _satellite = !_satellite),
            child: Icon(_satellite ? Icons.satellite_alt : Icons.map),
          ),
        ),
        if (_isLoadingRoute) Center(child: CircularProgressIndicator()),
      ],
    );
  }

  // Keep your existing _buildStopMarkers and _buildBusMarker methods
  List<Marker> _buildStopMarkers() {
    return widget.stops.map((stop) {
      Color markerColor;
      IconData markerIcon;

      switch (stop.status) {
        case StopStatus.completed:
          markerColor = Colors.grey;
          markerIcon = Icons.location_on;
          break;
        case StopStatus.current:
          markerColor = Colors.orange;
          markerIcon = Icons.location_on;
          break;
        case StopStatus.next:
          markerColor = Colors.green;
          markerIcon = Icons.location_on;
          break;
        case StopStatus.upcoming:
          markerColor = Colors.blue;
          markerIcon = Icons.location_on;
          break;
      }

      return Marker(
        point: LatLng(stop.latitude, stop.longitude),
        width: 50,
        height: 50,
        child: Column(
          children: [
            Icon(markerIcon, color: markerColor, size: 30),
            Text(stop.name, style: TextStyle(fontSize: 10, color: markerColor)),
          ],
        ),
      );
    }).toList();
  }

  List<Marker> _buildBusMarker() {
    return [
      Marker(
        point: widget.currentLocation,
        width: 60,
        height: 60,
        child: Icon(Icons.directions_bus, color: Colors.red, size: 40),
      ),
    ];
  }
}
