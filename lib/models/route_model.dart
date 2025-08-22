import 'stop_model.dart';

class RouteModel {
  final String id;
  final String name;
  final List<Stop> stops;
  final String busId;

  RouteModel({
    required this.id,
    required this.name,
    required this.stops,
    required this.busId,
  });
}
