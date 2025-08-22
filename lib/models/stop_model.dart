class Stop {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int studentCount;
  StopStatus status;

  Stop({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.studentCount = 0,
    this.status = StopStatus.upcoming,
  });
}

enum StopStatus {
  completed,
  current,
  next,
  upcoming,
}