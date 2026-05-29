import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/habit_model.dart';
import '../../providers/habit_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/shopping_provider.dart';
import '../../services/habit_completion_service.dart';
import '../../utils/app_utils.dart';
import '../../widgets/shared_widgets.dart';
import 'add_edit_habit_sheet.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Tracker'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: () => _showAddSheet(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add'),
            ),
          ),
        ],
      ),
      body: habitProvider.habits.isEmpty
          ? EmptyState(
              icon: Icons.checklist_rounded,
              title: 'No habits yet',
              subtitle: 'Add your first habit to start tracking your routine.',
              actionLabel: 'Add Habit',
              onAction: () => _showAddSheet(context),
            )
          : _HabitList(),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const AddEditHabitSheet(),
    );
  }
}

class _HabitList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();
    final categories = HabitCategory.values;

    // Build weekly stats bar
    final stats = habitProvider.weeklyCompletionRate();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        // Weekly overview card
        _WeeklyOverviewCard(stats: stats),

        // Habits grouped by category
        ...categories.map((cat) {
          final catHabits = habitProvider.byCategory(cat);
          if (catHabits.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: _categoryLabel(cat),
                trailing: Icon(
                  AppUtils.habitCategoryIcon(cat),
                  size: 16,
                  color: AppUtils.habitCategoryColor(cat),
                ),
              ),
              ...catHabits.map((h) => _HabitCard(habit: h)),
            ],
          );
        }),
      ],
    );
  }

  String _categoryLabel(HabitCategory cat) {
    switch (cat) {
      case HabitCategory.morning:
        return 'Morning';
      case HabitCategory.afternoon:
        return 'Afternoon';
      case HabitCategory.evening:
        return 'Evening';
      case HabitCategory.anytime:
        return 'Anytime';
    }
  }
}

class _WeeklyOverviewCard extends StatelessWidget {
  final Map<String, double> stats;
  const _WeeklyOverviewCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This Week',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: stats.entries.map((e) {
                final isToday = e.key ==
                    ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                        [DateTime.now().weekday - 1];
                return Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: e.value >= 1.0
                            ? color
                            : e.value > 0
                                ? color.withOpacity(0.35)
                                : color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: isToday
                            ? Border.all(color: color, width: 2)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        e.value > 0 ? '${(e.value * 100).toInt()}' : '—',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: e.value > 0 ? Colors.white : color.withOpacity(0.4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(e.key,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isToday ? color : null,
                              fontWeight: isToday ? FontWeight.w700 : null,
                            )),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitCard extends StatefulWidget {
  final HabitModel habit;
  const _HabitCard({required this.habit});

  @override
  State<_HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<_HabitCard> {
  bool _loading = false;

  Future<void> _toggle() async {
    if (_loading) return;
    setState(() => _loading = true);

    final service = HabitCompletionService(
      habitProvider: context.read<HabitProvider>(),
      inventoryProvider: context.read<InventoryProvider>(),
      shoppingProvider: context.read<ShoppingProvider>(),
    );

    final result = await service.toggleHabit(widget.habit.id);

    if (mounted) {
      setState(() => _loading = false);
      if (result.wasCompleted && result.deductedItems.isNotEmpty) {
        _showDeductionSnackBar(result.deductedItems, result.insufficientItems);
      }
      if (result.insufficientItems.isNotEmpty) {
        _showInsufficientStockDialog(result.insufficientItems);
      }
    }
  }

  void _showDeductionSnackBar(List<String> deducted, List<String> insufficient) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Inventory updated: ${deducted.join(', ')}'),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showInsufficientStockDialog(List<String> items) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 8),
          Text('Low Stock Warning'),
        ]),
        content: Text(
            'Insufficient stock for: ${items.join(', ')}.\n\nAdded to your shopping list.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK')),
        ],
      ),
    );
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Edit Habit'),
              onTap: () {
                Navigator.pop(ctx);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => AddEditHabitSheet(habit: widget.habit),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_rounded, color: Colors.red.shade600),
              title: Text('Delete Habit',
                  style: TextStyle(color: Colors.red.shade600)),
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await showConfirmDialog(
                  context,
                  title: 'Delete Habit',
                  message:
                      'Delete "${widget.habit.title}"? This cannot be undone.',
                );
                if (confirm && mounted) {
                  context.read<HabitProvider>().deleteHabit(widget.habit.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habit = widget.habit;
    final isDone = habit.isCompletedToday();
    final colorScheme = Theme.of(context).colorScheme;
    final catColor = AppUtils.habitCategoryColor(habit.category);

    return Card(
      child: InkWell(
        onLongPress: _showOptions,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Completion toggle
              GestureDetector(
                onTap: _toggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDone
                        ? Colors.green.shade600
                        : Colors.transparent,
                    border: Border.all(
                      color: isDone
                          ? Colors.green.shade600
                          : Colors.grey.shade400,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _loading
                      ? Padding(
                          padding: const EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: isDone ? Colors.white : colorScheme.primary),
                        )
                      : isDone
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 20)
                          : null,
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : null,
                            color: isDone ? Colors.grey.shade400 : null,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (habit.scheduledTime != null) ...[
                          Icon(Icons.access_time_rounded,
                              size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 3),
                          Text(AppUtils.formatTime(habit.scheduledTime),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey.shade500)),
                          const SizedBox(width: 8),
                        ],
                        if (habit.linkedItems.isNotEmpty) ...[
                          Icon(Icons.inventory_2_rounded,
                              size: 12, color: Colors.teal.shade400),
                          const SizedBox(width: 3),
                          Text('${habit.linkedItems.length} items linked',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.teal.shade400)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Streak
              if (habit.currentStreak > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('🔥 ${habit.currentStreak}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.orange.shade800)),
                ),

              const SizedBox(width: 6),
              Icon(Icons.more_vert_rounded,
                  size: 18, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
