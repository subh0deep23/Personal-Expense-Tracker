import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../utils/formatters.dart';
import '../utils/color_utils.dart';
import '../widgets/animated_expense_card.dart';
import 'add_expense_screen.dart';
import 'expense_detail_screen.dart';
import 'categories_screen.dart';
import 'summary_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Expense> _expenses = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final expenses = await _databaseHelper.getExpenses();
      final categories = await _databaseHelper.getCategories();

      setState(() {
        _expenses = expenses;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading data: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _addExpense() async {
    // Check if we have categories before proceeding
    if (_categories.isEmpty) {
      // Show a dialog prompting the user to add a category first
      final result = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('No Categories'),
              content: const Text(
                'You need to add at least one category before adding expenses. Would you like to add a category now?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Add Category'),
                ),
              ],
            ),
      );

      if (result == true) {
        // Switch to the Categories tab and show the add category dialog
        setState(() {
          _currentIndex = 2; // Switch to Categories tab
        });
        _showAddCategoryDialog();
      }
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(categories: _categories),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _viewExpenseDetails(Expense expense) async {
    final category = _categories.firstWhere(
      (c) => c.id == expense.categoryId,
      orElse: () => Category(name: 'Unknown', color: '#607D8B'),
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                ExpenseDetailScreen(expense: expense, category: category),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Expense'),
            content: Text(
              'Are you sure you want to delete "${expense.title}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _databaseHelper.deleteExpense(expense.id!);

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Expense deleted')));
          setState(() {
            _isLoading = true;
          });
          _loadData();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting expense: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showAddCategoryDialog() async {
    final nameController = TextEditingController();
    Color selectedColor = Colors.blue; // Default color

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Add Category'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Category Name',
                        ),
                        autofocus: true,
                      ),
                      const SizedBox(height: 16),
                      const Text('Select Color'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            ColorUtils.getCategoryColors().map((color) {
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedColor = color;
                                  });
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          selectedColor == color
                                              ? Colors.white
                                              : Colors.transparent,
                                      width: 2,
                                    ),
                                    boxShadow:
                                        selectedColor == color
                                            ? [
                                              BoxShadow(
                                                color: Colors.black.withAlpha(
                                                  76,
                                                ), // 0.3 opacity
                                                blurRadius: 4,
                                                spreadRadius: 1,
                                              ),
                                            ]
                                            : null,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a category name'),
                          ),
                        );
                        return;
                      }

                      try {
                        final newCategory = Category(
                          name: name,
                          color: ColorUtils.toHex(selectedColor),
                        );

                        await _databaseHelper.insertCategory(newCategory);

                        if (context.mounted) {
                          Navigator.pop(context, true);
                          // Refresh the data
                          _loadData();
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error saving category: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Widget _buildExpenseList() {
    if (_expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 80,
              color: Theme.of(
                context,
              ).colorScheme.primary.withAlpha(128), // 0.5 opacity
            ),
            const SizedBox(height: 16),
            Text(
              'No expenses yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add your first expense',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    // Group expenses by date
    final Map<String, List<Expense>> groupedExpenses = {};
    for (var expense in _expenses) {
      final dateKey = Formatters.formatDateForList(expense.date);
      if (!groupedExpenses.containsKey(dateKey)) {
        groupedExpenses[dateKey] = [];
      }
      groupedExpenses[dateKey]!.add(expense);
    }

    return ListView.builder(
      itemCount: groupedExpenses.length,
      itemBuilder: (context, index) {
        final dateKey = groupedExpenses.keys.elementAt(index);
        final expensesForDate = groupedExpenses[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                dateKey,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ...expensesForDate.map((expense) {
              final category = _categories.firstWhere(
                (c) => c.id == expense.categoryId,
                orElse: () => Category(name: 'Unknown', color: '#607D8B'),
              );

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: AnimatedExpenseCard(
                  expense: expense,
                  category: category,
                  onTap: () => _viewExpenseDetails(expense),
                  onDelete: () => _deleteExpense(expense),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      // Expenses tab
      _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildExpenseList(),

      // Summary tab
      SummaryScreen(
        databaseHelper: _databaseHelper,
        categories: _categories,
        onRefresh: _loadData,
      ),

      // Categories tab
      CategoriesScreen(onCategoriesChanged: _loadData),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Personal Expense Tracker')),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Expenses'),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Summary',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categories',
          ),
        ],
      ),
      floatingActionButton:
          _currentIndex == 0
              ? FloatingActionButton(
                onPressed: _addExpense,
                child: const Icon(Icons.add),
              )
              : null,
    );
  }
}
