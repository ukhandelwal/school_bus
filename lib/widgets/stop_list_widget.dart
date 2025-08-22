import 'package:flutter/material.dart';
import '../models/stop_model.dart';

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
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Bus Stops',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: stops.length,
              itemBuilder: (context, index) {
                final stop = stops[index];
                return _buildStopCard(stop);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopCard(Stop stop) {
    Color statusColor;
    String statusText;
    switch (stop.status) {
      case StopStatus.completed:
        statusColor = Colors.grey;
        statusText = 'Completed';
        break;
      case StopStatus.current:
        statusColor = Colors.orange;
        statusText = 'Current';
        break;
      case StopStatus.next:
        statusColor = Colors.green;
        statusText = 'Next';
        break;
      case StopStatus.upcoming:
        statusColor = Colors.blue;
        statusText = 'Upcoming';
        break;
    }

    return GestureDetector(
      onTap: () => onStopSelected(stop),
      child: Container(
        width: 150,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stop.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              statusText,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('Students: ${stop.studentCount}'),
          ],
        ),
      ),
    );
  }
}
