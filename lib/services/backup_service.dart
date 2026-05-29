import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/habit_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/shopping_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';

class BackupService {
  final HabitProvider habitProvider;
  final InventoryProvider inventoryProvider;
  final ShoppingProvider shoppingProvider;
  final ExpenseProvider expenseProvider;
  final SettingsProvider settingsProvider;

  BackupService({
    required this.habitProvider,
    required this.inventoryProvider,
    required this.shoppingProvider,
    required this.expenseProvider,
    required this.settingsProvider,
  });

  Future<bool> exportBackup() async {
    try {
      final habitData = await habitProvider.exportData();
      final inventoryData = await inventoryProvider.exportData();
      final shoppingData = await shoppingProvider.exportData();
      final expenseData = await expenseProvider.exportData();
      final settingsData = settingsProvider.exportData();

      final backup = {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        ...habitData,
        ...inventoryData,
        ...shoppingData,
        ...expenseData,
        ...settingsData,
      };

      final json = const JsonEncoder.withIndent('  ').convert(backup);
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-')
          .substring(0, 19);
      final file = File('${dir.path}/routinefuel_backup_$timestamp.json');
      await file.writeAsString(json);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'RoutineFuel Backup',
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return false;

      final path = result.files.first.path;
      if (path == null) return false;

      final content = await File(path).readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      if (data['habits'] != null) {
        await habitProvider.importData(data['habits'] as List);
      }
      if (data['inventory'] != null) {
        await inventoryProvider.importData(data['inventory'] as List);
      }
      if (data['shopping'] != null) {
        await shoppingProvider.importData(data['shopping'] as List);
      }
      if (data['expenses'] != null) {
        await expenseProvider.importData(data['expenses'] as List);
      }
      if (data['settings'] != null) {
        await settingsProvider.importData(data['settings'] as Map<String, dynamic>);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> clearAll() async {
    await habitProvider.clearAll();
    await inventoryProvider.clearAll();
    await shoppingProvider.clearAll();
    await expenseProvider.clearAll();
    await settingsProvider.clearAll();
  }
}
