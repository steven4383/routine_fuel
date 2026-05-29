import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/habit_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/expense_provider.dart';
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
    final colorScheme = Theme.of(context).colorScheme;

    final completionPercent = habits.todayCompletionPercent;
    final lowStockItems = inventory.lowStockItems;
    final monthSpend = expenses.monthTotal;
    final budget = settings.monthlyBudget;
    final symbol = settings.currencySymbol;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            expandedHeight: 80,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppUtils.greeting(),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            AppUtils.formatDate(DateTime.now()),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    _CompletionRing(percent: completionPercent),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Today's habits summary
                const SectionHeader(title: "Today's Habits"),
                _TodayHabitsCard(habits: habits),

                // Low stock alerts
                if (lowStockItems.isNotEmpty) ...[
                  SectionHeader(
                    title: 'Low Stock Alerts',
                    trailing: TextButton(onPressed: () => context.go('/inventory'), child: const Text('View all')),
                  ),
                  ...lowStockItems
                      .take(3)
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: AlertBanner(
                            message:
                                '${item.name}: ${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} ${item.unitLabel} left (min: ${item.minimumThreshold.toInt()})',
                            color: Colors.orange.shade700,
                            icon: Icons.warning_amber_rounded,
                            onTap: () => context.go('/inventory'),
                          ),
                        ),
                      ),
                ],

                // Monthly spending
                const SectionHeader(title: 'Monthly Budget'),
                ProgressCard(
                  label: AppUtils.formatMonthYear(DateTime.now()),
                  value: budget > 0 ? (monthSpend / budget).clamp(0, 1) : 0,
                  subtitle:
                      '${AppUtils.formatAmountFull(monthSpend, symbol)} of ${AppUtils.formatAmountFull(budget, symbol)}',
                  color: monthSpend > budget * 0.9 ? Colors.red.shade600 : Colors.green.shade600,
                ),

                // Quick actions
                const SectionHeader(title: 'Quick Actions'),
                _QuickActionsGrid(),

                // Shopping list summary
                if (shopping.pending.isNotEmpty) ...[
                  SectionHeader(
                    title: 'Shopping List',
                    trailing: TextButton(onPressed: () => context.go('/shopping'), child: const Text('View all')),
                  ),
                  AlertBanner(
                    message:
                        '${shopping.pending.length} item${shopping.pending.length > 1 ? 's' : ''} waiting to be purchased',
                    color: colorScheme.secondary,
                    icon: Icons.shopping_cart_rounded,
                    onTap: () => context.go('/shopping'),
                  ),
                ],

                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionRing extends StatelessWidget {
  final double percent;
  const _CompletionRing({required this.percent});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: percent,
            strokeWidth: 7,
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation(color),
            strokeCap: StrokeCap.round,
          ),
          Text(
            '${(percent * 100).toInt()}%',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: color),
          ),
        ],
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
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.add_task_rounded, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                'No habits yet — add your first!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }
    final shown = all.take(4).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            ...shown.map(
              (h) => ListTile(
                dense: true,
                leading: Icon(
                  h.isCompletedToday() ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: h.isCompletedToday() ? Colors.green.shade600 : Colors.grey.shade400,
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
            if (all.length > 4)
              TextButton(
                onPressed: () => context.go('/habits'),
                child: Text('+ ${all.length - 4} more habit${all.length - 4 > 1 ? 's' : ''}'),
              ),
          ],
        ),
      ),
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
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Text(
        '🔥 $streak',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange.shade800),
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(icon: Icons.checklist_rounded, label: 'Log Habit', color: Colors.green.shade600, route: '/habits'),
      _QuickAction(
        icon: Icons.shopping_cart_rounded,
        label: 'Shopping',
        color: Colors.orange.shade600,
        route: '/shopping',
      ),
      _QuickAction(
        icon: Icons.inventory_2_rounded,
        label: 'Inventory',
        color: Colors.teal.shade600,
        route: '/inventory',
      ),
      _QuickAction(
        icon: Icons.receipt_long_rounded,
        label: 'Add Expense',
        color: Colors.blue.shade600,
        route: '/expenses',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      // mainAxisSpacing: 8,
      childAspectRatio: 2.0,

      children: actions
          .map(
            (a) => SizedBox(
              height: 20,
              child: Card(
                child: InkWell(
                  onTap: () => context.go(a.route),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(a.icon, size: 20, color: a.color),
                      const SizedBox(width: 10),
                      Text(a.label, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: a.color)),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final String route;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.route});
}
