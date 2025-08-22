import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/stop_model.dart';
import '../services/location_service.dart';

class BusMapWidget extends StatefulWidget {
  final List<Stop> stops;
  final LatLng currentLocation;

  const BusMapWidget({
    Key? key,
    required this.stops,
    required this.currentLocation,
  }) : super(key: key);

  @override
  _BusMapWidgetState createState() => _BusMapWidgetState();
}

class _BusMapWidgetState extends State<BusMapWidget> {
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    //
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: widget.currentLocation, // Changed from 'center' to 'initialCenter'
        initialZoom: 15.0, // Also changed from 'zoom' to 'initialZoom'
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.schoolbus.school_bus',
        ),
        MarkerLayer(markers: _buildStopMarkers() + _buildBusMarker()),
        PolylineLayer(polylines: _buildRoutePolyline()),
      ],
    );
  }

  List<Marker> _buildStopMarkers() {
    return widget.stops.map((stop) {
      Color markerColor;
      switch (stop.status) {
        case StopStatus.completed:
          markerColor = Colors.grey;
          break;
        case StopStatus.current:
          markerColor = Colors.orange;
          break;
        case StopStatus.next:
          markerColor = Colors.green;
          break;
        case StopStatus.upcoming:
          markerColor = Colors.blue;
          break;
      }

      return Marker(
        point: LatLng(stop.latitude, stop.longitude),
        width: 40,
        height: 40,
        child: Container(
          child: Column(
            children: [
              Icon(Icons.location_on, color: markerColor, size: 30),
              Text(stop.name, style: TextStyle(fontSize: 10)),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Marker> _buildBusMarker() {
    return [
      Marker(
        point: widget.currentLocation,
        width: 50,
        height: 50, child: Icon(Icons.directions_bus, color: Colors.red, size: 40),

      ),
    ];
  }

  List<Polyline> _buildRoutePolyline() {
    if (widget.stops.length < 2) return [];

    final points = widget.stops
        .map((stop) => LatLng(stop.latitude, stop.longitude))
        .toList();

    return [Polyline(points: points, color: Colors.blue, strokeWidth: 4.0)];
  }
}
