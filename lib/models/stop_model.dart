import 'student_model.dart';

class Stop {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int studentCount; // quick count
  final List<Student> students; // detailed list
  StopStatus status;

  Stop({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.studentCount = 0,
    this.students = const [],
    this.status = StopStatus.upcoming,
  });
}

enum StopStatus { completed, current, next, upcoming }
