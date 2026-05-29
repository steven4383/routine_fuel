import 'package:hive/hive.dart';

part 'settings_model.g.dart';

@HiveType(typeId: 10)
class AppSettings extends HiveObject {
  @HiveField(0)
  bool isDarkMode;

  @HiveField(1)
  bool morningReminderEnabled;

  @HiveField(2)
  String morningReminderTime; // "HH:mm"

  @HiveField(3)
  bool lowStockAlertEnabled;

  @HiveField(4)
  bool shoppingReminderEnabled;

  @HiveField(5)
  bool habitCompletionReminderEnabled;

  @HiveField(6)
  double monthlyBudget;

  @HiveField(7)
  String currencySymbol;

  AppSettings({
    this.isDarkMode = false,
    this.morningReminderEnabled = true,
    this.morningReminderTime = '07:30',
    this.lowStockAlertEnabled = true,
    this.shoppingReminderEnabled = true,
    this.habitCompletionReminderEnabled = false,
    this.monthlyBudget = 4000,
    this.currencySymbol = '₹',
  });
}
