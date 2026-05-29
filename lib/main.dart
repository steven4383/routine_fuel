import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'models/hive_adapters.dart';
import 'models/habit_model.dart';
import 'models/inventory_model.dart';
import 'models/shopping_model.dart';
import 'models/expense_model.dart';
import 'models/settings_model.dart';
import 'providers/habit_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/shopping_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/settings_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register all adapters (no build_runner needed)
  registerHiveAdapters();

  // Initialize providers (open Hive boxes)
  final habitProvider = HabitProvider();
  final inventoryProvider = InventoryProvider();
  final shoppingProvider = ShoppingProvider();
  final expenseProvider = ExpenseProvider();
  final settingsProvider = SettingsProvider();

  await Future.wait([
    habitProvider.init(),
    inventoryProvider.init(),
    shoppingProvider.init(),
    expenseProvider.init(),
    settingsProvider.init(),
  ]);

  // Sync shopping list on startup
  await shoppingProvider.syncFromInventory(inventoryProvider.lowStockItems);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: habitProvider),
        ChangeNotifierProvider.value(value: inventoryProvider),
        ChangeNotifierProvider.value(value: shoppingProvider),
        ChangeNotifierProvider.value(value: expenseProvider),
        ChangeNotifierProvider.value(value: settingsProvider),
      ],
      child: const RoutineFuelApp(),
    ),
  );
}

class RoutineFuelApp extends StatelessWidget {
  const RoutineFuelApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return ShadApp.custom(
      themeMode: settings.themeMode,
      theme: AppTheme.shadLightTheme(),
      darkTheme: AppTheme.shadDarkTheme(),
      appBuilder: (context) => MaterialApp.router(
        title: 'RoutineFuel',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: settings.themeMode,
        routerConfig: appRouter,
        localizationsDelegates: const [GlobalShadLocalizations.delegate],
        builder: (context, child) => ShadAppBuilder(child: child!),
      ),
    );
  }
}
