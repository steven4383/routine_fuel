import '../models/habit_model.dart';
import '../providers/habit_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/shopping_provider.dart';

class CompletionResult {
  final bool success;
  final bool wasCompleted; // true = marked done, false = unmarked
  final List<String> insufficientItems;
  final List<String> deductedItems;

  const CompletionResult({
    required this.success,
    required this.wasCompleted,
    this.insufficientItems = const [],
    this.deductedItems = const [],
  });
}

class HabitCompletionService {
  final HabitProvider habitProvider;
  final InventoryProvider inventoryProvider;
  final ShoppingProvider shoppingProvider;

  HabitCompletionService({
    required this.habitProvider,
    required this.inventoryProvider,
    required this.shoppingProvider,
  });

  Future<CompletionResult> toggleHabit(String habitId) async {
    // Toggle in habit provider — returns linked items only when marking done
    final linkedItems = await habitProvider.toggleCompletion(habitId);

    final wasCompleted = linkedItems.isNotEmpty ||
        habitProvider.habits
            .firstWhere((h) => h.id == habitId,
                orElse: () => HabitModel(
                    id: '', title: '', createdAt: DateTime.now()))
            .isCompletedToday();

    if (linkedItems.isEmpty) {
      // Was unmarked — no inventory changes
      return const CompletionResult(success: true, wasCompleted: false);
    }

    // Deduct linked inventory items
    final insufficientItems = <String>[];
    final deductedItems = <String>[];

    for (final linked in linkedItems) {
      final item = inventoryProvider.getById(linked.inventoryItemId);
      if (item == null) continue;
      final success = await inventoryProvider.deductQuantity(
          linked.inventoryItemId, linked.quantity);
      if (!success) {
        insufficientItems.add(item.name);
      } else {
        deductedItems.add(item.name);
      }
    }

    // Sync shopping list with new low-stock state
    await shoppingProvider.syncFromInventory(inventoryProvider.lowStockItems);

    return CompletionResult(
      success: true,
      wasCompleted: true,
      insufficientItems: insufficientItems,
      deductedItems: deductedItems,
    );
  }
}
