class Expense {
  final int? id;
  final String title;
  final double amount;
  final DateTime date;
  final int categoryId;
  final String? note;

  Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.categoryId,
    this.note,
  });

  // Convert an Expense object into a Map
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'categoryId': categoryId,
    };

    // Only include id if it's not null (for updates)
    if (id != null) {
      map['id'] = id;
    }

    // Only include note if it's not null
    if (note != null) {
      map['note'] = note;
    }

    return map;
  }

  // Create an Expense object from a Map
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      categoryId: map['categoryId'],
      note: map['note'],
    );
  }

  // Create a copy of this Expense with the given fields replaced with the new values
  Expense copyWith({
    int? id,
    String? title,
    double? amount,
    DateTime? date,
    int? categoryId,
    String? note,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
    );
  }
}
