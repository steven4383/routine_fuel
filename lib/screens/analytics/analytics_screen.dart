import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/expense_model.dart';
import '../../providers/expense_provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/settings_provider.dart';
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
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(
                children: [
                  const SectionHeader(title: 'Overview'),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.5,
                    children: [
                      _AnalyticsMetric(
                        label: "Today's completion",
                        value: '${(habits.todayCompletionPercent * 100).toInt()}%',
                        icon: Icons.today_rounded,
                        color: Colors.teal.shade600,
                        dark: true,
                      ),
                      _AnalyticsMetric(
                        label: 'Best streak',
                        value: habits.habits.isEmpty
                            ? '0'
                            : '${habits.habits.map((h) => h.currentStreak).reduce((a, b) => a > b ? a : b)}',
                        icon: Icons.local_fire_department_rounded,
                        color: Colors.orange.shade600,
                      ),
                      _AnalyticsMetric(
                        label: 'Month spend',
                        value: AppUtils.formatAmount(monthSpend, symbol),
                        icon: Icons.account_balance_wallet_rounded,
                        color: Colors.green.shade600,
                      ),
                      _AnalyticsMetric(
                        label: 'Low stock items',
                        value: '${inventory.lowStockItems.length}',
                        icon: Icons.warning_amber_rounded,
                        color: Colors.red.shade600,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _ChartCard(
            title: 'Weekly Habit Completion',
            child: weeklyStats.isEmpty
                ? const Center(child: Text('No data yet', style: TextStyle(color: Colors.grey)))
                : _WeeklyBarChart(stats: weeklyStats),
          ),
          _ChartCard(
            title: 'Daily Spending',
            child: _SpendingLineChart(
              dailySpending: expenses.dailySpendingThisMonth(),
              symbol: symbol,
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SectionHeader(title: 'Spending by Category'),
                  _CategoryPieChart(
                    breakdown: categoryBreakdown,
                    symbol: symbol,
                    total: monthSpend,
                  ),
                ],
              ),
            ),
          ),
          _BudgetStatusCard(
            value: budget > 0 ? (monthSpend / budget).clamp(0, 1).toDouble() : 0,
            label: AppUtils.formatMonthYear(DateTime.now()),
            subtitle: 'Spent $symbol${monthSpend.toStringAsFixed(0)} of $symbol${budget.toStringAsFixed(0)} budget',
            color: monthSpend > budget * 0.9 ? Colors.red.shade600 : const Color(0xFFFF3B0A),
          ),
          if (habits.habits.any((h) => h.currentStreak > 0))
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(
                  children: [
                    const SectionHeader(title: 'Habit Streaks'),
                    ...(habits.habits.where((h) => h.currentStreak > 0).toList()
                          ..sort((a, b) => b.currentStreak.compareTo(a.currentStreak)))
                        .take(5)
                        .map((h) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F7F7),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE8E8E8)),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    AppUtils.habitCategoryIcon(h.category),
                                    color: AppUtils.habitCategoryColor(h.category),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(h.title, style: Theme.of(context).textTheme.bodyMedium)),
                                  Text(
                                    '${h.currentStreak} day${h.currentStreak > 1 ? 's' : ''}',
                                    style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            )),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AnalyticsMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool dark;

  const _AnalyticsMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = dark ? Colors.white : const Color(0xFF17151A);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF211D22) : const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: dark ? Colors.transparent : const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: foreground.withOpacity(0.72)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: dark ? foreground : color, size: 18),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: foreground),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SectionHeader(title: title),
            SizedBox(height: 180, child: child),
          ],
        ),
      ),
    );
  }
}

class _BudgetStatusCard extends StatelessWidget {
  final String label;
  final double value;
  final String subtitle;
  final Color color;

  const _BudgetStatusCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Budget Status'),
            Row(
              children: [
                Expanded(child: Text(label, style: Theme.of(context).textTheme.titleSmall)),
                Text(
                  '${(value * 100).toInt()}%',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: value,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

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
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 0.5,
              getTitlesWidget: (value, meta) => Text(
                '${(value * 100).toInt()}%',
                style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
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
                  child: Text(entries[idx].key, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SpendingLineChart extends StatelessWidget {
  final Map<int, double> dailySpending;
  final String symbol;
  const _SpendingLineChart({required this.dailySpending, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.secondary;
    if (dailySpending.isEmpty) {
      return const Center(child: Text('No data yet', style: TextStyle(color: Colors.grey)));
    }

    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final spots = List.generate(daysInMonth, (i) {
      final day = i + 1;
      return FlSpot(day.toDouble(), dailySpending[day] ?? 0);
    });

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
            belowBarData: BarAreaData(show: true, color: color.withOpacity(0.1)),
          ),
        ],
      ),
    );
  }
}

class _CategoryPieChart extends StatefulWidget {
  final Map<ExpenseCategory, double> breakdown;
  final String symbol;
  final double total;
  const _CategoryPieChart({required this.breakdown, required this.symbol, required this.total});

  @override
  State<_CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<_CategoryPieChart> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final nonZero = widget.breakdown.entries.where((e) => e.value > 0).toList();

    if (nonZero.isEmpty || widget.total == 0) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('No spending data this month', style: TextStyle(color: Colors.grey))),
      );
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
                    if (!event.isInterestedForInteractions || response == null || response.touchedSection == null) {
                      _touched = -1;
                      return;
                    }
                    _touched = response.touchedSection!.touchedSectionIndex;
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
                  title: pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
                  titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
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
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
                ),
                const SizedBox(width: 6),
                Text(
                  '${e.key.categoryLabel}: ${widget.symbol}${e.value.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
