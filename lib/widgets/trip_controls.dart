import 'package:flutter/material.dart';

class TripControls extends StatelessWidget {
  final bool isTripActive;
  final Function() onStartTrip;
  final Function() onPauseTrip;
  final Function() onEndTrip;

  const TripControls({
    Key? key,
    required this.isTripActive,
    required this.onStartTrip,
    required this.onPauseTrip,
    required this.onEndTrip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50,
      right: 16,
      child: Column(
        children: [
          FloatingActionButton(
            onPressed: isTripActive ? onPauseTrip : onStartTrip,
            child: Icon(isTripActive ? Icons.pause : Icons.play_arrow),
            mini: true,
          ),
          SizedBox(height: 8),
          if (isTripActive)
            FloatingActionButton(
              onPressed: onEndTrip,
              child: Icon(Icons.stop),
              mini: true,
              backgroundColor: Colors.red,
            ),
        ],
      ),
    );
  }
}