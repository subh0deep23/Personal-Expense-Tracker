import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../utils/color_utils.dart';
import '../widgets/animated_form_field.dart';

class AddExpenseScreen extends StatefulWidget {
  final List<Category> categories;
  final Expense? expense; // If provided, we're editing an existing expense

  const AddExpenseScreen({super.key, required this.categories, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late DateTime _selectedDate;
  late int _selectedCategoryId;
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // If we're editing an existing expense, populate the form
    if (widget.expense != null) {
      _titleController.text = widget.expense!.title;
      _amountController.text = widget.expense!.amount.toString();
      _noteController.text = widget.expense!.note ?? '';
      _selectedDate = widget.expense!.date;
      _selectedCategoryId = widget.expense!.categoryId;
    } else {
      // Default values for new expense
      _selectedDate = DateTime.now();
      // Default to the first category if available, otherwise use a fallback ID
      _selectedCategoryId =
          widget.categories.isNotEmpty && widget.categories[0].id != null
              ? widget.categories[0].id!
              : -1; // Temporary ID that will be replaced when saving
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveExpense() async {
    // Check if we have categories before proceeding
    if (widget.categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a category first before adding an expense'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final title = _titleController.text;
        final amount = double.parse(_amountController.text);
        final note = _noteController.text.isEmpty ? null : _noteController.text;

        // Make sure we have a valid category ID
        if (_selectedCategoryId < 0 && widget.categories.isNotEmpty) {
          // If we have a temporary ID but categories exist, use the first category
          _selectedCategoryId = widget.categories[0].id!;
        }

        final expense = Expense(
          id: widget.expense?.id,
          title: title,
          amount: amount,
          date: _selectedDate,
          categoryId: _selectedCategoryId,
          note: note,
        );

        if (widget.expense == null) {
          // Creating a new expense
          await _databaseHelper.insertExpense(expense);
        } else {
          // Updating an existing expense
          await _databaseHelper.updateExpense(expense);
        }

        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving expense: $e'),
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
      appBar: AppBar(
        title: Text(widget.expense == null ? 'Add Expense' : 'Edit Expense'),
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        // Title field
                        AnimatedFormField(
                          controller: _titleController,
                          labelText: 'Title',
                          prefixIcon: Icons.title,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Amount field
                        AnimatedFormField(
                          controller: _amountController,
                          labelText: 'Amount',
                          prefixIcon: Icons.attach_money,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an amount';
                            }
                            try {
                              final amount = double.parse(value);
                              if (amount <= 0) {
                                return 'Amount must be greater than zero';
                              }
                            } catch (e) {
                              return 'Please enter a valid amount';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Category dropdown
                        widget.categories.isEmpty
                            ? Card(
                              color: Colors.amber.withAlpha(50),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.warning,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'No categories available',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Please add a category first from the Categories tab',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            : DropdownButtonFormField<int>(
                              value: _selectedCategoryId,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                prefixIcon: Icon(Icons.category),
                              ),
                              items:
                                  widget.categories.map((category) {
                                    // Ensure we have a valid ID to use as the value
                                    final categoryId = category.id ?? -1;
                                    return DropdownMenuItem<int>(
                                      value: categoryId,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 16,
                                            height: 16,
                                            decoration: BoxDecoration(
                                              color: ColorUtils.fromHex(
                                                category.color,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(category.name),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategoryId = value!;
                                });
                              },
                            ),
                        const SizedBox(height: 16),

                        // Date picker
                        AnimatedFormField(
                          controller: TextEditingController(
                            text: DateFormat(
                              'MMM dd, yyyy',
                            ).format(_selectedDate),
                          ),
                          labelText: 'Date',
                          prefixIcon: Icons.calendar_today,
                          readOnly: true,
                          onTap: () => _selectDate(context),
                        ),
                        const SizedBox(height: 16),

                        // Note field
                        AnimatedFormField(
                          controller: _noteController,
                          labelText: 'Note (Optional)',
                          prefixIcon: Icons.note,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),

                        // Save button
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 50,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveExpense,
                            style: ElevatedButton.styleFrom(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              widget.expense == null
                                  ? 'Add Expense'
                                  : 'Update Expense',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
