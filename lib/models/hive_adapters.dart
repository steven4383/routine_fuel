// Hand-written Hive adapters — no build_runner required.
// These replace the .g.dart generated files.

import 'package:hive/hive.dart';
import 'habit_model.dart';
import 'inventory_model.dart';
import 'shopping_model.dart';
import 'expense_model.dart';
import 'settings_model.dart';

// ─── RepeatType (typeId: 0) ───────────────────────────────────────────────────

class RepeatTypeAdapter extends TypeAdapter<RepeatType> {
  @override
  final int typeId = 0;
  @override
  RepeatType read(BinaryReader reader) => RepeatType.values[reader.readByte()];
  @override
  void write(BinaryWriter writer, RepeatType obj) =>
      writer.writeByte(obj.index);
}

// ─── HabitCategory (typeId: 1) ────────────────────────────────────────────────

class HabitCategoryAdapter extends TypeAdapter<HabitCategory> {
  @override
  final int typeId = 1;
  @override
  HabitCategory read(BinaryReader reader) =>
      HabitCategory.values[reader.readByte()];
  @override
  void write(BinaryWriter writer, HabitCategory obj) =>
      writer.writeByte(obj.index);
}

// ─── LinkedInventoryItem (typeId: 2) ─────────────────────────────────────────

class LinkedInventoryItemAdapter extends TypeAdapter<LinkedInventoryItem> {
  @override
  final int typeId = 2;
  @override
  LinkedInventoryItem read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return LinkedInventoryItem(
      inventoryItemId: fields[0] as String,
      quantity: (fields[1] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, LinkedInventoryItem obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.inventoryItemId)
      ..writeByte(1)
      ..write(obj.quantity);
  }
}

// ─── HabitModel (typeId: 3) ───────────────────────────────────────────────────

class HabitModelAdapter extends TypeAdapter<HabitModel> {
  @override
  final int typeId = 3;
  @override
  HabitModel read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return HabitModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String? ?? '',
      category: fields[3] as HabitCategory,
      scheduledTime: fields[4] as String?,
      repeatType: fields[5] as RepeatType,
      linkedItems: (fields[6] as List).cast<LinkedInventoryItem>(),
      completionHistory: (fields[7] as List).cast<String>(),
      createdAt: fields[8] as DateTime,
      isActive: fields[9] as bool? ?? true,
    );
  }

  @override
  void write(BinaryWriter writer, HabitModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.scheduledTime)
      ..writeByte(5)
      ..write(obj.repeatType)
      ..writeByte(6)
      ..write(obj.linkedItems)
      ..writeByte(7)
      ..write(obj.completionHistory)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.isActive);
  }
}

// ─── UnitType (typeId: 4) ─────────────────────────────────────────────────────

class UnitTypeAdapter extends TypeAdapter<UnitType> {
  @override
  final int typeId = 4;
  @override
  UnitType read(BinaryReader reader) => UnitType.values[reader.readByte()];
  @override
  void write(BinaryWriter writer, UnitType obj) => writer.writeByte(obj.index);
}

// ─── InventoryCategory (typeId: 5) ────────────────────────────────────────────

class InventoryCategoryAdapter extends TypeAdapter<InventoryCategory> {
  @override
  final int typeId = 5;
  @override
  InventoryCategory read(BinaryReader reader) =>
      InventoryCategory.values[reader.readByte()];
  @override
  void write(BinaryWriter writer, InventoryCategory obj) =>
      writer.writeByte(obj.index);
}

// ─── InventoryItem (typeId: 6) ────────────────────────────────────────────────

class InventoryItemAdapter extends TypeAdapter<InventoryItem> {
  @override
  final int typeId = 6;
  @override
  InventoryItem read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return InventoryItem(
      id: fields[0] as String,
      name: fields[1] as String,
      quantity: (fields[2] as num).toDouble(),
      unit: fields[3] as UnitType,
      minimumThreshold: (fields[4] as num).toDouble(),
      pricePerUnit: (fields[5] as num).toDouble(),
      category: fields[6] as InventoryCategory,
      updatedAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, InventoryItem obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.unit)
      ..writeByte(4)
      ..write(obj.minimumThreshold)
      ..writeByte(5)
      ..write(obj.pricePerUnit)
      ..writeByte(6)
      ..write(obj.category)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }
}

