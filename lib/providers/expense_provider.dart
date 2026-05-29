import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/expense_model.dart';

class ExpenseProvider extends ChangeNotifier {
  static const _boxName = 'expensesBox';
  late Box<ExpenseModel> _box;
  bool _initialized = false;

  List<ExpenseModel> get expenses => _box.values.toList()
    ..sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));

  Future<void> init() async {
    if (_initialized) return;
    _box = await Hive.openBox<ExpenseModel>(_boxName);
    _initialized = true;
    notifyListeners();
  }

  Future<void> addExpense(ExpenseModel expense) async {
    await _box.put(expense.id, expense);
    notifyListeners();
  }

  Future<void> deleteExpense(String id) async {
    await _box.delete(id);
    notifyListeners();
  }

  double get todayTotal {
    final today = DateTime.now();
    return expenses
        .where((e) =>
            e.purchaseDate.year == today.year &&
            e.purchaseDate.month == today.month &&
            e.purchaseDate.day == today.day)
        .fold(0, (sum, e) => sum + e.totalAmount);
  }

  double get monthTotal {
    final now = DateTime.now();
    return monthTotalFor(now.year, now.month);
  }

  double monthTotalFor(int year, int month) {
    return expenses
        .where(
            (e) => e.purchaseDate.year == year && e.purchaseDate.month == month)
        .fold(0, (sum, e) => sum + e.totalAmount);
  }

  Map<ExpenseCategory, double> monthCategoryBreakdown() {
    final now = DateTime.now();
    final result = <ExpenseCategory, double>{};
    for (final cat in ExpenseCategory.values) {
      result[cat] = expenses
          .where((e) =>
              e.purchaseDate.year == now.year &&
              e.purchaseDate.month == now.month &&
              e.category == cat)
          .fold(0, (sum, e) => sum + e.totalAmount);
    }
    return result;
  }

  List<ExpenseModel> expensesForMonth(int year, int month) {
    return expenses
        .where(
            (e) => e.purchaseDate.year == year && e.purchaseDate.month == month)
        .toList();
  }

  /// Returns spending per day for the current month (day number → amount).
  Map<int, double> dailySpendingThisMonth() {
    final now = DateTime.now();
    final result = <int, double>{};
    final monthExpenses = expensesForMonth(now.year, now.month);
    for (final e in monthExpenses) {
      result[e.purchaseDate.day] =
          (result[e.purchaseDate.day] ?? 0) + e.totalAmount;
    }
    return result;
  }

  ExpenseModel createExpense({
    required String itemName,
    required double quantity,
    required double totalAmount,
    ExpenseCategory category = ExpenseCategory.other,
    String? notes,
  }) {
    return ExpenseModel(
      id: const Uuid().v4(),
      itemName: itemName,
      quantity: quantity,
      totalAmount: totalAmount,
      category: category,
      notes: notes,
    );
  }

  Future<Map<String, dynamic>> exportData() async {
    return {
      'expenses': _box.values
          .map((e) => {
                'id': e.id,
                'itemName': e.itemName,
                'quantity': e.quantity,
                'totalAmount': e.totalAmount,
                'purchaseDate': e.purchaseDate.toIso8601String(),
                'category': e.category.index,
                'notes': e.notes,
              })
          .toList(),
    };
  }

  Future<void> importData(List<dynamic> data) async {
    await _box.clear();
    for (final item in data) {
      final e = ExpenseModel(
        id: item['id'],
        itemName: item['itemName'],
        quantity: (item['quantity'] as num).toDouble(),
        totalAmount: (item['totalAmount'] as num).toDouble(),
        purchaseDate: DateTime.parse(item['purchaseDate']),
        category: ExpenseCategory.values[item['category'] ?? 6],
        notes: item['notes'],
      );
      await _box.put(e.id, e);
    }
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _box.clear();
    notifyListeners();
  }
}
