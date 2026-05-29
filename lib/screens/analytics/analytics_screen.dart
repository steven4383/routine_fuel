import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/habit_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/expense_model.dart';
import '../../utils/app_utils.dart';
import '../../widgets/shared_widgets.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<HabitProvider>();
    final expenses = context.watch<ExpenseProvider>();
    final inventory = context.watch<InventoryProvider>();
    final settings = context.watch<SettingsProvider>();
    final symbol = settings.currencySymbol;

    final weeklyStats = habits.weeklyCompletionRate();
    final categoryBreakdown = expenses.monthCategoryBreakdown();
    final monthSpend = expenses.monthTotal;
    final budget = settings.monthlyBudget;

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          // Summary stats
          const SectionHeader(title: 'Overview'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              StatCard(
                label: "Today's completion",
                value:
                    '${(habits.todayCompletionPercent * 100).toInt()}%',
                icon: Icons.today_rounded,
                color: Colors.teal.shade600,
              ),
              StatCard(
                label: 'Best streak',
                value: habits.habits.isEmpty
                    ? '0'
                    : '${habits.habits.map((h) => h.currentStreak).reduce((a, b) => a > b ? a : b)} 🔥',
                icon: Icons.local_fire_department_rounded,
                color: Colors.orange.shade600,
              ),
              StatCard(
                label: 'Month spend',
                value: AppUtils.formatAmount(monthSpend, symbol),
                icon: Icons.account_balance_wallet_rounded,
                color: Colors.green.shade600,
              ),
              StatCard(
                label: 'Low stock items',
                value: '${inventory.lowStockItems.length}',
                icon: Icons.warning_amber_rounded,
                color: Colors.red.shade600,
              ),
            ],
          ),

          // Weekly habit bar chart
          const SectionHeader(title: 'Weekly Habit Completion'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: weeklyStats.isEmpty
                  ? const Center(
                      child: Text('No data yet',
                          style: TextStyle(color: Colors.grey)))
                  : SizedBox(
                      height: 180,
                      child: _WeeklyBarChart(stats: weeklyStats),
                    ),
            ),
          ),

          // Monthly spending line chart
          const SectionHeader(title: 'Daily Spending (This Month)'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 180,
                child: _SpendingLineChart(
                  dailySpending: expenses.dailySpendingThisMonth(),
                  symbol: symbol,
                ),
              ),
            ),
          ),

          // Category pie chart
          const SectionHeader(title: 'Spending by Category'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _CategoryPieChart(
                breakdown: categoryBreakdown,
                symbol: symbol,
                total: monthSpend,
              ),
            ),
          ),

          // Budget vs spend
          const SectionHeader(title: 'Budget Status'),
          ProgressCard(
            label:
                AppUtils.formatMonthYear(DateTime.now()),
            value: budget > 0 ? (monthSpend / budget).clamp(0, 1) : 0,
            subtitle:
                'Spent $symbol${monthSpend.toStringAsFixed(0)} of $symbol${budget.toStringAsFixed(0)} budget',
            color: monthSpend > budget * 0.9
                ? Colors.red.shade600
                : Colors.green.shade600,
          ),

          // Habit streaks list
          if (habits.habits.isNotEmpty) ...[
            const SectionHeader(title: 'Habit Streaks'),
            Card(
              child: Column(
                children: (habits.habits
                      .where((h) => h.currentStreak > 0)
                      .toList()
                    ..sort((a, b) =>
                        b.currentStreak.compareTo(a.currentStreak)))
                    .take(5)
                    .map((h) => ListTile(
                        dense: true,
                        leading: Icon(
                            AppUtils.habitCategoryIcon(h.category),
                            color:
                                AppUtils.habitCategoryColor(h.category),
                            size: 20),
                        title: Text(h.title,
                            style:
                                Theme.of(context).textTheme.bodyMedium),
                        trailing: Text(
                          '🔥 ${h.currentStreak} day${h.currentStreak > 1 ? 's' : ''}',
                          style: TextStyle(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w600),
                        ),
                      ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Weekly Bar Chart ─────────────────────────────────────────────────────────

class _WeeklyBarChart extends StatelessWidget {
  final Map<String, double> stats;
  const _WeeklyBarChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final entries = stats.entries.toList();

    return BarChart(
      BarChartData(
        maxY: 1.0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 0.25,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 0.5,
              getTitlesWidget: (value, meta) => Text(
                '${(value * 100).toInt()}%',
                style: TextStyle(
                    fontSize: 9, color: Colors.grey.shade500),
              ),
              reservedSize: 32,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= entries.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    entries[idx].key,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: entries.asMap().entries.map((e) {
          final idx = e.key;
          final val = e.value.value;
          return BarChartGroupData(
            x: idx,
            barRods: [
              BarChartRodData(
                toY: val,
                color: val >= 1.0
                    ? color
                    : val > 0
                        ? color.withOpacity(0.6)
                        : Colors.grey.shade200,
                width: 28,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── Spending Line Chart ──────────────────────────────────────────────────────

class _SpendingLineChart extends StatelessWidget {
  final Map<int, double> dailySpending;
  final String symbol;
  const _SpendingLineChart(
      {required this.dailySpending, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.secondary;
    if (dailySpending.isEmpty) {
      return const Center(
          child: Text('No data yet', style: TextStyle(color: Colors.grey)));
    }

    final now = DateTime.now();
    final daysInMonth =
        DateTime(now.year, now.month + 1, 0).day;
    final spots = List.generate(daysInMonth, (i) {
      final day = i + 1;
      return FlSpot(day.toDouble(), dailySpending[day] ?? 0);
    });

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (val, meta) => Text(
                AppUtils.formatAmount(val, symbol),
                style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 7,
              getTitlesWidget: (val, meta) => Text(
                val.toInt().toString(),
                style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
              ),
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category Pie Chart ───────────────────────────────────────────────────────

class _CategoryPieChart extends StatefulWidget {
  final Map<ExpenseCategory, double> breakdown;
  final String symbol;
  final double total;
  const _CategoryPieChart(
      {required this.breakdown,
      required this.symbol,
      required this.total});

  @override
  State<_CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<_CategoryPieChart> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final nonZero = widget.breakdown.entries
        .where((e) => e.value > 0)
        .toList();

    if (nonZero.isEmpty || widget.total == 0) {
      return const Center(
          child: Text('No spending data this month',
              style: TextStyle(color: Colors.grey)));
    }

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.touchedSection == null) {
                      _touched = -1;
                      return;
                    }
                    _touched =
                        response.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sections: nonZero.asMap().entries.map((e) {
                final isTouched = e.key == _touched;
                final color = AppUtils.expenseCategoryColor(e.value.key);
                final pct = e.value.value / widget.total * 100;
                return PieChartSectionData(
                  value: e.value.value,
                  color: color,
                  radius: isTouched ? 60 : 50,
                  title: pct >= 8
                      ? '${pct.toStringAsFixed(0)}%'
                      : '',
                  titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                );
              }).toList(),
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: nonZero.map((e) {
            final color = AppUtils.expenseCategoryColor(e.key);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: color, borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 6),
                Text(
                  '${e.key.categoryLabel}: ${widget.symbol}${e.value.toStringAsFixed(0)}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
