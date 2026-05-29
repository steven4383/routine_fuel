import 'package:hive/hive.dart';

part 'inventory_model.g.dart';

@HiveType(typeId: 4)
enum UnitType {
  @HiveField(0)
  piece,
  @HiveField(1)
  kg,
  @HiveField(2)
  gram,
  @HiveField(3)
  litre,
  @HiveField(4)
  packet,
}

@HiveType(typeId: 5)
enum InventoryCategory {
  @HiveField(0)
  fruits,
  @HiveField(1)
  vegetables,
  @HiveField(2)
  protein,
  @HiveField(3)
  dairy,
  @HiveField(4)
  grains,
  @HiveField(5)
  supplements,
  @HiveField(6)
  other,
}

extension InventoryCategoryLabel on InventoryCategory {
  String get categoryLabel {
    switch (this) {
      case InventoryCategory.fruits:
        return 'Fruits';
      case InventoryCategory.vegetables:
        return 'Vegetables';
      case InventoryCategory.protein:
        return 'Protein';
      case InventoryCategory.dairy:
        return 'Dairy';
      case InventoryCategory.grains:
        return 'Grains';
      case InventoryCategory.supplements:
        return 'Supplements';
      case InventoryCategory.other:
        return 'Other';
    }
  }
}

@HiveType(typeId: 6)
class InventoryItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double quantity;

  @HiveField(3)
  UnitType unit;

  @HiveField(4)
  double minimumThreshold;

  @HiveField(5)
  double pricePerUnit;

  @HiveField(6)
  InventoryCategory category;

  @HiveField(7)
  DateTime updatedAt;

  InventoryItem({
    required this.id,
    required this.name,
    required this.quantity,
    this.unit = UnitType.piece,
    this.minimumThreshold = 2,
    this.pricePerUnit = 0,
    this.category = InventoryCategory.other,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  bool get isLowStock => quantity <= minimumThreshold;

  String get unitLabel {
    switch (unit) {
      case UnitType.piece:
        return 'pcs';
      case UnitType.kg:
        return 'kg';
      case UnitType.gram:
        return 'g';
      case UnitType.litre:
        return 'L';
      case UnitType.packet:
        return 'pkt';
    }
  }

  String get categoryLabel => category.categoryLabel;

  InventoryItem copyWith({
    String? id,
    String? name,
    double? quantity,
    UnitType? unit,
    double? minimumThreshold,
    double? pricePerUnit,
    InventoryCategory? category,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      minimumThreshold: minimumThreshold ?? this.minimumThreshold,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      category: category ?? this.category,
      updatedAt: DateTime.now(),
    );
  }
}
