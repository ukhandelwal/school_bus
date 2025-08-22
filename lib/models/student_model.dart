class Student {
  final String id;
  final String name;
  final String? imageUrl; // optional; show initials if null

  Student({
    required this.id,
    required this.name,
    this.imageUrl,
  });
}
