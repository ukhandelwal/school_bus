import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/stop_model.dart';
import '../models/student_model.dart';

class BusMapWidget extends StatefulWidget {
  final List<Stop> stops;
  final LatLng currentLocation;
  final List<LatLng> routePoints;
  final bool isLoadingRoute;
  final MapController mapController;
  final double headingDeg; // 0..360

  const BusMapWidget({
    super.key,
    required this.stops,
    required this.currentLocation,
    required this.routePoints,
    required this.isLoadingRoute,
    required this.mapController,
    this.headingDeg = 0.0,
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
            if (widget.routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: widget.routePoints,
                    color: Colors.blueAccent.withOpacity(0.8),
                    strokeWidth: 5.0,
                  ),
                ],
              ),
            MarkerLayer(markers: _buildStopMarkers() + _buildBusMarker()),
          ],
        ),

        // Satellite toggle
        Positioned(
          right: 16,
          bottom: 170,
          child: _mapFloating(
            onTap: () => setState(() => _satellite = !_satellite),
            icon: _satellite ? Icons.satellite_alt : Icons.map,
            label: _satellite ? 'Satellite' : 'Default',
          ),
        ),

     /*   if (widget.isLoadingRoute)
          const Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),*/
      ],
    );
  }

  List<Marker> _buildStopMarkers() {
    return widget.stops.map((stop) {
      final color = _statusColor(stop.status);
      final iconData = _statusIcon(stop.status);

      return Marker(
        point: LatLng(stop.latitude, stop.longitude),
        width: 230,
        height: 160, // increased to avoid overflow
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                shape: BoxShape.circle,
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
              ),
              padding: const EdgeInsets.all(6),
              child: Icon(iconData, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: _StopInfoCard(stop: stop, color: color),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Marker> _buildBusMarker() {
    return [
      Marker(
        point: widget.currentLocation,
        width: 80,
        height: 80,
        child: _RotatingBus(
          headingDeg: widget.headingDeg,
          size: 64,
        ),
      ),
    ];
  }

  Color _statusColor(StopStatus s) {
    switch (s) {
      case StopStatus.completed:
        return Colors.grey;
      case StopStatus.current:
        return Colors.orange;
      case StopStatus.next:
        return Colors.green;
      case StopStatus.upcoming:
        return Colors.blue;
    }
  }

  IconData _statusIcon(StopStatus s) {
    switch (s) {
      case StopStatus.completed:
        return Icons.check_circle;
      case StopStatus.current:
        return Icons.flag;
      case StopStatus.next:
      case StopStatus.upcoming:
        return Icons.location_on;
    }
  }

  Widget _mapFloating({required VoidCallback onTap, required IconData icon, required String label}) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _StopInfoCard extends StatelessWidget {
  final Stop stop;
  final Color color;
  const _StopInfoCard({required this.stop, required this.color});

  @override
  Widget build(BuildContext context) {
    final students = stop.students;
    final count = stop.studentCount > 0 ? stop.studentCount : students.length;

    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 210,
        maxHeight: 120,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            border: Border.all(color: color.withOpacity(0.5), width: 1),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title + count
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        stop.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _CountBadge(count: count, color: color),
                  ],
                ),
                const SizedBox(height: 6),
                // Avatars row (tight)
                SizedBox(
                  height: 30,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.zero,
                    itemCount: students.length.clamp(0, 4),
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final s = students[index];
                      return _StudentAvatar(student: s, ringColor: color, radius: 12);
                    },
                  ),
                ),
                const SizedBox(height: 6),
                // Names chips (tight)
                SizedBox(
                  height: 22,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.zero,
                    itemCount: students.length.clamp(0, 4),
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final s = students[index];
                      return _NameChip(name: s.name, color: color, fontSize: 10);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final Color color;
  const _CountBadge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StudentAvatar extends StatelessWidget {
  final Student student;
  final Color ringColor;
  final double radius;

  const _StudentAvatar({
    required this.student,
    required this.ringColor,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final String? img = student.imageUrl;
    final String initials = _initials(student.name);

    return Container(
      padding: const EdgeInsets.all(1.8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: 1.4),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: img != null ? NetworkImage(img) : null,
        child: img == null
            ? Text(
          initials,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        )
            : null,
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    final first = parts.first.substring(0, 1).toUpperCase();
    final last = parts.last.substring(0, 1).toUpperCase();
    return '$first$last';
  }
}

class _NameChip extends StatelessWidget {
  final String name;
  final Color color;
  final double fontSize;

  const _NameChip({
    required this.name,
    required this.color,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text(
        name,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RotatingBus extends StatelessWidget {
  final double headingDeg; // 0..360 (0 = North)
  final double size;

  const _RotatingBus({required this.headingDeg, this.size = 60});

  @override
  Widget build(BuildContext context) {
    // Adjust if your asset faces right/left/down by default
    const double assetFacingOffsetDeg = 0;
    final double radians = (headingDeg + assetFacingOffsetDeg) * (pi / 180.0);

    return Container(
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // soft shadow
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          Transform.rotate(
            angle: radians,
            child: Image.asset(
              'asset/images/bus.png',
              width: size,
              height: size,
              filterQuality: FilterQuality.high,
            ),
          ),
        ],
      ),
    );
  }
}
