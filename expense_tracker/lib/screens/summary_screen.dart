import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/category.dart';
import '../utils/formatters.dart';
import '../utils/color_utils.dart';

class SummaryScreen extends StatefulWidget {
  final DatabaseHelper databaseHelper;
  final List<Category> categories;
  final Function onRefresh;

  const SummaryScreen({
    super.key,
    required this.databaseHelper,
    required this.categories,
    required this.onRefresh,
  });

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  List<Map<String, dynamic>> _categoryExpenses = [];
  double _totalExpenses = 0;
  bool _isLoading = true;
  String _timeRange = 'All Time';
  final List<String> _timeRanges = ['All Time', 'This Month', 'This Week'];

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
      DateTime? startDate;
      final now = DateTime.now();

      if (_timeRange == 'This Month') {
        startDate = DateTime(now.year, now.month, 1);
      } else if (_timeRange == 'This Week') {
        // Calculate the start of the week (Sunday)
        final daysToSubtract = now.weekday % 7;
        startDate = DateTime(now.year, now.month, now.day - daysToSubtract);
      }

      List<Map<String, dynamic>> categoryExpenses;

      if (startDate != null) {
        final expenses = await widget.databaseHelper.getExpensesByDateRange(
          startDate,
          now.add(const Duration(days: 1)),
        );

        // Manually calculate totals by category
        final Map<int, double> categoryTotals = {};
        for (var expense in expenses) {
          categoryTotals[expense.categoryId] =
              (categoryTotals[expense.categoryId] ?? 0) + expense.amount;
        }

        categoryExpenses = [];
        for (var category in widget.categories) {
          if (categoryTotals.containsKey(category.id)) {
            categoryExpenses.add({
              'id': category.id,
              'name': category.name,
              'color': category.color,
              'total': categoryTotals[category.id],
            });
          }
        }

        // Sort by total (descending)
        categoryExpenses.sort(
          (a, b) => (b['total'] as double).compareTo(a['total'] as double),
        );

        // Calculate total
        _totalExpenses = categoryTotals.values.fold(
          0,
          (sum, amount) => sum + amount,
        );
      } else {
        // Get all time data
        categoryExpenses = await widget.databaseHelper.getExpensesByCategory();
        _totalExpenses = await widget.databaseHelper.getTotalExpenses();
      }

      setState(() {
        _categoryExpenses = categoryExpenses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading summary data: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: () async {
                  await widget.onRefresh();
                  await _loadData();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time range selector
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Time Range',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              SegmentedButton<String>(
                                segments:
                                    _timeRanges.map((range) {
                                      return ButtonSegment<String>(
                                        value: range,
                                        label: Text(range),
                                      );
                                    }).toList(),
                                selected: {_timeRange},
                                onSelectionChanged: (Set<String> newSelection) {
                                  setState(() {
                                    _timeRange = newSelection.first;
                                  });
                                  _loadData();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Total expenses
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Expenses',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                Formatters.formatCurrency(_totalExpenses),
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              Text(
                                _getTimeRangeText(),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Pie chart
                      if (_categoryExpenses.isNotEmpty) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Spending by Category',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 200,
                                  child: PieChart(
                                    PieChartData(
                                      sections: _buildPieChartSections(),
                                      centerSpaceRadius: 40,
                                      sectionsSpace: 2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Category breakdown
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Category Breakdown',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 16),
                              if (_categoryExpenses.isEmpty)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'No expenses in this time period',
                                    ),
                                  ),
                                )
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _categoryExpenses.length,
                                  itemBuilder: (context, index) {
                                    final category = _categoryExpenses[index];
                                    final total = category['total'] as double;
                                    final percentage =
                                        _totalExpenses > 0
                                            ? (total / _totalExpenses * 100)
                                            : 0;
                                    final color = ColorUtils.fromHex(
                                      category['color'],
                                    );

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 16,
                                            height: 16,
                                            decoration: BoxDecoration(
                                              color: color,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(category['name']),
                                          ),
                                          Text(
                                            Formatters.formatCurrency(total),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '(${percentage.toStringAsFixed(1)}%)',
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    return _categoryExpenses.map((category) {
      final total = category['total'] as double;
      final percentage =
          _totalExpenses > 0 ? (total / _totalExpenses * 100) : 0;
      final color = ColorUtils.fromHex(category['color']);

      return PieChartSectionData(
        value: total,
        title: '${percentage.toStringAsFixed(1)}%',
        color: color,
        radius: 80,
        titleStyle: TextStyle(
          color: ColorUtils.getContrastingTextColor(color),
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();
  }

  String _getTimeRangeText() {
    final now = DateTime.now();
    final dateFormatter = DateFormat();

    switch (_timeRange) {
      case 'This Month':
        return 'For ${DateFormat('MMMM yyyy').format(now)}';
      case 'This Week':
        final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
        return 'From ${DateFormat('MMM dd').format(startOfWeek)} to ${DateFormat('MMM dd').format(now)}';
      default:
        return 'All time';
    }
  }
}
