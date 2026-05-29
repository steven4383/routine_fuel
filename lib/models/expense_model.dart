import 'package:hive/hive.dart';

part 'expense_model.g.dart';

@HiveType(typeId: 8)
enum ExpenseCategory {
  @HiveField(0)
  fruits,
  @HiveField(1)
  vegetables,
  @HiveField(2)
  protein,
  @HiveField(3)
  dairy,
  @HiveField(4)
  supplements,
  @HiveField(5)
  grains,
  @HiveField(6)
  other,
}

extension ExpenseCategoryLabel on ExpenseCategory {
  String get categoryLabel {
    switch (this) {
      case ExpenseCategory.fruits:
        return 'Fruits';
      case ExpenseCategory.vegetables:
        return 'Vegetables';
      case ExpenseCategory.protein:
        return 'Protein';
      case ExpenseCategory.dairy:
        return 'Dairy';
      case ExpenseCategory.supplements:
        return 'Supplements';
      case ExpenseCategory.grains:
        return 'Grains';
      case ExpenseCategory.other:
        return 'Other';
    }
  }
}

@HiveType(typeId: 9)
class ExpenseModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String itemName;

  @HiveField(2)
  double quantity;

  @HiveField(3)
  double totalAmount;

  @HiveField(4)
  DateTime purchaseDate;

  @HiveField(5)
  ExpenseCategory category;

  @HiveField(6)
  String? notes;

  ExpenseModel({
    required this.id,
    required this.itemName,
    required this.quantity,
    required this.totalAmount,
    DateTime? purchaseDate,
    this.category = ExpenseCategory.other,
    this.notes,
  }) : purchaseDate = purchaseDate ?? DateTime.now();

  String get categoryLabel => category.categoryLabel;

  ExpenseModel copyWith({
    String? id,
    String? itemName,
    double? quantity,
    double? totalAmount,
    DateTime? purchaseDate,
    ExpenseCategory? category,
    String? notes,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      totalAmount: totalAmount ?? this.totalAmount,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      category: category ?? this.category,
      notes: notes ?? this.notes,
    );
  }
}
