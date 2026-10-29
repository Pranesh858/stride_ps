class Habit {
  final int? id;
  final String name;
  final DateTime createdAt;

  const Habit({this.id, required this.name, required this.createdAt});

  Map<String, Object?> toMap() {
    return {'name': name, 'created_at': createdAt.toIso8601String()};
  }

  factory Habit.fromMap(Map<String, Object?> map) {
    return Habit(
      id: map['id'] as int,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// Turns a date into a text key like "2026-10-21".
String dayKey(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}

/// Counts consecutive checked days, ending today (or yesterday).
int currentStreak(Set<String> days) {
  final now = DateTime.now();
  var d = DateTime(now.year, now.month, now.day);

  // If today isn't checked yet, the streak is still alive until midnight.
  if (!days.contains(dayKey(d))) {
    d = DateTime(d.year, d.month, d.day - 1);
  }

  int count = 0;
  while (days.contains(dayKey(d))) {
    count++;
    d = DateTime(d.year, d.month, d.day - 1);
  }
  return count;
}
