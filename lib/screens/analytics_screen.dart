import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_state.dart';
import '../models/transaction.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'month'; // week, month, year

  DateTime get _startDate {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'week':
        return now.subtract(const Duration(days: 7));
      case 'month':
        return DateTime(now.year, now.month, 1);
      case 'year':
        return DateTime(now.year, 1, 1);
      default:
        return DateTime(now.year, now.month, 1);
    }
  }

  DateTime get _endDate => DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'week',
                  label: Text('Week'),
                ),
                ButtonSegment(
                  value: 'month',
                  label: Text('Month'),
                ),
                ButtonSegment(
                  value: 'year',
                  label: Text('Year'),
                ),
              ],
              selected: {_selectedPeriod},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedPeriod = newSelection.first;
                });
              },
            ),
          ),
        ),
      ),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          return FutureBuilder<Map<String, dynamic>>(
            future: _loadAnalyticsData(appState),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!['transactions'].isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 64,
                        color: theme.colorScheme.primary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No data available',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add transactions to see analytics',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final data = snapshot.data!;
              final totalIncome = data['totalIncome'] as double;
              final totalExpenses = data['totalExpenses'] as double;
              final spendingByCategory = data['spendingByCategory'] as Map<String, double>;
              final transactions = data['transactions'] as List<Transaction>;

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                },
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Summary Cards
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            color: Colors.green.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.arrow_downward,
                                        color: Colors.green.shade700,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Income',
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    currencyFormat.format(totalIncome),
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: Colors.green.shade900,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Card(
                            color: Colors.red.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.arrow_upward,
                                        color: Colors.red.shade700,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Expenses',
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    currencyFormat.format(totalExpenses),
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: Colors.red.shade900,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Net Income/Loss
                    Card(
                      color: totalIncome - totalExpenses >= 0
                          ? Colors.blue.shade50
                          : Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              totalIncome - totalExpenses >= 0
                                  ? 'Net Income'
                                  : 'Net Loss',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              currencyFormat.format((totalIncome - totalExpenses).abs()),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: totalIncome - totalExpenses >= 0
                                    ? Colors.blue.shade900
                                    : Colors.orange.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Spending by Category - Pie Chart
                    if (spendingByCategory.isNotEmpty) ...[
                      Text(
                        'Spending by Category',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 250,
                                child: _SpendingPieChart(
                                  spendingByCategory: spendingByCategory,
                                  appState: appState,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _CategoryLegend(
                                spendingByCategory: spendingByCategory,
                                appState: appState,
                                totalExpenses: totalExpenses,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Daily Spending Trend - Bar Chart
                    Text(
                      'Daily Spending Trend',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          height: 250,
                          child: _DailySpendingChart(
                            transactions: transactions,
                            startDate: _startDate,
                            endDate: _endDate,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _loadAnalyticsData(AppState appState) async {
    final transactions = appState.getTransactionsByDateRange(
      _startDate,
      _endDate,
    );
    final spendingByCategory = appState.getSpendingByCategory(
      _startDate,
      _endDate,
    );
    final totalIncome = appState.getTotalIncome(_startDate, _endDate);
    final totalExpenses = appState.getTotalExpenses(_startDate, _endDate);

    return {
      'transactions': transactions,
      'spendingByCategory': spendingByCategory,
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
    };
  }
}

class _SpendingPieChart extends StatefulWidget {
  final Map<String, double> spendingByCategory;
  final AppState appState;

  const _SpendingPieChart({
    required this.spendingByCategory,
    required this.appState,
  });

  @override
  State<_SpendingPieChart> createState() => _SpendingPieChartState();
}

class _SpendingPieChartState extends State<_SpendingPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final total = widget.spendingByCategory.values.fold(0.0, (a, b) => a + b);
    
    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  pieTouchResponse == null ||
                  pieTouchResponse.touchedSection == null) {
                touchedIndex = -1;
                return;
              }
              touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
            });
          },
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: _buildSections(total),
      ),
    );
  }

  List<PieChartSectionData> _buildSections(double total) {
    final entries = widget.spendingByCategory.entries.toList();
    
    return List.generate(entries.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 65.0 : 55.0;
      
      final category = widget.appState.getCategoryById(entries[i].key);
      final percentage = (entries[i].value / total * 100);
      
      return PieChartSectionData(
        color: category?.color ?? Colors.grey,
        value: entries[i].value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }
}

class _CategoryLegend extends StatelessWidget {
  final Map<String, double> spendingByCategory;
  final AppState appState;
  final double totalExpenses;

  const _CategoryLegend({
    required this.spendingByCategory,
    required this.appState,
    required this.totalExpenses,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final entries = spendingByCategory.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: entries.map((entry) {
        final category = appState.getCategoryById(entry.key);
        final percentage = (entry.value / totalExpenses * 100);
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: category?.color ?? Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category?.name ?? entry.key,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                currencyFormat.format(entry.value),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _DailySpendingChart extends StatelessWidget {
  final List<Transaction> transactions;
  final DateTime startDate;
  final DateTime endDate;

  const _DailySpendingChart({
    required this.transactions,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    final dailySpending = <DateTime, double>{};
    
    // Group transactions by day
    for (var transaction in transactions) {
      if (transaction.type == TransactionType.expense) {
        final date = DateTime(
          transaction.date.year,
          transaction.date.month,
          transaction.date.day,
        );
        dailySpending[date] = (dailySpending[date] ?? 0) + transaction.amount;
      }
    }

    if (dailySpending.isEmpty) {
      return const Center(
        child: Text('No spending data available'),
      );
    }

    final sortedDates = dailySpending.keys.toList()..sort();
    final maxSpending = dailySpending.values.reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxSpending * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final date = sortedDates[group.x.toInt()];
              return BarTooltipItem(
                '${DateFormat('MMM dd').format(date)}\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: NumberFormat.currency(symbol: '\$').format(rod.toY),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= sortedDates.length) return const Text('');
                final date = sortedDates[value.toInt()];
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('dd').format(date),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '\$${value.toInt()}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          sortedDates.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: dailySpending[sortedDates[index]]!,
                color: Colors.blue,
                width: 16,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
