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
      appBar: AppBar(
        title: const Text('Jaipur School Bus Tracker'),
        backgroundColor: Colors.blue[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadMockData,
          ),
        ],
      ),
      body: Stack(
        children: [
          Obx(() {
            return BusMapWidget(
              mapController: mapController,
              stops: controller.stops,
              currentLocation: controller.currentLocation.value,
              routePoints: controller.routePoints,
              isLoadingRoute: controller.isLoadingRoute.value,
            );
          }),

          // Stop list
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: StopListWidget(
              stops: controller.stops,
              onStopSelected: controller.onStopSelected,
            ),
          ),

          // Trip controls
          Positioned(
            top: 50,
            right: 16,
            child: Obx(() {
              final active = controller.isTripActive.value;
              return Column(
                children: [
                  FloatingActionButton(
                    onPressed: active
                        ? controller.pauseTrip
                        : controller.startTrip,
                    child: Icon(active ? Icons.pause : Icons.play_arrow),
                    mini: true,
                  ),
                  const SizedBox(height: 8),
                  if (active)
                    FloatingActionButton(
                      onPressed: controller.endTrip,
                      child: const Icon(Icons.stop),
                      mini: true,
                      backgroundColor: Colors.red,
                    ),
                ],
              );
            }),
          ),

          // Trip in progress pill
          Positioned(
            top: 16,
            left: 16,
            child: Obx(() {
              if (!controller.isTripActive.value) {
                return const SizedBox.shrink();
              }
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
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
              );
            }),
          ),

          // Coordinate pill
          Positioned(
            top: 16,
            right: 16,
            child: Obx(() {
              final LatLng loc = controller.currentLocation.value;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Lat: ${loc.latitude.toStringAsFixed(4)}\nLng: ${loc.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
