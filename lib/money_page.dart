import 'package:flutter/material.dart';

import 'models/money_entry.dart';
import 'add_entry_sheet.dart';
import 'category_pie.dart';
import 'database/app_database.dart';

class MoneyPage extends StatefulWidget {
  const MoneyPage({super.key});

  @override
  State<MoneyPage> createState() => _MoneyPageState();
}

class _MoneyPageState extends State<MoneyPage> {
  List<MoneyEntry> _entries = [];
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  static const List<String> _monthNames = [
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
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final entries = await AppDatabase.instance.getEntries();
    if (!mounted) return;
    setState(() {
      _entries = entries;
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
  }

  Future<void> _openAddSheet() async {
    final MoneyEntry? newEntry = await showModalBottomSheet<MoneyEntry>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddEntrySheet(),
    );

    if (newEntry != null) {
      await AppDatabase.instance.insertEntry(newEntry);
      if (!mounted) return;
      setState(() {
        _month = DateTime(newEntry.date.year, newEntry.date.month);
      });
      await _loadEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries
        .where(
          (e) => e.date.year == _month.year && e.date.month == _month.month,
        )
        .toList();

    double income = 0;
    double expense = 0;
    final Map<String, double> categoryTotals = {};

    for (final e in entries) {
      if (e.isExpense) {
        expense += e.amount;
        categoryTotals[e.category] =
            (categoryTotals[e.category] ?? 0) + e.amount;
      } else {
        income += e.amount;
      }
    }
    final balance = income - expense;

    return Scaffold(
      appBar: AppBar(title: const Text('Money')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSheet,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => _changeMonth(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                '${_monthNames[_month.month - 1]} ${_month.year}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                onPressed: () => _changeMonth(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Balance'),
                    Text(
                      '₹${balance.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text('Income: ₹${income.toStringAsFixed(0)}'),
                        Text('Spent: ₹${expense.toStringAsFixed(0)}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spending by category',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  CategoryPie(totals: categoryTotals),
                ],
              ),
            ),
          ),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('No entries this month. Tap + to add one.'),
              ),
            ),
          for (final e in entries)
            Dismissible(
              key: ValueKey(e.id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) async {
                setState(() {
                  _entries.removeWhere((x) => x.id == e.id);
                });
                await AppDatabase.instance.deleteEntry(e.id!);
              },
              child: ListTile(
                leading: Icon(
                  e.isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                ),
                title: Text(e.title),
                subtitle: Text(e.category),
                trailing: Text(
                  '${e.isExpense ? '-' : '+'}₹${e.amount.toStringAsFixed(0)}',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
