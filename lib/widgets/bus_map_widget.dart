import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/stop_model.dart';

class BusMapWidget extends StatefulWidget {
  final List<Stop> stops;
  final LatLng currentLocation;
  final List<LatLng> routePoints;
  final bool isLoadingRoute;
  final MapController mapController;

  const BusMapWidget({
    super.key,
    required this.stops,
    required this.currentLocation,
    required this.routePoints,
    required this.isLoadingRoute,
    required this.mapController,
  });

  @override
  State<BusMapWidget> createState() => _BusMapWidgetState();
}

class _BusMapWidgetState extends State<BusMapWidget> {
  bool _satellite = false;
  Timer? _followDebounce;

  @override
  void dispose() {
    _followDebounce?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant BusMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLocation != widget.currentLocation) {
      // Follow bus with light debounce to avoid jitter
      _followDebounce?.cancel();
      _followDebounce = Timer(const Duration(milliseconds: 250), () {
        widget.mapController.move(
          widget.currentLocation,
          widget.mapController.camera.zoom,
        );
      });
    }
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
              urlTemplate: _satellite
                  ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                  : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.school_bus_tracker',
            ),
            MarkerLayer(markers: _buildStopMarkers() + _buildBusMarker()),
            if (widget.routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: widget.routePoints,
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
        if (widget.isLoadingRoute)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

  List<Marker> _buildStopMarkers() {
    return widget.stops.map((stop) {
      Color color;
      IconData icon = Icons.location_on;
      switch (stop.status) {
        case StopStatus.completed:
          color = Colors.grey;
          break;
        case StopStatus.current:
          color = Colors.orange;
          break;
        case StopStatus.next:
          color = Colors.green;
          break;
        case StopStatus.upcoming:
          color = Colors.blue;
          break;
      }
      return Marker(
        point: LatLng(stop.latitude, stop.longitude),
        width: 150,
        height: 150,
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            Text(stop.name, style: TextStyle(fontSize: 10, color: color)),
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
        child: const Icon(Icons.directions_bus, color: Colors.red, size: 40),
      ),
    ];
  }
}
