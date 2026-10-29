enum TaskPriority { low, medium, high }

class TaskItem {
  final int? id;
  final String title;
  final TaskPriority priority;
  final DateTime? dueDate;
  final bool isDone;

  const TaskItem({
    this.id,
    required this.title,
    this.priority = TaskPriority.medium,
    this.dueDate,
    this.isDone = false,
  });

  Map<String, Object?> toMap() {
    return {
      'title': title,
      'priority': priority.index,
      'due_date': dueDate?.toIso8601String(),
      'is_done': isDone ? 1 : 0,
    };
  }

  factory TaskItem.fromMap(Map<String, Object?> map) {
    final due = map['due_date'] as String?;
    return TaskItem(
      id: map['id'] as int,
      title: map['title'] as String,
      priority: TaskPriority.values[map['priority'] as int],
      dueDate: due == null ? null : DateTime.parse(due),
      isDone: (map['is_done'] as int) == 1,
    );
  }
}