// ─── ShoppingItem (typeId: 7) ─────────────────────────────────────────────────

class ShoppingItemAdapter extends TypeAdapter<ShoppingItem> {
  @override
  final int typeId = 7;
  @override
  ShoppingItem read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return ShoppingItem(
      id: fields[0] as String,
      name: fields[1] as String,
      quantityNeeded: (fields[2] as num).toDouble(),
      unit: fields[3] as String? ?? 'pcs',
      isAutoGenerated: fields[4] as bool? ?? false,
      isPurchased: fields[5] as bool? ?? false,
      linkedInventoryId: fields[6] as String?,
      createdAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ShoppingItem obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.quantityNeeded)
      ..writeByte(3)
      ..write(obj.unit)
      ..writeByte(4)
      ..write(obj.isAutoGenerated)
      ..writeByte(5)
      ..write(obj.isPurchased)
      ..writeByte(6)
      ..write(obj.linkedInventoryId)
      ..writeByte(7)
      ..write(obj.createdAt);
  }
}

// ─── ExpenseCategory (typeId: 8) ──────────────────────────────────────────────

class ExpenseCategoryAdapter extends TypeAdapter<ExpenseCategory> {
  @override
  final int typeId = 8;
  @override
  ExpenseCategory read(BinaryReader reader) =>
      ExpenseCategory.values[reader.readByte()];
  @override
  void write(BinaryWriter writer, ExpenseCategory obj) =>
      writer.writeByte(obj.index);
}

// ─── ExpenseModel (typeId: 9) ─────────────────────────────────────────────────

class ExpenseModelAdapter extends TypeAdapter<ExpenseModel> {
  @override
  final int typeId = 9;
  @override
  ExpenseModel read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return ExpenseModel(
      id: fields[0] as String,
      itemName: fields[1] as String,
      quantity: (fields[2] as num).toDouble(),
      totalAmount: (fields[3] as num).toDouble(),
      purchaseDate: fields[4] as DateTime,
      category: fields[5] as ExpenseCategory,
      notes: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ExpenseModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.itemName)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.totalAmount)
      ..writeByte(4)
      ..write(obj.purchaseDate)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.notes);
  }
}

// ─── AppSettings (typeId: 10) ─────────────────────────────────────────────────

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 10;
  @override
  AppSettings read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      isDarkMode: fields[0] as bool? ?? false,
      morningReminderEnabled: fields[1] as bool? ?? true,
      morningReminderTime: fields[2] as String? ?? '07:30',
      lowStockAlertEnabled: fields[3] as bool? ?? true,
      shoppingReminderEnabled: fields[4] as bool? ?? true,
      habitCompletionReminderEnabled: fields[5] as bool? ?? false,
      monthlyBudget: (fields[6] as num?)?.toDouble() ?? 4000,
      currencySymbol: fields[7] as String? ?? '₹',
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.isDarkMode)
      ..writeByte(1)
      ..write(obj.morningReminderEnabled)
      ..writeByte(2)
      ..write(obj.morningReminderTime)
      ..writeByte(3)
      ..write(obj.lowStockAlertEnabled)
      ..writeByte(4)
      ..write(obj.shoppingReminderEnabled)
      ..writeByte(5)
      ..write(obj.habitCompletionReminderEnabled)
      ..writeByte(6)
      ..write(obj.monthlyBudget)
      ..writeByte(7)
      ..write(obj.currencySymbol);
  }
}

/// Register all adapters. Call once in main() before Hive.openBox.
void registerHiveAdapters() {
  Hive
    ..registerAdapter(RepeatTypeAdapter())
    ..registerAdapter(HabitCategoryAdapter())
    ..registerAdapter(LinkedInventoryItemAdapter())
    ..registerAdapter(HabitModelAdapter())
    ..registerAdapter(UnitTypeAdapter())
    ..registerAdapter(InventoryCategoryAdapter())
    ..registerAdapter(InventoryItemAdapter())
    ..registerAdapter(ShoppingItemAdapter())
    ..registerAdapter(ExpenseCategoryAdapter())
    ..registerAdapter(ExpenseModelAdapter())
    ..registerAdapter(AppSettingsAdapter());
}
