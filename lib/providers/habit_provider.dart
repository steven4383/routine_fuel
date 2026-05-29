import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/habit_model.dart';

class HabitProvider extends ChangeNotifier {
  static const _boxName = 'habitsBox';
  late Box<HabitModel> _box;
  bool _initialized = false;

  List<HabitModel> get habits =>
      _box.values.where((h) => h.isActive).toList()
        ..sort((a, b) => a.category.index.compareTo(b.category.index));

  List<HabitModel> get todayHabits => habits;

  List<HabitModel> get completedToday =>
      habits.where((h) => h.isCompletedToday()).toList();

  List<HabitModel> get pendingToday =>
      habits.where((h) => !h.isCompletedToday()).toList();

  double get todayCompletionPercent {
    if (habits.isEmpty) return 0;
    return completedToday.length / habits.length;
  }

  List<HabitModel> byCategory(HabitCategory cat) =>
      habits.where((h) => h.category == cat).toList();

  Future<void> init() async {
    if (_initialized) return;
    _box = await Hive.openBox<HabitModel>(_boxName);
    _initialized = true;
    notifyListeners();
  }

  Future<void> addHabit(HabitModel habit) async {
    await _box.put(habit.id, habit);
    notifyListeners();
  }

  Future<void> updateHabit(HabitModel habit) async {
    await _box.put(habit.id, habit);
    notifyListeners();
  }

  Future<void> deleteHabit(String id) async {
    final habit = _box.get(id);
    if (habit != null) {
      habit.isActive = false;
      await _box.put(id, habit);
    }
    notifyListeners();
  }

  /// Returns the list of linked items for downstream inventory deduction.
  Future<List<LinkedInventoryItem>> toggleCompletion(String id) async {
    final habit = _box.get(id);
    if (habit == null) return [];
    final today = DateTime.now();
    List<LinkedInventoryItem> deductions = [];
    if (habit.isCompletedToday()) {
      habit.unmarkCompleted(today);
    } else {
      habit.markCompleted(today);
      deductions = List.from(habit.linkedItems);
    }
    await _box.put(id, habit);
    notifyListeners();
    return deductions;
  }

  HabitModel createHabit({
    required String title,
    String description = '',
    HabitCategory category = HabitCategory.anytime,
    String? scheduledTime,
    RepeatType repeatType = RepeatType.daily,
    List<LinkedInventoryItem>? linkedItems,
  }) {
    return HabitModel(
      id: const Uuid().v4(),
      title: title,
      description: description,
      category: category,
      scheduledTime: scheduledTime,
      repeatType: repeatType,
      linkedItems: linkedItems ?? [],
    );
  }

  // Analytics helpers
  Map<String, double> weeklyCompletionRate() {
    final result = <String, double>{};
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final key =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final shortKey =
          ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day.weekday - 1];
      if (habits.isEmpty) {
        result[shortKey] = 0;
      } else {
        final completed =
            habits.where((h) => h.completionHistory.contains(key)).length;
        result[shortKey] = completed / habits.length;
      }
    }
    return result;
  }

  Future<Map<String, dynamic>> exportData() async {
    return {
      'habits': _box.values
          .map((h) => {
                'id': h.id,
                'title': h.title,
                'description': h.description,
                'category': h.category.index,
                'scheduledTime': h.scheduledTime,
                'repeatType': h.repeatType.index,
                'linkedItems': h.linkedItems
                    .map((l) => {
                          'inventoryItemId': l.inventoryItemId,
                          'quantity': l.quantity,
                        })
                    .toList(),
                'completionHistory': h.completionHistory,
                'createdAt': h.createdAt.toIso8601String(),
                'isActive': h.isActive,
              })
          .toList(),
    };
  }

  Future<void> importData(List<dynamic> data) async {
    await _box.clear();
    for (final item in data) {
      final habit = HabitModel(
        id: item['id'],
        title: item['title'],
        description: item['description'] ?? '',
        category: HabitCategory.values[item['category'] ?? 3],
        scheduledTime: item['scheduledTime'],
        repeatType: RepeatType.values[item['repeatType'] ?? 0],
        linkedItems: (item['linkedItems'] as List? ?? [])
            .map((l) => LinkedInventoryItem(
                  inventoryItemId: l['inventoryItemId'],
                  quantity: (l['quantity'] as num).toDouble(),
                ))
            .toList(),
        completionHistory: List<String>.from(item['completionHistory'] ?? []),
        createdAt: DateTime.parse(item['createdAt']),
        isActive: item['isActive'] ?? true,
      );
      await _box.put(habit.id, habit);
    }
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _box.clear();
    notifyListeners();
  }
}
