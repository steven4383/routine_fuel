import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/inventory_model.dart';

class InventoryProvider extends ChangeNotifier {
  static const _boxName = 'inventoryBox';
  late Box<InventoryItem> _box;
  bool _initialized = false;

  List<InventoryItem> get items =>
      _box.values.toList()..sort((a, b) => a.name.compareTo(b.name));

  List<InventoryItem> get lowStockItems =>
      items.where((i) => i.isLowStock).toList();

  List<InventoryItem> byCategory(InventoryCategory cat) =>
      items.where((i) => i.category == cat).toList();

  InventoryItem? getById(String id) => _box.get(id);

  Future<void> init() async {
    if (_initialized) return;
    _box = await Hive.openBox<InventoryItem>(_boxName);
    _initialized = true;
    notifyListeners();
  }

  Future<void> addItem(InventoryItem item) async {
    await _box.put(item.id, item);
    notifyListeners();
  }

  Future<void> updateItem(InventoryItem item) async {
    final updated = item.copyWith();
    await _box.put(item.id, updated);
    notifyListeners();
  }

  Future<void> deleteItem(String id) async {
    await _box.delete(id);
    notifyListeners();
  }

  /// Deducts quantity. Returns true if stock was sufficient, false otherwise.
  Future<bool> deductQuantity(String itemId, double amount) async {
    final item = _box.get(itemId);
    if (item == null) return false;
    if (item.quantity < amount) {
      // Deduct whatever is available but warn caller
      item.quantity = 0;
      await _box.put(itemId, item);
      notifyListeners();
      return false;
    }
    item.quantity = (item.quantity - amount);
    item.updatedAt = DateTime.now();
    await _box.put(itemId, item);
    notifyListeners();
    return true;
  }

  Future<void> restoreQuantity(String itemId, double amount) async {
    final item = _box.get(itemId);
    if (item == null) return;
    item.quantity = item.quantity + amount;
    item.updatedAt = DateTime.now();
    await _box.put(itemId, item);
    notifyListeners();
  }

  InventoryItem createItem({
    required String name,
    required double quantity,
    UnitType unit = UnitType.piece,
    double minimumThreshold = 2,
    double pricePerUnit = 0,
    InventoryCategory category = InventoryCategory.other,
  }) {
    return InventoryItem(
      id: const Uuid().v4(),
      name: name,
      quantity: quantity,
      unit: unit,
      minimumThreshold: minimumThreshold,
      pricePerUnit: pricePerUnit,
      category: category,
    );
  }

  bool hasDuplicate(String name, {String? excludeId}) {
    return items.any((i) =>
        i.name.toLowerCase() == name.toLowerCase() && i.id != excludeId);
  }

  Future<Map<String, dynamic>> exportData() async {
    return {
      'inventory': _box.values
          .map((i) => {
                'id': i.id,
                'name': i.name,
                'quantity': i.quantity,
                'unit': i.unit.index,
                'minimumThreshold': i.minimumThreshold,
                'pricePerUnit': i.pricePerUnit,
                'category': i.category.index,
                'updatedAt': i.updatedAt.toIso8601String(),
              })
          .toList(),
    };
  }

  Future<void> importData(List<dynamic> data) async {
    await _box.clear();
    for (final item in data) {
      final inv = InventoryItem(
        id: item['id'],
        name: item['name'],
        quantity: (item['quantity'] as num).toDouble(),
        unit: UnitType.values[item['unit'] ?? 0],
        minimumThreshold: (item['minimumThreshold'] as num).toDouble(),
        pricePerUnit: (item['pricePerUnit'] as num).toDouble(),
        category: InventoryCategory.values[item['category'] ?? 6],
        updatedAt: DateTime.parse(item['updatedAt']),
      );
      await _box.put(inv.id, inv);
    }
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _box.clear();
    notifyListeners();
  }
}
