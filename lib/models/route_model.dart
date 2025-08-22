import 'stop_model.dart';

class Route {
  final String id;
  final String name;
  final List<Stop> stops;
  final String busId;

  Route({
    required this.id,
    required this.name,
    required this.stops,
    required this.busId,
  });
}