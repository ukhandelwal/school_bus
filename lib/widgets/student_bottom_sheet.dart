import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/trip_controller.dart';
import '../models/stop_model.dart';
import '../models/student_model.dart';

class StudentBottomSheet extends StatefulWidget {
  final Stop stop;

  const StudentBottomSheet({super.key, required this.stop});

  static Future<void> show(BuildContext context, Stop stop) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        minChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (context, controller) => StudentBottomSheet(stop: stop),
      ),
    );
  }

  @override
  State<StudentBottomSheet> createState() => _StudentBottomSheetState();
}

class _StudentBottomSheetState extends State<StudentBottomSheet> {
  String? _address;
  bool _loadingAddr = true;

  @override
  void initState() {
    super.initState();
    _reverseGeocode();
  }

  Future<void> _reverseGeocode() async {
    setState(() => _loadingAddr = true);
    try {
      final lat = widget.stop.latitude;
      final lon = widget.stop.longitude;
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lon',
      );
      final res = await http.get(url, headers: {
        'User-Agent': 'school_bus_tracker/1.0',
      });
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final disp = data['display_name'];
        setState(() => _address = disp is String ? disp : null);
      } else {
        setState(() => _address = null);
      }
    } catch (_) {
      setState(() => _address = null);
    } finally {
      if (mounted) setState(() => _loadingAddr = false);
    }
  }

  // Open Google Maps at coordinates
  Future<void> _openInMaps(double lat, double lon) async {
    Get.back();
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) throw 'launch failed';
    } catch (_) {
      // fallback: try maps app scheme if available
      final alt = Uri.parse('geo:$lat,$lon?q=$lat,$lon');
      await launchUrl(alt, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _navigateTo(double lat, double lon) async {
    Get.back();
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&travelmode=driving&dir_action=navigate',
    );
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) throw 'launch failed';
    } catch (_) {
      final alt = Uri.parse('google.navigation:q=$lat,$lon&mode=d');
      await launchUrl(alt, mode: LaunchMode.externalApplication);
    }
  }
  //
  // // Open Google Maps directions and start the in-app trip
  // Future<void> _navigateTo(double lat, double lon) async {
  //   final url =
  //   Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&travelmode=driving');
  //   if (await canLaunchUrl(url)) {
  //     await launchUrl(url, mode: LaunchMode.externalApplication);
  //   }
  //   final controller = Get.isRegistered<TripController>() ? Get.find<TripController>() : null;
  //   controller?.startTrip();
  // }

  @override
  Widget build(BuildContext context) {
    final stop = widget.stop;
    final accent = Colors.blue;

    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12)],
        ),
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverToBoxAdapter(
              child: Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Header
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(child: _Header(stop: stop, accent: accent)),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Map card
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: _MapCard(
                  stop: stop,
                  accent: accent,
                  onCopyCoords: () {
                    Get.back();
                    final text =
                        '${stop.latitude.toStringAsFixed(6)}, ${stop.longitude.toStringAsFixed(6)}';
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coordinates copied')),
                    );
                  },
                  onNavigate: () => _navigateTo(stop.latitude, stop.longitude),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Address block
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: _AddressBlock(
                  address: _address,
                  loading: _loadingAddr,
                  lat: stop.latitude,
                  lon: stop.longitude,
                  accent: accent,
                  onOpenMaps: () => _openInMaps(stop.latitude, stop.longitude),
                  onCopy: () {
                    final txt = _address ??
                        '${stop.latitude.toStringAsFixed(6)}, ${stop.longitude.toStringAsFixed(6)}';
                    Clipboard.setData(ClipboardData(text: txt));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Address copied')),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Students section
            SliverPadding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              sliver: SliverToBoxAdapter(
                child: _StudentsSection(
                  students: stop.students,
                  count:
                  stop.studentCount > 0 ? stop.studentCount : stop.students.length,
                  accent: accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Stop stop;
  final Color accent;

  const _Header({required this.stop, required this.accent});

  @override
  Widget build(BuildContext context) {
    final status = stop.status;
    final statusColor = _statusColor(status);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(10),
          child: Icon(Icons.location_on, color: accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stop.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _pill(label: _statusText(status), color: statusColor),
                  const SizedBox(width: 8),
                  _pill(
                    label:
                    'Lat ${stop.latitude.toStringAsFixed(5)} • Lng ${stop.longitude.toStringAsFixed(5)}',
                    color: Colors.black54,
                    light: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pill({required String label, required Color color, bool light = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: light ? color.withOpacity(0.1) : color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: light ? color : Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  static String _statusText(StopStatus s) {
    switch (s) {
      case StopStatus.completed:
        return 'Completed';
      case StopStatus.current:
        return 'Current';
      case StopStatus.next:
        return 'Next';
      case StopStatus.upcoming:
        return 'Upcoming';
    }
  }

  static Color _statusColor(StopStatus s) {
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
}

class _MapCard extends StatelessWidget {
  final Stop stop;
  final Color accent;
  final VoidCallback onCopyCoords;
  final VoidCallback onNavigate;

  const _MapCard({
    required this.stop,
    required this.accent,
    required this.onCopyCoords,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Material(
        elevation: 1.5,
        child: Column(
          children: [
            SizedBox(
              height: 240,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(stop.latitude, stop.longitude),
                  initialZoom: 16,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.school_bus_tracker',
                  ),
                  MarkerLayer(markers: [
                    Marker(
                      width: 48,
                      height: 48,
                      point: LatLng(stop.latitude, stop.longitude),
                      child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                    ),
                  ]),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              color: Colors.grey.shade50,
              child: Row(
                children: [
                  _chipButton(
                    icon: Icons.copy_rounded,
                    label: 'Copy coords',
                    onTap: onCopyCoords,
                  ),
                  const SizedBox(width: 8),
                  _chipButton(
                    icon: Icons.navigation_rounded,
                    label: 'Navigate',
                    onTap: onNavigate,
                  ),
                  const Spacer(),
                  Row(
                    children: const [
                      Icon(Icons.timer, size: 18),
                      SizedBox(width: 4),
                      Text('ETA —'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipButton(
      {required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _AddressBlock extends StatelessWidget {
  final String? address;
  final bool loading;
  final double lat;
  final double lon;
  final Color accent;
  final VoidCallback onOpenMaps;
  final VoidCallback onCopy;

  const _AddressBlock({
    required this.address,
    required this.loading,
    required this.lat,
    required this.lon,
    required this.accent,
    required this.onOpenMaps,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0.5,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.place, color: accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Address',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 6),
                  if (loading)
                    const Text('Fetching address…',
                        style: TextStyle(fontStyle: FontStyle.italic))
                  else
                    Text(
                      address ?? 'Address not available',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _addressAction(
                        icon: Icons.copy_rounded,
                        label: 'Copy',
                        onTap: onCopy,
                      ),
                      _addressAction(
                        icon: Icons.map_rounded,
                        label: 'Open in Maps',
                        onTap: onOpenMaps,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addressAction(
      {required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _StudentsSection extends StatelessWidget {
  final List<Student> students;
  final int count;
  final Color accent;

  const _StudentsSection({
    required this.students,
    required this.count,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final header = Row(
      children: [
        Icon(Icons.group, color: accent),
        const SizedBox(width: 8),
        Text('Students ($count)',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
      ],
    );

    if (students.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 8),
          const SizedBox(
            height: 80,
            child: Center(child: Text('No students assigned to this stop')),
          ),
        ],
      );
    }

    final avatarGrid = Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: students.take(6).map((s) => _avatar(s, accent)).toList(),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        avatarGrid,
        // Add list if you want a detailed scrollable list below avatars:
        // SizedBox(
        //   height: 220,
        //   child: ListView.separated(
        //     itemCount: students.length,
        //     separatorBuilder: (_, __) => const Divider(height: 1),
        //     itemBuilder: (_, i) {
        //       final s = students[i];
        //       return ListTile(
        //         leading: CircleAvatar(
        //           backgroundColor: accent.withOpacity(0.12),
        //           child: Text(
        //             _initials(s.name),
        //             style: TextStyle(color: accent, fontWeight: FontWeight.bold),
        //           ),
        //         ),
        //         title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        //         subtitle: const Text('Student'),
        //         trailing: const Icon(Icons.chevron_right),
        //       );
        //     },
        //   ),
        // ),
      ],
    );
  }

  Widget _avatar(Student s, Color accent) {
    final initials = _initials(s.name);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(1.8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: accent, width: 1.4),
          ),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: s.imageUrl != null ? NetworkImage(s.imageUrl!) : null,
            child: s.imageUrl == null
                ? Text(
              initials,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            )
                : null,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 72,
          child: Text(
            s.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0].toUpperCase()}${parts.last[0].toUpperCase()}';
  }
}
