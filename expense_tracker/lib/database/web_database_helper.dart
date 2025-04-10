import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import '../models/expense.dart';

class WebDatabaseHelper {
  static final WebDatabaseHelper _instance = WebDatabaseHelper._internal();
  factory WebDatabaseHelper() => _instance;

  static SharedPreferences? _prefs;

  // Keys for SharedPreferences
  static const String _categoriesKey = 'categories';
  static const String _expensesKey = 'expenses';
  static int _categoryIdCounter = 0;
  static int _expenseIdCounter = 0;

  WebDatabaseHelper._internal();

  Future<void> init() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();

      // Initialize ID counters
      final categories = getCategories();
      final expenses = getExpenses();

      if (categories.isNotEmpty) {
        _categoryIdCounter =
            categories.map((c) => c.id ?? 0).reduce((a, b) => a > b ? a : b) +
            1;
      }

      if (expenses.isNotEmpty) {
        _expenseIdCounter =
            expenses.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
      }

      // Add default categories if none exist
      if (categories.isEmpty) {
        await _insertDefaultCategories();
      }
    }
  }

  Future<void> _insertDefaultCategories() async {
    final defaultCategories = [
      Category(id: 1, name: 'Food', color: '#4CAF50'),
      Category(id: 2, name: 'Transportation', color: '#2196F3'),
      Category(id: 3, name: 'Entertainment', color: '#9C27B0'),
      Category(id: 4, name: 'Shopping', color: '#F44336'),
      Category(id: 5, name: 'Bills', color: '#FF9800'),
      Category(id: 6, name: 'Health', color: '#E91E63'),
      Category(id: 7, name: 'Other', color: '#607D8B'),
    ];

    _categoryIdCounter = 8; // Set the counter after the default categories

    final List<String> serializedCategories =
        defaultCategories
            .map((category) => jsonEncode(category.toMap()))
            .toList();

    await _prefs!.setStringList(_categoriesKey, serializedCategories);
  }

  // Storage methods
  List<Category> getCategories() {
    if (_prefs == null) return [];

    final List<String>? serializedCategories = _prefs!.getStringList(
      _categoriesKey,
    );
    if (serializedCategories == null || serializedCategories.isEmpty) return [];

    return serializedCategories
        .map((serialized) => Category.fromMap(jsonDecode(serialized)))
        .toList();
  }

  List<Expense> getExpenses() {
    if (_prefs == null) return [];

    final List<String>? serializedExpenses = _prefs!.getStringList(
      _expensesKey,
    );
    if (serializedExpenses == null || serializedExpenses.isEmpty) return [];

    return serializedExpenses
        .map((serialized) => Expense.fromMap(jsonDecode(serialized)))
        .toList();
  }

  Future<void> saveCategories(List<Category> categories) async {
    if (_prefs == null) await init();

    final List<String> serializedCategories =
        categories.map((category) => jsonEncode(category.toMap())).toList();

    await _prefs!.setStringList(_categoriesKey, serializedCategories);
  }

  Future<void> saveExpenses(List<Expense> expenses) async {
    if (_prefs == null) await init();

    final List<String> serializedExpenses =
        expenses.map((expense) => jsonEncode(expense.toMap())).toList();

    await _prefs!.setStringList(_expensesKey, serializedExpenses);
  }

  // CRUD operations for Category

  Future<int> insertCategory(Category category) async {
    await init();

    final categories = getCategories();
    final newCategory = Category(
      id: _categoryIdCounter++,
      name: category.name,
      color: category.color,
    );

    categories.add(newCategory);
    await saveCategories(categories);

    return newCategory.id!;
  }

  Future<Category?> getCategoryById(int id) async {
    await init();
    final categories = getCategories();
    try {
      return categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<int> updateCategory(Category category) async {
    if (category.id == null) {
      throw ArgumentError('Category ID cannot be null for update operation');
    }

    await init();

    final categories = getCategories();
    final index = categories.indexWhere((c) => c.id == category.id);

    if (index != -1) {
      categories[index] = category;
      await saveCategories(categories);
      return 1; // Return 1 to indicate success
    }
    return 0; // Return 0 to indicate no rows were updated
  }

  Future<int> deleteCategory(int id) async {
    await init();

    final categories = getCategories();
    final initialLength = categories.length;

    categories.removeWhere((category) => category.id == id);

    if (initialLength != categories.length) {
      await saveCategories(categories);

      // Also remove expenses with this category
      final expenses = getExpenses();
      expenses.removeWhere((expense) => expense.categoryId == id);
      await saveExpenses(expenses);

      return 1; // Return 1 to indicate success
    }
    return 0; // Return 0 to indicate no rows were deleted
  }

  // CRUD operations for Expense

  Future<int> insertExpense(Expense expense) async {
    await init();

    final expenses = getExpenses();
    final newExpense = Expense(
      id: _expenseIdCounter++,
      title: expense.title,
      amount: expense.amount,
      date: expense.date,
      categoryId: expense.categoryId,
      note: expense.note,
    );

    expenses.add(newExpense);
    await saveExpenses(expenses);

    return newExpense.id!;
  }

  Future<List<Expense>> getAllExpenses() async {
    await init();
    final expenses = getExpenses();

    // Sort by date descending
    expenses.sort((a, b) => b.date.compareTo(a.date));

    return expenses;
  }

  Future<Expense?> getExpenseById(int id) async {
    await init();
    final expenses = getExpenses();
    try {
      return expenses.firstWhere((expense) => expense.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<int> updateExpense(Expense expense) async {
    if (expense.id == null) {
      throw ArgumentError('Expense ID cannot be null for update operation');
    }

    await init();

    final expenses = getExpenses();
    final index = expenses.indexWhere((e) => e.id == expense.id);

    if (index != -1) {
      expenses[index] = expense;
      await saveExpenses(expenses);
      return 1; // Return 1 to indicate success
    }
    return 0; // Return 0 to indicate no rows were updated
  }

  Future<int> deleteExpense(int id) async {
    await init();

    final expenses = getExpenses();
    final initialLength = expenses.length;

    expenses.removeWhere((expense) => expense.id == id);

    if (initialLength != expenses.length) {
      await saveExpenses(expenses);
      return 1; // Return 1 to indicate success
    }
    return 0; // Return 0 to indicate no rows were deleted
  }

  // Query operations

  Future<List<Map<String, dynamic>>> getExpensesByCategory() async {
    await init();

    final expenses = getExpenses();
    final categories = getCategories();

    // Group expenses by category and calculate totals
    final Map<int, double> categoryTotals = {};
    for (var expense in expenses) {
      categoryTotals[expense.categoryId] =
          (categoryTotals[expense.categoryId] ?? 0) + expense.amount;
    }

    // Create result in the same format as the SQL query
    final List<Map<String, dynamic>> result = [];
    for (var category in categories) {
      if (category.id != null && categoryTotals.containsKey(category.id)) {
        result.add({
          'id': category.id,
          'name': category.name,
          'color': category.color,
          'total': categoryTotals[category.id],
        });
      }
    }

    // Sort by total descending
    result.sort(
      (a, b) => (b['total'] as double).compareTo(a['total'] as double),
    );

    return result;
  }

  Future<List<Expense>> getExpensesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    await init();

    final expenses = getExpenses();

    return expenses.where((expense) {
        return expense.date.isAfter(
              startDate.subtract(const Duration(days: 1)),
            ) &&
            expense.date.isBefore(endDate.add(const Duration(days: 1)));
      }).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Sort by date descending
  }

  Future<List<Expense>> getExpensesByCategoryId(int categoryId) async {
    await init();

    final expenses = getExpenses();

    return expenses
        .where((expense) => expense.categoryId == categoryId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Sort by date descending
  }

  Future<double> getTotalExpenses() async {
    await init();

    final expenses = getExpenses();

    if (expenses.isEmpty) return 0.0;

    double total = 0.0;
    for (var expense in expenses) {
      total += expense.amount;
    }
    return total;
  }
}
