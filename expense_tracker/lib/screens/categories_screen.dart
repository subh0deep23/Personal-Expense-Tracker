import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/category.dart';
import '../utils/color_utils.dart';

class CategoriesScreen extends StatefulWidget {
  final Function onCategoriesChanged;

  const CategoriesScreen({super.key, required this.onCategoriesChanged});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await _databaseHelper.getCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading categories: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _addCategory() async {
    final result = await _showCategoryDialog();
    if (result == true) {
      await _loadCategories();
      widget.onCategoriesChanged();
    }
  }

  Future<void> _editCategory(Category category) async {
    final result = await _showCategoryDialog(category: category);
    if (result == true) {
      await _loadCategories();
      widget.onCategoriesChanged();
    }
  }

  Future<bool?> _showCategoryDialog({Category? category}) async {
    final nameController = TextEditingController(text: category?.name ?? '');
    Color selectedColor =
        category != null
            ? ColorUtils.fromHex(category.color)
            : ColorUtils.getCategoryColors().first;

    return showDialog<bool>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(
                  category == null ? 'Add Category' : 'Edit Category',
                ),
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
                          id: category?.id,
                          name: name,
                          color: ColorUtils.toHex(selectedColor),
                        );

                        if (category == null) {
                          await _databaseHelper.insertCategory(newCategory);
                        } else {
                          await _databaseHelper.updateCategory(newCategory);
                        }

                        if (context.mounted) {
                          Navigator.pop(context, true);
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
  }

  Future<void> _deleteCategory(Category category) async {
    // Check if there are expenses using this category
    final expenses = await _databaseHelper.getExpensesByCategoryId(
      category.id!,
    );

    if (expenses.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cannot delete category with expenses. Please delete or reassign the expenses first.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Category'),
            content: Text(
              'Are you sure you want to delete "${category.name}"?',
            ),
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

    if (confirmed == true) {
      try {
        await _databaseHelper.deleteCategory(category.id!);
        await _loadCategories();
        widget.onCategoriesChanged();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting category: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _categories.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.category,
                      size: 80,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha(128), // 0.5 opacity
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No categories yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the + button to add your first category',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadCategories,
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final categoryColor = ColorUtils.fromHex(category.color);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: categoryColor,
                          child: Icon(
                            Icons.category,
                            color: ColorUtils.getContrastingTextColor(
                              categoryColor,
                            ),
                          ),
                        ),
                        title: Text(category.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editCategory(category),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteCategory(category),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        child: const Icon(Icons.add),
      ),
    );
  }
}
