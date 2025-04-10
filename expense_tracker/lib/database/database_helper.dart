import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/category.dart';
import '../models/expense.dart';
import 'web_database_helper.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;
  static final WebDatabaseHelper _webHelper = WebDatabaseHelper();
  static final bool _isWeb = kIsWeb;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_isWeb) {
      throw UnsupportedError(
        'SQLite database is not supported on web platform',
      );
    }

    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (_isWeb) {
      throw UnsupportedError(
        'SQLite database is not supported on web platform',
      );
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'expense_tracker.db');

    return await openDatabase(path, version: 1, onCreate: _createDb);
  }

  Future<void> _createDb(Database db, int version) async {
    // Create categories table
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color TEXT NOT NULL
      )
    ''');

    // Create expenses table
    await db.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        categoryId INTEGER NOT NULL,
        note TEXT,
        FOREIGN KEY (categoryId) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    // Insert default categories
    await _insertDefaultCategories(db);
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final defaultCategories = [
      {'name': 'Food', 'color': '#4CAF50'},
      {'name': 'Transportation', 'color': '#2196F3'},
      {'name': 'Entertainment', 'color': '#9C27B0'},
      {'name': 'Shopping', 'color': '#F44336'},
      {'name': 'Bills', 'color': '#FF9800'},
      {'name': 'Health', 'color': '#E91E63'},
      {'name': 'Other', 'color': '#607D8B'},
    ];

    for (var category in defaultCategories) {
      await db.insert('categories', category);
    }
  }

  // CRUD operations for Category

  Future<int> insertCategory(Category category) async {
    if (_isWeb) {
      return await _webHelper.insertCategory(category);
    } else {
      final db = await database;
      return await db.insert('categories', category.toMap());
    }
  }

  Future<List<Category>> getCategories() async {
    if (_isWeb) {
      await _webHelper.init();
      return _webHelper.getCategories();
    } else {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('categories');

      return List.generate(maps.length, (i) {
        return Category.fromMap(maps[i]);
      });
    }
  }

  Future<Category?> getCategoryById(int id) async {
    if (_isWeb) {
      return await _webHelper.getCategoryById(id);
    } else {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'categories',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return Category.fromMap(maps.first);
      }
      return null;
    }
  }

  Future<int> updateCategory(Category category) async {
    if (_isWeb) {
      return await _webHelper.updateCategory(category);
    } else {
      final db = await database;
      return await db.update(
        'categories',
        category.toMap(),
        where: 'id = ?',
        whereArgs: [category.id],
      );
    }
  }

  Future<int> deleteCategory(int id) async {
    if (_isWeb) {
      return await _webHelper.deleteCategory(id);
    } else {
      final db = await database;
      return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
    }
  }

  // CRUD operations for Expense

  Future<int> insertExpense(Expense expense) async {
    if (_isWeb) {
      return await _webHelper.insertExpense(expense);
    } else {
      final db = await database;
      return await db.insert('expenses', expense.toMap());
    }
  }

  Future<List<Expense>> getExpenses() async {
    if (_isWeb) {
      return await _webHelper.getAllExpenses();
    } else {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'expenses',
        orderBy: 'date DESC',
      );

      return List.generate(maps.length, (i) {
        return Expense.fromMap(maps[i]);
      });
    }
  }

  Future<Expense?> getExpenseById(int id) async {
    if (_isWeb) {
      return await _webHelper.getExpenseById(id);
    } else {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'expenses',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return Expense.fromMap(maps.first);
      }
      return null;
    }
  }

  Future<int> updateExpense(Expense expense) async {
    if (_isWeb) {
      return await _webHelper.updateExpense(expense);
    } else {
      final db = await database;
      return await db.update(
        'expenses',
        expense.toMap(),
        where: 'id = ?',
        whereArgs: [expense.id],
      );
    }
  }

  Future<int> deleteExpense(int id) async {
    if (_isWeb) {
      return await _webHelper.deleteExpense(id);
    } else {
      final db = await database;
      return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
    }
  }

  // Query operations

  Future<List<Map<String, dynamic>>> getExpensesByCategory() async {
    if (_isWeb) {
      return await _webHelper.getExpensesByCategory();
    } else {
      final db = await database;
      return await db.rawQuery('''
        SELECT c.id, c.name, c.color, SUM(e.amount) as total
        FROM expenses e
        JOIN categories c ON e.categoryId = c.id
        GROUP BY e.categoryId
        ORDER BY total DESC
      ''');
    }
  }

  Future<List<Expense>> getExpensesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (_isWeb) {
      return await _webHelper.getExpensesByDateRange(startDate, endDate);
    } else {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'expenses',
        where: 'date BETWEEN ? AND ?',
        whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
        orderBy: 'date DESC',
      );

      return List.generate(maps.length, (i) {
        return Expense.fromMap(maps[i]);
      });
    }
  }

  Future<List<Expense>> getExpensesByCategoryId(int categoryId) async {
    if (_isWeb) {
      return await _webHelper.getExpensesByCategoryId(categoryId);
    } else {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'expenses',
        where: 'categoryId = ?',
        whereArgs: [categoryId],
        orderBy: 'date DESC',
      );

      return List.generate(maps.length, (i) {
        return Expense.fromMap(maps[i]);
      });
    }
  }

  Future<double> getTotalExpenses() async {
    if (_isWeb) {
      return await _webHelper.getTotalExpenses();
    } else {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT SUM(amount) as total FROM expenses',
      );
      return result.first['total'] as double? ?? 0.0;
    }
  }
}
