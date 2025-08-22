class Bus {
  final String id;
  final String name;
  final int capacity;
  final String? currentRouteId;

  Bus({
    required this.id,
    required this.name,
    required this.capacity,
    this.currentRouteId,
  });
}