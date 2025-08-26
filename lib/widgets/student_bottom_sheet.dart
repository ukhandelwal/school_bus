import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
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
        // 80% by default, can collapse to ~70% and expand up to 90%
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
          'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lon');
      final res = await http.get(url, headers: {
        'User-Agent': 'school_bus_tracker/1.0'
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

  @override
  Widget build(BuildContext context) {
    final stop = widget.stop;
    final accent = Colors.blue;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12)],
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // drag handle
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          // Header: Stop name + status + coords
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _Header(stop: stop, accent: accent),
          ),
          const SizedBox(height: 12),

          // Map card with actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _MapCard(
              stop: stop,
              accent: accent,
            ),
          ),
          const SizedBox(height: 12),

          // Address block
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _AddressBlock(
              address: _address,
              loading: _loadingAddr,
              lat: stop.latitude,
              lon: stop.longitude,
              accent: accent,
            ),
          ),
          const SizedBox(height: 8),

          // Students section (expand)
          Expanded(
            child: _StudentsSection(
              students: stop.students,
              count: stop.studentCount > 0 ? stop.studentCount : stop.students.length,
              accent: accent,
            ),
          ),
          const SizedBox(height: 8),
        ],
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
              Text(stop.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  )),
              const SizedBox(height: 6),
              Row(
                children: [
                  _pill(
                    label: _statusText(status),
                    color: statusColor,
                  ),
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

  const _MapCard({required this.stop, required this.accent});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Material(
        elevation: 1.5,
        child: Column(
          children: [
            SizedBox(
              height: 240, // larger map viewport
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
                    onTap: () {
                      final text =
                          '${stop.latitude.toStringAsFixed(6)}, ${stop.longitude.toStringAsFixed(6)}';
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coordinates copied')),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _chipButton(
                    icon: Icons.navigation_rounded,
                    label: 'Navigate',
                    onTap: () {
                      final lat = stop.latitude;
                      final lon = stop.longitude;
                      // Open in external map app via geo: or Google Maps URL
                      // Use url_launcher if desired; keeping UI code only here.
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Open maps via url_launcher in app')),
                      );
                    },
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

  Widget _chipButton({required IconData icon, required String label, required VoidCallback onTap}) {
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

  const _AddressBlock({
    required this.address,
    required this.loading,
    required this.lat,
    required this.lon,
    required this.accent,
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
                        onTap: () {
                          final txt = address ??
                              '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}';
                          Clipboard.setData(ClipboardData(text: txt));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Address copied')),
                          );
                        },
                      ),
                      _addressAction(
                        icon: Icons.map_rounded,
                        label: 'Open in Maps',
                        onTap: () {
                          // Add url_launcher integration to open maps with lat/lon.
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Open maps via url_launcher in app')),
                          );
                        },
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
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            const SizedBox(height: 8),
            const Expanded(
              child: Center(child: Text('No students assigned to this stop')),
            ),
          ],
        ),
      );
    }

    // Top avatars grid (first 6), then list
    final top = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: header,
    );

    final avatarGrid = Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: students.take(6).map((s) {
          return _avatar(s, accent);
        }).toList(),
      ),
    );

    final list = Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: students.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final s = students[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: accent.withOpacity(0.12),
              child: Text(
                _initials(s.name),
                style: TextStyle(color: accent, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Student'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Optionally open student detail page or actions
            },
          );
        },
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        top,
        avatarGrid,
        // list,
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
    final parts =
    name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.toUpperCase()}${parts.last.toUpperCase()}';
  }
}
