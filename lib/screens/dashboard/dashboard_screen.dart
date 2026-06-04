import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/expense_provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/shopping_provider.dart';
import '../../utils/app_utils.dart';
import '../../widgets/shared_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<HabitProvider>();
    final inventory = context.watch<InventoryProvider>();
    final expenses = context.watch<ExpenseProvider>();
    final settings = context.watch<SettingsProvider>();
    final shopping = context.watch<ShoppingProvider>();

    final completionPercent = habits.todayCompletionPercent;
    final lowStockItems = inventory.lowStockItems;
    final monthSpend = expenses.monthTotal;
    final budget = settings.monthlyBudget;
    final symbol = settings.currencySymbol;
    final budgetPercent = budget > 0 ? (monthSpend / budget).clamp(0.0, 1.0).toDouble() : 0.0;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B0A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.local_fire_department_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppUtils.greeting(), style: Theme.of(context).textTheme.titleLarge),
                      Text(
                        AppUtils.formatDate(DateTime.now()),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => context.go('/settings'),
                  icon: const Icon(Icons.tune_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DashboardHero(
              completionPercent: completionPercent,
              habitValue: '${habits.completedToday.length}/${habits.todayHabits.length}',
              spendValue: AppUtils.formatAmountFull(monthSpend, symbol),
              spendSubtitle: budget > 0 ? 'of ${AppUtils.formatAmountFull(budget, symbol)}' : 'No budget set',
              budgetPercent: budgetPercent,
            ),
            const SizedBox(height: 10),
            _TodayHabitsCard(habits: habits),
            if (lowStockItems.isNotEmpty)
              _DashboardPanel(
                title: 'Low Stock',
                actionLabel: 'View all',
                onAction: () => context.go('/inventory'),
                children: lowStockItems
                    .take(3)
                    .map(
                      (item) => _AlertRow(
                        icon: Icons.warning_amber_rounded,
                        text:
                            '${item.name}: ${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} ${item.unitLabel} left',
                        onTap: () => context.go('/inventory'),
                      ),
                    )
                    .toList(),
              ),
            ProgressCard(
              label: AppUtils.formatMonthYear(DateTime.now()),
              value: budgetPercent,
              subtitle:
                  '${AppUtils.formatAmountFull(monthSpend, symbol)} of ${AppUtils.formatAmountFull(budget, symbol)}',
              color: monthSpend > budget * 0.9 ? Colors.red.shade600 : const Color(0xFFFF3B0A),
            ),
            _QuickActionsGrid(),
            if (shopping.pending.isNotEmpty)
              _DashboardPanel(
                title: 'Shopping List',
                actionLabel: 'View all',
                onAction: () => context.go('/shopping'),
                children: [
                  _AlertRow(
                    icon: Icons.shopping_cart_rounded,
                    text:
                        '${shopping.pending.length} item${shopping.pending.length > 1 ? 's' : ''} waiting to be purchased',
                    onTap: () => context.go('/shopping'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  final double completionPercent;
  final double budgetPercent;
  final String habitValue;
  final String spendValue;
  final String spendSubtitle;

  const _DashboardHero({
    required this.completionPercent,
    required this.budgetPercent,
    required this.habitValue,
    required this.spendValue,
    required this.spendSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Habits Done',
                value: habitValue,
                subtitle: 'Today',
                icon: Icons.checklist_rounded,
                dark: true,
                onTap: () => context.go('/habits'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: _CompletionRing(percent: completionPercent)),
          ],
        ),
        const SizedBox(height: 10),
        _WideChartCard(
          value: spendValue,
          subtitle: spendSubtitle,
          percent: budgetPercent,
          onTap: () => context.go('/expenses'),
        ),
      ],
    );
  }
}

class _CompletionRing extends StatelessWidget {
  final double percent;
  const _CompletionRing({required this.percent});

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0.0, 1.0);
    final done = clamped <= 0 ? 0.001 : clamped;
    final remaining = (1 - clamped).clamp(0.001, 1.0);

    return Container(
      height: 156,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3B0A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Daily Completion',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.78)),
                ),
              ),
              const Icon(Icons.donut_large_rounded, color: Colors.white, size: 17),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 82,
                  child: PieChart(
                    PieChartData(
                      startDegreeOffset: -90,
                      sectionsSpace: 2,
                      centerSpaceRadius: 26,
                      pieTouchData: PieTouchData(enabled: false),
                      sections: [
                        PieChartSectionData(
                          value: done.toDouble(),
                          color: Colors.white,
                          radius: 13,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          value: remaining.toDouble(),
                          color: const Color(0xFF211D22),
                          radius: 13,
                          showTitle: false,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${(clamped * 100).round()}%',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: clamped.toDouble(),
                        minHeight: 8,
                        backgroundColor: const Color(0xFF211D22),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WideChartCard extends StatelessWidget {
  final String value;
  final String subtitle;
  final double percent;
  final VoidCallback onTap;

  const _WideChartCard({
    required this.value,
    required this.subtitle,
    required this.percent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bars = [0.30, 0.52, 0.38, 0.66, 0.45, percent.clamp(0.10, 1.0), 0.58, 0.82];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 184,
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Monthly Spend', style: Theme.of(context).textTheme.titleMedium)),
                const Icon(Icons.tune_rounded, size: 18, color: Color(0xFF211D22)),
              ],
            ),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const Spacer(),
            SizedBox(
              height: 62,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: 1,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  barTouchData: BarTouchData(enabled: false),
                  barGroups: bars.asMap().entries.map((entry) {
                    final active = entry.key == 5;
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value,
                          width: 15,
                          color: active ? const Color(0xFFFF3B0A) : const Color(0xFF211D22),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final bool dark;
  final VoidCallback onTap;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = dark ? Colors.white : const Color(0xFF17151A);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 156,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF211D22) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: dark ? Colors.transparent : const Color(0xFFE8E8E8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: foreground)),
                ),
                Icon(icon, size: 18, color: foreground),
              ],
            ),
            const Spacer(),
            Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: foreground)),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: foreground.withOpacity(0.58))),
          ],
        ),
      ),
    );
  }
}

