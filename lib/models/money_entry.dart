class MoneyEntry {
  final int? id;
  final String title;
  final double amount;
  final bool isExpense;
  final String category;
  final DateTime date;

  const MoneyEntry({
    this.id,
    required this.title,
    required this.amount,
    required this.isExpense,
    required this.category,
    required this.date,
  });

  Map<String, Object?> toMap() {
    return {
      'title': title,
      'amount': amount,
      'is_expense': isExpense ? 1 : 0,
      'category': category,
      'date': date.toIso8601String(),
    };
  }

  factory MoneyEntry.fromMap(Map<String, Object?> map) {
    return MoneyEntry(
      id: map['id'] as int,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      isExpense: (map['is_expense'] as int) == 1,
      category: map['category'] as String,
      date: DateTime.parse(map['date'] as String),
    );
  }
}
