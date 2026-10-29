import 'package:flutter/material.dart';

import 'habits_page.dart';
import 'money_page.dart';
import 'tasks_page.dart';
import 'today_page.dart';

void main() {
  runApp(const StrideApp());
}

class StrideApp extends StatelessWidget {
  const StrideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stride',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  int _todayVersion = 0;

  void _goToTab(int index) {
    setState(() {
      _currentIndex = index;
      if (index == 0) {
        _todayVersion++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          TodayPage(key: ValueKey(_todayVersion), onOpenTab: _goToTab),
          const MoneyPage(),
          const TasksPage(),
          const HabitsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _goToTab,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today), label: 'Today'),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Money',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_fire_department),
            label: 'Habits',
          ),
        ],
      ),
    );
  }
}
