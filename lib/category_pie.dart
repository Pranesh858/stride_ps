import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CategoryPie extends StatelessWidget {
  final Map<String, double> totals;

  const CategoryPie({super.key, required this.totals});

  static const List<Color> _palette = [
    Colors.teal,
    Colors.orange,
    Colors.indigo,
    Colors.pink,
    Colors.amber,
    Colors.green,
    Colors.purple,
    Colors.brown,
  ];

  @override
  Widget build(BuildContext context) {
    if (totals.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(child: Text('No spending this month')),
      );
    }

    final total = totals.values.fold<double>(0, (a, b) => a + b);
    final names = totals.keys.toList()..sort();

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                for (int i = 0; i < names.length; i++)
                  PieChartSectionData(
                    value: totals[names[i]]!,
                    color: _palette[i % _palette.length],
                    title:
                        '${(totals[names[i]]! / total * 100).toStringAsFixed(0)}%',
                    radius: 50,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            for (int i = 0; i < names.length; i++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    color: _palette[i % _palette.length],
                  ),
                  const SizedBox(width: 4),
                  Text('${names[i]} ₹${totals[names[i]]!.toStringAsFixed(0)}'),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