class _TodayHabitsCard extends StatelessWidget {
  final HabitProvider habits;
  const _TodayHabitsCard({required this.habits});

  @override
  Widget build(BuildContext context) {
    final all = habits.todayHabits;
    if (all.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SectionHeader(title: "Today's Habits"),
              const SizedBox(height: 10),
              ListTile(
                leading: Icon(Icons.add_task_rounded, color: Theme.of(context).colorScheme.primary),
                title: const Text('No habits yet - add your first!'),
              ),
            ],
          ),
        ),
      );
    }

    final shown = all.take(4).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          children: [
            SectionHeader(
              title: "Today's Habits",
              trailing: TextButton(onPressed: () => context.go('/habits'), child: const Text('Open')),
            ),
            ...shown.map(
              (h) => ListTile(
                dense: true,
                leading: Icon(
                  h.isCompletedToday() ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: h.isCompletedToday() ? const Color(0xFFFF3B0A) : Colors.grey.shade400,
                  size: 22,
                ),
                title: Text(
                  h.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        decoration: h.isCompletedToday() ? TextDecoration.lineThrough : null,
                        color: h.isCompletedToday() ? Colors.grey.shade400 : null,
                      ),
                ),
                trailing: h.currentStreak > 0 ? _StreakChip(streak: h.currentStreak) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final List<Widget> children;

  const _DashboardPanel({
    required this.title,
    required this.actionLabel,
    required this.onAction,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SectionHeader(
              title: title,
              trailing: TextButton(onPressed: onAction, child: Text(actionLabel)),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _AlertRow({required this.icon, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      dense: true,
      leading: Icon(icon, color: const Color(0xFFFF3B0A)),
      title: Text(text),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
    );
  }
}

class _StreakChip extends StatelessWidget {
  final int streak;
  const _StreakChip({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3B0A).withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFFF3B0A).withOpacity(0.18)),
      ),
      child: Text(
        '$streak day',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFFF3B0A)),
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(icon: Icons.checklist_rounded, label: 'Log Habit', route: '/habits'),
      _QuickAction(icon: Icons.shopping_cart_rounded, label: 'Shopping', route: '/shopping'),
      _QuickAction(icon: Icons.inventory_2_rounded, label: 'Inventory', route: '/inventory'),
      _QuickAction(icon: Icons.receipt_long_rounded, label: 'Expense', route: '/expenses'),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SectionHeader(title: 'Quick Actions'),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.25,
              children: actions
                  .map(
                    (action) => InkWell(
                      onTap: () => context.go(action.route),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F4F4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE8E8E8)),
                        ),
                        child: Row(
                          children: [
                            Icon(action.icon, size: 20, color: const Color(0xFFFF3B0A)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(action.label, style: Theme.of(context).textTheme.titleSmall)),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final String route;

  const _QuickAction({required this.icon, required this.label, required this.route});
}
