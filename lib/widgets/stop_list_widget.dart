import 'package:flutter/material.dart';
import '../models/stop_model.dart';
import '../widgets/student_bottom_sheet.dart';

class StopListWidget extends StatelessWidget {
  final List<Stop> stops;
  final Function(Stop) onStopSelected;

  const StopListWidget({
    super.key,
    required this.stops,
    required this.onStopSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: stops.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, index) => _StopChip(
        stop: stops[index],
        onTap: () {
          final stop = stops[index];
          onStopSelected(stop); // keep existing flow
          StudentBottomSheet.show(context, stop); // new bottom sheet
        },
      ),
    );
  }
}

class _StopChip extends StatelessWidget {
  final Stop stop;
  final VoidCallback onTap;
  const _StopChip({required this.stop, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(stop.status);
    final icon = _statusIcon(stop.status);
    final border = _statusBorder(stop.status);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 1.6),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stop.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w700, color: color)),
                  const SizedBox(height: 4),
                  Text(
                    _statusText(stop.status),
                    style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text('Students: ${stop.studentCount}', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusText(StopStatus s) {
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

  IconData _statusIcon(StopStatus s) {
    switch (s) {
      case StopStatus.completed:
        return Icons.check_circle;
      case StopStatus.current:
        return Icons.flag;
      case StopStatus.next:
        return Icons.navigate_next;
      case StopStatus.upcoming:
        return Icons.location_on;
    }
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

  Color _statusBorder(StopStatus s) {
    switch (s) {
      case StopStatus.completed:
        return Colors.grey.shade400;
      case StopStatus.current:
        return Colors.orange.shade400;
      case StopStatus.next:
        return Colors.green.shade400;
      case StopStatus.upcoming:
        return Colors.blue.shade400;
    }
  }
}
