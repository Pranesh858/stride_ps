import 'package:flutter/material.dart';

import 'database/app_database.dart';
import 'models/habit.dart';

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key});

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  List<Habit> _habits = [];
  Map<int, Set<String>> _checkins = {};

  static const List<String> _weekdayLetters = [
    'M',
    'T',
    'W',
    'T',
    'F',
    'S',
    'S',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final habits = await AppDatabase.instance.getHabits();
    final checkins = await AppDatabase.instance.getCheckins();
    if (!mounted) return;
    setState(() {
      _habits = habits;
      _checkins = checkins;
    });
  }

  Future<void> _addHabit() async {
    final String? name = await showDialog<String>(
      context: context,
      builder: (context) => const _AddHabitDialog(),
    );
    if (name != null) {
      await AppDatabase.instance.insertHabit(
        Habit(name: name, createdAt: DateTime.now()),
      );
      await _load();
    }
  }

  Future<void> _toggle(Habit habit, DateTime day) async {
    final key = dayKey(day);
    final isDone = _checkins[habit.id]?.contains(key) ?? false;
    await AppDatabase.instance.setCheckin(habit.id!, key, !isDone);
    await _load();
  }

  Widget _buildCard(Habit habit) {
    final colors = Theme.of(context).colorScheme;
    final days = _checkins[habit.id] ?? <String>{};
    final streak = currentStreak(days);
    final now = DateTime.now();
    final doneToday = days.contains(dayKey(now));
    final week = [
      for (int i = 6; i >= 0; i--) DateTime(now.year, now.month, now.day - i),
    ];

    return Dismissible(
      key: ValueKey(habit.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete "${habit.name}"?'),
            content: const Text('Its check-in history will be deleted too.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        return result ?? false;
      },
      onDismissed: (_) async {
        setState(() {
          _habits.removeWhere((x) => x.id == habit.id);
        });
        await AppDatabase.instance.deleteHabit(habit.id!);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department,
                              size: 18,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              streak == 1
                                  ? '1 day streak'
                                  : '$streak day streak',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  doneToday
                      ? IconButton.filled(
                          onPressed: () => _toggle(habit, now),
                          icon: const Icon(Icons.check),
                        )
                      : IconButton.outlined(
                          onPressed: () => _toggle(habit, now),
                          icon: const Icon(Icons.check),
                        ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final d in week)
                    GestureDetector(
                      onTap: () => _toggle(habit, d),
                      child: Column(
                        children: [
                          Text(
                            _weekdayLetters[d.weekday - 1],
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          const SizedBox(height: 4),
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: days.contains(dayKey(d))
                                ? colors.primary
                                : colors.surfaceContainerHighest,
                            child: days.contains(dayKey(d))
                                ? Icon(
                                    Icons.check,
                                    size: 16,
                                    color: colors.onPrimary,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayKey = dayKey(DateTime.now());
    final doneToday = _habits
        .where((h) => _checkins[h.id]?.contains(todayKey) ?? false)
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Habits')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHabit,
        child: const Icon(Icons.add),
      ),
      body: _habits.isEmpty
          ? const Center(child: Text('No habits yet. Tap + to start one.'))
          : ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    '$doneToday of ${_habits.length} done today',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                for (final h in _habits) _buildCard(h),
              ],
            ),
    );
  }
}

class _AddHabitDialog extends StatefulWidget {
  const _AddHabitDialog();

  @override
  State<_AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends State<_AddHabitDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New habit'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(
          hintText: 'e.g. Drink 2L water',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
