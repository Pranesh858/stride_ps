import 'package:flutter/material.dart';

import 'database/app_database.dart';
import 'models/habit.dart';
import 'models/task_item.dart';

class TodayPage extends StatefulWidget {
  final void Function(int tabIndex) onOpenTab;

  const TodayPage({super.key, required this.onOpenTab});

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  bool _loading = true;
  double _spentToday = 0;
  double _spentMonth = 0;
  List<TaskItem> _dueTasks = [];
  int _overdueCount = 0;
  List<Habit> _habits = [];
  Map<int, Set<String>> _checkins = {};

  static const List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = AppDatabase.instance;
    final entries = await db.getEntries();
    final tasks = await db.getTasks();
    final habits = await db.getHabits();
    final checkins = await db.getCheckins();
    if (!mounted) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    double spentToday = 0;
    double spentMonth = 0;
    for (final e in entries) {
      if (!e.isExpense) continue;
      if (e.date.year == now.year && e.date.month == now.month) {
        spentMonth += e.amount;
        if (e.date.day == now.day) {
          spentToday += e.amount;
        }
      }
    }

    final due = tasks
        .where(
          (t) => !t.isDone && t.dueDate != null && !t.dueDate!.isAfter(today),
        )
        .toList();
    due.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    final overdue = due.where((t) => t.dueDate!.isBefore(today)).length;

    setState(() {
      _spentToday = spentToday;
      _spentMonth = spentMonth;
      _dueTasks = due;
      _overdueCount = overdue;
      _habits = habits;
      _checkins = checkins;
      _loading = false;
    });
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _moneyCard() {
    return _SummaryCard(
      icon: Icons.account_balance_wallet,
      title: 'Money',
      onTap: () => widget.onOpenTab(1),
      child: Row(
        children: [
          Expanded(
            child: _Stat(
              label: 'Spent today',
              value: '₹${_spentToday.toStringAsFixed(0)}',
            ),
          ),
          Expanded(
            child: _Stat(
              label: 'This month',
              value: '₹${_spentMonth.toStringAsFixed(0)}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _tasksCard() {
    final errorColor = Theme.of(context).colorScheme.error;

    return _SummaryCard(
      icon: Icons.check_circle_outline,
      title: 'Tasks due',
      onTap: () => widget.onOpenTab(2),
      child: _dueTasks.isEmpty
          ? const Text('Nothing due today.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_overdueCount > 0)
                  Text(
                    '$_overdueCount overdue',
                    style: TextStyle(
                      color: errorColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                for (final t in _dueTasks.take(3))
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.radio_button_unchecked, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_dueTasks.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('+${_dueTasks.length - 3} more'),
                  ),
              ],
            ),
    );
  }

  Widget _habitsCard() {
    final todayKey = dayKey(DateTime.now());
    final pending = _habits
        .where((h) => !(_checkins[h.id]?.contains(todayKey) ?? false))
        .toList();
    final doneCount = _habits.length - pending.length;

    Widget content;
    if (_habits.isEmpty) {
      content = const Text('No habits yet. Tap to start one.');
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$doneCount of ${_habits.length} done today'),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: doneCount / _habits.length,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          if (pending.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text('All habits done. Nice.'),
            ),
          for (final h in pending.take(4))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(child: Text(h.name)),
                  if (currentStreak(_checkins[h.id] ?? <String>{}) > 0)
                    Text(
                      '${currentStreak(_checkins[h.id] ?? <String>{})} day streak',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                ],
              ),
            ),
        ],
      );
    }

    return _SummaryCard(
      icon: Icons.local_fire_department,
      title: 'Habits',
      onTap: () => widget.onOpenTab(3),
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Today')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_weekdays[now.weekday - 1]}, ${now.day} ${_months[now.month - 1]}',
                        ),
                      ],
                    ),
                  ),
                  _moneyCard(),
                  _tasksCard(),
                  _habitsCard(),
                ],
              ),
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget child;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const Spacer(),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
      ],
    );
  }
}
