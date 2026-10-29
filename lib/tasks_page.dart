import 'package:flutter/material.dart';

import 'add_task_sheet.dart';
import 'database/app_database.dart';
import 'models/task_item.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  List<TaskItem> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await AppDatabase.instance.getTasks();
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
    });
  }

  Future<void> _openAddSheet() async {
    final TaskItem? newTask = await showModalBottomSheet<TaskItem>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddTaskSheet(),
    );

    if (newTask != null) {
      await AppDatabase.instance.insertTask(newTask);
      await _loadTasks();
    }
  }

  Future<void> _toggleDone(TaskItem task, bool done) async {
    await AppDatabase.instance.setTaskDone(task.id!, done);
    await _loadTasks();
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  String _dueLabel(DateTime due) {
    final diff = due.difference(_today()).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff < 0) return 'Overdue by ${-diff}d';
    return '${due.day}/${due.month}/${due.year}';
  }

  Color _priorityColor(TaskPriority p) {
    return switch (p) {
      TaskPriority.high => Colors.red,
      TaskPriority.medium => Colors.orange,
      TaskPriority.low => Colors.blueGrey,
    };
  }

  List<TaskItem> get _pending {
    final list = _tasks.where((t) => !t.isDone).toList();
    list.sort((a, b) {
      if (a.dueDate == null && b.dueDate == null) {
        return b.priority.index.compareTo(a.priority.index);
      }
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      final byDate = a.dueDate!.compareTo(b.dueDate!);
      if (byDate != 0) return byDate;
      return b.priority.index.compareTo(a.priority.index);
    });
    return list;
  }

  Widget _buildTile(TaskItem t) {
    final overdue =
        !t.isDone && t.dueDate != null && t.dueDate!.isBefore(_today());

    return Dismissible(
      key: ValueKey(t.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        setState(() {
          _tasks.removeWhere((x) => x.id == t.id);
        });
        await AppDatabase.instance.deleteTask(t.id!);
      },
      child: ListTile(
        leading: Checkbox(
          value: t.isDone,
          onChanged: (v) => _toggleDone(t, v ?? false),
        ),
        title: Text(
          t.title,
          style: t.isDone
              ? const TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                )
              : null,
        ),
        subtitle: t.dueDate == null
            ? null
            : Text(
                _dueLabel(t.dueDate!),
                style: TextStyle(color: overdue ? Colors.red : null),
              ),
        trailing: Icon(Icons.flag, color: _priorityColor(t.priority)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _pending;
    final done = _tasks.where((t) => t.isDone).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSheet,
        child: const Icon(Icons.add),
      ),
      body: _tasks.isEmpty
          ? const Center(child: Text('No tasks yet. Tap + to add one.'))
          : ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    pending.isEmpty
                        ? 'All done. Nice work.'
                        : '${pending.length} to do',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                for (final t in pending) _buildTile(t),
                if (done.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      'Done (${done.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  for (final t in done) _buildTile(t),
                ],
              ],
            ),
    );
  }
}
