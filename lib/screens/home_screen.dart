import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../controllers/trip_controller.dart';
import '../widgets/bus_map_widget.dart';
import '../widgets/stop_list_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TripController controller = Get.put(TripController());
  final MapController mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Obx(() {
            return BusMapWidget(
              mapController: mapController,
              stops: controller.stops,
              currentLocation: controller.currentLocation.value,
              routePoints: controller.routePoints,
              isLoadingRoute: controller.isLoadingRoute.value,
              headingDeg: controller.headingDeg.value, // NEW
            );
          }),

          // Top status banners
          _TopPills(),

          // Bottom Glass Panel with Stops & Controls
          Align(
            alignment: Alignment.bottomCenter,
            child: _BottomGlassPanel(controller: controller),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.blue,
      title: const Text(
        'School Bus Tracker',
        style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
      ),
      actions: [
        IconButton(
          onPressed: controller.loadMockData,
          icon: const Icon(Icons.refresh, color: Colors.white),
          tooltip: 'Reload',
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class _TopPills extends StatelessWidget {
  _TopPills({super.key});

  final TripController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 56, 12, 0),
        child: Row(
          children: [
            Obx(() {
              if (!controller.isTripActive.value) {
                return const SizedBox.shrink();
              }
              return _glassPill(
                child: Row(
                  children: const [
                    Icon(Icons.directions_bus, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Trip in Progress',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                color: Colors.green.withOpacity(0.65),
              );
            }),
            const SizedBox(width: 8),
            Obx(() {
              final LatLng loc = controller.currentLocation.value;
              return _glassPill(
                child: Text(
                  'Lat ${loc.latitude.toStringAsFixed(4)} | Lng ${loc.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                color: Colors.black54,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _glassPill({required Widget child, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

class _BottomGlassPanel extends StatelessWidget {
  final TripController controller;

  const _BottomGlassPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            spreadRadius: 1,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row
          Row(
            children: const [
              Icon(Icons.route, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Route & Stops',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stops scroller
          SizedBox(
            height: 110,
            child: StopListWidget(
              stops: controller.stops,
              onStopSelected: controller.onStopSelected,
            ),
          ),
          const SizedBox(height: 8),

          // Action row
          Obx(
            () => _ActionRow(
              isTripActive: controller.isTripActive.value,
              onStart: controller.startTrip,
              onPause: controller.pauseTrip,
              onResume: controller.resumeTrip,
              onStop: controller.endTrip,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final bool isTripActive;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  const _ActionRow({
    super.key,
    required this.isTripActive,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            if (!isTripActive)
              _roundedButton(
                color: Colors.green,
                icon: Icons.play_arrow,
                label: 'Start',
                onTap: onStart,
              ),
            if (isTripActive) ...[
              _roundedButton(
                color: Colors.orange,
                icon: Icons.pause,
                label: 'Pause',
                onTap: onPause,
              ),
              const SizedBox(width: 8),
              _roundedButton(
                color: Colors.blue,
                icon: Icons.play_circle_fill,
                label: 'Resume',
                onTap: onResume,
              ),
              const SizedBox(width: 8),
              _roundedButton(
                color: Colors.red,
                icon: Icons.stop,
                label: 'Stop',
                onTap: onStop,
              ),
            ],
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            _roundedButton(
              color: Colors.black87,
              icon: Icons.layers,
              label: 'Map',
              onTap: () => Get.find<TripController>().loadMockData(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _roundedButton({
    required Color color,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
