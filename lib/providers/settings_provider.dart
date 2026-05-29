import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/settings_model.dart';

class SettingsProvider extends ChangeNotifier {
  static const _boxName = 'settingsBox';
  static const _settingsKey = 'app_settings';
  late Box<AppSettings> _box;
  late AppSettings _settings;
  bool _initialized = false;

  AppSettings get settings => _settings;
  bool get isDarkMode => _settings.isDarkMode;
  ThemeMode get themeMode =>
      _settings.isDarkMode ? ThemeMode.dark : ThemeMode.light;
  double get monthlyBudget => _settings.monthlyBudget;
  String get currencySymbol => _settings.currencySymbol;

  Future<void> init() async {
    if (_initialized) return;
    _box = await Hive.openBox<AppSettings>(_boxName);
    _settings = _box.get(_settingsKey) ?? AppSettings();
    _initialized = true;
    notifyListeners();
  }

  Future<void> _save() async {
    await _box.put(_settingsKey, _settings);
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _settings.isDarkMode = !_settings.isDarkMode;
    await _save();
  }

  Future<void> setDarkMode(bool value) async {
    _settings.isDarkMode = value;
    await _save();
  }

  Future<void> toggleMorningReminder(bool value) async {
    _settings.morningReminderEnabled = value;
    await _save();
  }

  Future<void> toggleLowStockAlert(bool value) async {
    _settings.lowStockAlertEnabled = value;
    await _save();
  }

  Future<void> toggleShoppingReminder(bool value) async {
    _settings.shoppingReminderEnabled = value;
    await _save();
  }

  Future<void> setMorningReminderTime(String time) async {
    _settings.morningReminderTime = time;
    await _save();
  }

  Future<void> setMonthlyBudget(double budget) async {
    _settings.monthlyBudget = budget;
    await _save();
  }

  Future<void> setCurrencySymbol(String symbol) async {
    _settings.currencySymbol = symbol;
    await _save();
  }

  Map<String, dynamic> exportData() {
    return {
      'settings': {
        'isDarkMode': _settings.isDarkMode,
        'morningReminderEnabled': _settings.morningReminderEnabled,
        'morningReminderTime': _settings.morningReminderTime,
        'lowStockAlertEnabled': _settings.lowStockAlertEnabled,
        'shoppingReminderEnabled': _settings.shoppingReminderEnabled,
        'habitCompletionReminderEnabled':
            _settings.habitCompletionReminderEnabled,
        'monthlyBudget': _settings.monthlyBudget,
        'currencySymbol': _settings.currencySymbol,
      },
    };
  }

  Future<void> importData(Map<String, dynamic> data) async {
    _settings = AppSettings(
      isDarkMode: data['isDarkMode'] ?? false,
      morningReminderEnabled: data['morningReminderEnabled'] ?? true,
      morningReminderTime: data['morningReminderTime'] ?? '07:30',
      lowStockAlertEnabled: data['lowStockAlertEnabled'] ?? true,
      shoppingReminderEnabled: data['shoppingReminderEnabled'] ?? true,
      habitCompletionReminderEnabled:
          data['habitCompletionReminderEnabled'] ?? false,
      monthlyBudget: (data['monthlyBudget'] as num?)?.toDouble() ?? 4000,
      currencySymbol: data['currencySymbol'] ?? '₹',
    );
    await _save();
  }

  Future<void> clearAll() async {
    _settings = AppSettings();
    await _save();
  }
}
