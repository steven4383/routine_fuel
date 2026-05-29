import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/backup_service.dart';
import '../../providers/habit_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/shopping_provider.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/shared_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          // Appearance
          const SectionHeader(title: 'Appearance'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_rounded),
                  title: const Text('Dark Mode'),
                  value: settings.isDarkMode,
                  onChanged: (_) => settings.toggleDarkMode(),
                ),
              ],
            ),
          ),

          // Notifications
          const SectionHeader(title: 'Notifications'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.wb_sunny_rounded,
                      color: Colors.orange),
                  title: const Text('Morning Reminder'),
                  subtitle: Text(settings.settings.morningReminderTime),
                  value: settings.settings.morningReminderEnabled,
                  onChanged: (v) =>
                      settings.toggleMorningReminder(v),
                ),
                const Divider(height: 1, indent: 56),
                SwitchListTile(
                  secondary: const Icon(Icons.warning_amber_rounded,
                      color: Colors.orange),
                  title: const Text('Low Stock Alerts'),
                  subtitle: const Text('When stock falls below minimum'),
                  value: settings.settings.lowStockAlertEnabled,
                  onChanged: (v) => settings.toggleLowStockAlert(v),
                ),
                const Divider(height: 1, indent: 56),
                SwitchListTile(
                  secondary: const Icon(Icons.shopping_cart_rounded,
                      color: Colors.teal),
                  title: const Text('Shopping Reminder'),
                  subtitle: const Text('When list has 3+ items'),
                  value: settings.settings.shoppingReminderEnabled,
                  onChanged: (v) =>
                      settings.toggleShoppingReminder(v),
                ),
              ],
            ),
          ),

          // Budget
          const SectionHeader(title: 'Budget'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.green),
              title: const Text('Monthly Budget'),
              subtitle: Text(
                  '${settings.currencySymbol}${settings.monthlyBudget.toStringAsFixed(0)}'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14),
              onTap: () => _showBudgetDialog(context, settings),
            ),
          ),

          // Data & Backup
          const SectionHeader(title: 'Data & Backup'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.upload_rounded,
                      color: Colors.blue),
                  title: const Text('Export Backup'),
                  subtitle: const Text('Save all data as JSON'),
                  onTap: () => _exportBackup(context),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.download_rounded,
                      color: Colors.blue),
                  title: const Text('Import Backup'),
                  subtitle: const Text('Restore from JSON file'),
                  onTap: () => _importBackup(context),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading:
                      Icon(Icons.delete_forever_rounded,
                          color: Colors.red.shade600),
                  title: Text('Clear All Data',
                      style: TextStyle(color: Colors.red.shade600)),
                  subtitle: const Text('Permanently delete everything'),
                  onTap: () => _clearAll(context),
                ),
              ],
            ),
          ),

          // About
          const SectionHeader(title: 'About'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.info_outline_rounded),
                  title: const Text('RoutineFuel'),
                  subtitle: const Text('Version 1.0.0'),
                ),
                const Divider(height: 1, indent: 56),
                const ListTile(
                  leading: Icon(Icons.offline_bolt_rounded,
                      color: Colors.green),
                  title: Text('Offline First'),
                  subtitle: Text('All data stored locally on your device'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBudgetDialog(
      BuildContext context, SettingsProvider settings) {
    final ctrl = TextEditingController(
        text: settings.monthlyBudget.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Monthly Budget'),
        content: TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Budget amount',
            prefixText: settings.currencySymbol,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text);
              if (v != null && v > 0) {
                settings.setMonthlyBudget(v);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context) async {
    final service = _buildBackupService(context);
    final success = await service.exportBackup();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              success ? 'Backup exported successfully!' : 'Export failed'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Import Backup',
      message:
          'This will replace all current data. Are you sure?',
      confirmLabel: 'Import',
      confirmColor: Colors.blue,
    );
    if (!confirm) return;

    final service = _buildBackupService(context);
    final success = await service.importBackup();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              success ? 'Backup imported successfully!' : 'Import failed or cancelled'),
          backgroundColor: success ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  Future<void> _clearAll(BuildContext context) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Clear All Data',
      message:
          'This will permanently delete all habits, inventory, expenses, and shopping data. This cannot be undone.',
      confirmLabel: 'Clear Everything',
    );
    if (!confirm) return;

    final service = _buildBackupService(context);
    await service.clearAll();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data cleared')),
      );
    }
  }

  BackupService _buildBackupService(BuildContext context) {
    return BackupService(
      habitProvider: context.read<HabitProvider>(),
      inventoryProvider: context.read<InventoryProvider>(),
      shoppingProvider: context.read<ShoppingProvider>(),
      expenseProvider: context.read<ExpenseProvider>(),
      settingsProvider: context.read<SettingsProvider>(),
    );
  }
}
