import 'package:hive/hive.dart';

part 'habit_model.g.dart';

@HiveType(typeId: 0)
enum RepeatType {
  @HiveField(0)
  daily,
  @HiveField(1)
  weekly,
  @HiveField(2)
  none,
}

@HiveType(typeId: 1)
enum HabitCategory {
  @HiveField(0)
  morning,
  @HiveField(1)
  afternoon,
  @HiveField(2)
  evening,
  @HiveField(3)
  anytime,
}

@HiveType(typeId: 2)
class LinkedInventoryItem extends HiveObject {
  @HiveField(0)
  String inventoryItemId;

  @HiveField(1)
  double quantity;

  LinkedInventoryItem({
    required this.inventoryItemId,
    required this.quantity,
  });
}

@HiveType(typeId: 3)
class HabitModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  HabitCategory category;

  @HiveField(4)
  String? scheduledTime; // "HH:mm" format

  @HiveField(5)
  RepeatType repeatType;

  @HiveField(6)
  List<LinkedInventoryItem> linkedItems;

  @HiveField(7)
  List<String> completionHistory; // ISO date strings "yyyy-MM-dd"

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  bool isActive;

  HabitModel({
    required this.id,
    required this.title,
    this.description = '',
    this.category = HabitCategory.anytime,
    this.scheduledTime,
    this.repeatType = RepeatType.daily,
    List<LinkedInventoryItem>? linkedItems,
    List<String>? completionHistory,
    DateTime? createdAt,
    this.isActive = true,
  })  : linkedItems = linkedItems ?? [],
        completionHistory = completionHistory ?? [],
        createdAt = createdAt ?? DateTime.now();

  bool isCompletedToday() {
    final today = _dateKey(DateTime.now());
    return completionHistory.contains(today);
  }

  void markCompleted(DateTime date) {
    final key = _dateKey(date);
    if (!completionHistory.contains(key)) {
      completionHistory.add(key);
    }
  }

  void unmarkCompleted(DateTime date) {
    final key = _dateKey(date);
    completionHistory.remove(key);
  }

  int get currentStreak {
    if (completionHistory.isEmpty) return 0;
    int streak = 0;
    DateTime day = DateTime.now();
    while (true) {
      if (completionHistory.contains(_dateKey(day))) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  HabitModel copyWith({
    String? id,
    String? title,
    String? description,
    HabitCategory? category,
    String? scheduledTime,
    RepeatType? repeatType,
    List<LinkedInventoryItem>? linkedItems,
    List<String>? completionHistory,
    bool? isActive,
  }) {
    return HabitModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      repeatType: repeatType ?? this.repeatType,
      linkedItems: linkedItems ?? this.linkedItems,
      completionHistory: completionHistory ?? this.completionHistory,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
