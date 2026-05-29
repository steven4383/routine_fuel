import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../models/inventory_model.dart';
import '../models/habit_model.dart';

class AppUtils {
  // ─── Date helpers ────────────────────────────────────────────────────────────

  static String formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static String formatMonthYear(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  static String formatTime(String? time) {
    if (time == null) return '';
    final parts = time.split(':');
    if (parts.length != 2) return time;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1].padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // ─── Currency ────────────────────────────────────────────────────────────────

  static String formatAmount(double amount, String symbol) {
    if (amount >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}k';
    }
    return '$symbol${amount.toStringAsFixed(0)}';
  }

  static String formatAmountFull(double amount, String symbol) {
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  // ─── Category colors ─────────────────────────────────────────────────────────

  static Color categoryColor(InventoryCategory cat, BuildContext context) {
    switch (cat) {
      case InventoryCategory.fruits:
        return Colors.orange;
      case InventoryCategory.vegetables:
        return Colors.green;
      case InventoryCategory.protein:
        return Colors.red.shade400;
      case InventoryCategory.dairy:
        return Colors.blue.shade300;
      case InventoryCategory.grains:
        return Colors.amber.shade700;
      case InventoryCategory.supplements:
        return Colors.purple.shade400;
      case InventoryCategory.other:
        return Colors.grey;
    }
  }

  static Color expenseCategoryColor(ExpenseCategory cat) {
    switch (cat) {
      case ExpenseCategory.fruits:
        return Colors.orange;
      case ExpenseCategory.vegetables:
        return Colors.green;
      case ExpenseCategory.protein:
        return Colors.red.shade400;
      case ExpenseCategory.dairy:
        return Colors.blue.shade300;
      case ExpenseCategory.supplements:
        return Colors.purple.shade400;
      case ExpenseCategory.grains:
        return Colors.amber.shade700;
      case ExpenseCategory.other:
        return Colors.grey;
    }
  }

  static IconData categoryIcon(InventoryCategory cat) {
    switch (cat) {
      case InventoryCategory.fruits:
        return Icons.apple_rounded;
      case InventoryCategory.vegetables:
        return Icons.eco_rounded;
      case InventoryCategory.protein:
        return Icons.set_meal_rounded;
      case InventoryCategory.dairy:
        return Icons.water_drop_rounded;
      case InventoryCategory.grains:
        return Icons.grain_rounded;
      case InventoryCategory.supplements:
        return Icons.medication_rounded;
      case InventoryCategory.other:
        return Icons.category_rounded;
    }
  }

  static Color habitCategoryColor(HabitCategory cat) {
    switch (cat) {
      case HabitCategory.morning:
        return Colors.orange.shade600;
      case HabitCategory.afternoon:
        return Colors.blue.shade400;
      case HabitCategory.evening:
        return Colors.indigo.shade400;
      case HabitCategory.anytime:
        return Colors.teal.shade500;
    }
  }

  static IconData habitCategoryIcon(HabitCategory cat) {
    switch (cat) {
      case HabitCategory.morning:
        return Icons.wb_sunny_rounded;
      case HabitCategory.afternoon:
        return Icons.wb_cloudy_rounded;
      case HabitCategory.evening:
        return Icons.nights_stay_rounded;
      case HabitCategory.anytime:
        return Icons.access_time_rounded;
    }
  }

  // ─── Stock status ─────────────────────────────────────────────────────────────

  static Color stockStatusColor(bool isLow) =>
      isLow ? Colors.red.shade600 : Colors.green.shade600;

  static double stockPercent(double quantity, double threshold) {
    if (quantity <= 0) return 0;
    final max = threshold * 4;
    return (quantity / max).clamp(0.0, 1.0);
  }

  // ─── Validation ──────────────────────────────────────────────────────────────

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validatePositiveNumber(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final num = double.tryParse(value);
    if (num == null || num <= 0) {
      return '$fieldName must be greater than 0';
    }
    return null;
  }
}
