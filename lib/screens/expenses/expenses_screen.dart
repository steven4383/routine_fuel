import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/expense_model.dart';
import '../../providers/expense_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/app_utils.dart';
import '../../widgets/shared_widgets.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseProvider>();
    final settings = context.watch<SettingsProvider>();
    final symbol = settings.currencySymbol;
    final budget = settings.monthlyBudget;
    final monthSpend = expenses.monthTotal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: () => _showAddSheet(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary cards
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Today',
                        value: AppUtils.formatAmountFull(
                            expenses.todayTotal, symbol),
                        icon: Icons.today_rounded,
                        color: Colors.blue.shade600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                        label: 'This Month',
                        value: AppUtils.formatAmountFull(monthSpend, symbol),
                        icon: Icons.calendar_month_rounded,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ProgressCard(
                  label: 'Monthly Budget',
                  value: budget > 0 ? (monthSpend / budget).clamp(0, 1) : 0,
                  subtitle:
                      '$symbol${monthSpend.toStringAsFixed(0)} / $symbol${budget.toStringAsFixed(0)}',
                  color: monthSpend > budget * 0.9
                      ? Colors.red.shade600
                      : Colors.green.shade600,
                ),
              ],
            ),
          ),

          // Expense list
          Expanded(
            child: expenses.expenses.isEmpty
                ? EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'No expenses yet',
                    subtitle: 'Track your grocery spending here.',
                    actionLabel: 'Add Expense',
                    onAction: () => _showAddSheet(context),
                  )
                : ListView(
                    padding:
                        const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    children: [
                      const SectionHeader(title: 'Recent Expenses'),
                      ...expenses.expenses.map((e) => _ExpenseCard(
                          expense: e, symbol: symbol)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const AddExpenseSheet(),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  final String symbol;
  const _ExpenseCard({required this.expense, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final color = AppUtils.expenseCategoryColor(expense.category);
    return Card(
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.receipt_rounded, color: color, size: 20),
        ),
        title: Text(expense.itemName,
            style: Theme.of(context).textTheme.titleSmall),
        subtitle: Text(
          '${expense.categoryLabel}  ·  ${AppUtils.formatDate(expense.purchaseDate)}',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey.shade500),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$symbol${expense.totalAmount.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              'qty: ${expense.quantity % 1 == 0 ? expense.quantity.toInt() : expense.quantity}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey.shade400),
            ),
          ],
        ),
        onLongPress: () => _deleteExpense(context),
      ),
    );
  }

  Future<void> _deleteExpense(BuildContext context) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Delete Expense',
      message: 'Delete "${expense.itemName}"?',
    );
    if (confirm) {
      context.read<ExpenseProvider>().deleteExpense(expense.id);
    }
  }
}

// ─── Add Expense Sheet ────────────────────────────────────────────────────────

class AddExpenseSheet extends StatefulWidget {
  const AddExpenseSheet({super.key});

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _amountCtrl = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.other;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final expense = context.read<ExpenseProvider>().createExpense(
          itemName: _nameCtrl.text.trim(),
          quantity: double.parse(_qtyCtrl.text),
          totalAmount: double.parse(_amountCtrl.text),
          category: _category,
        );
    await context.read<ExpenseProvider>().addExpense(expense);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text('Add Expense',
                      style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Item Name *',
                          prefixIcon: Icon(Icons.label_rounded),
                        ),
                        textCapitalization: TextCapitalization.words,
                        autofocus: true,
                        validator: (v) => v == null || v.isEmpty
                            ? 'Name is required'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _qtyCtrl,
                              decoration:
                                  const InputDecoration(labelText: 'Qty *'),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              validator: (v) {
                                final n = double.tryParse(v ?? '');
                                return n == null || n <= 0 ? 'Invalid' : null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _amountCtrl,
                              decoration: InputDecoration(
                                labelText: 'Total Amount *',
                                prefixIcon: const Icon(
                                    Icons.currency_rupee_rounded),
                                prefixText: context
                                    .read<SettingsProvider>()
                                    .currencySymbol,
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              validator: (v) {
                                final n = double.tryParse(v ?? '');
                                return n == null || n <= 0
                                    ? 'Invalid amount'
                                    : null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text('Category',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ExpenseCategory.values.map((cat) {
                          final selected = _category == cat;
                          final color =
                              AppUtils.expenseCategoryColor(cat);
                          return ChoiceChip(
                            label: Text(cat.categoryLabel),
                            selected: selected,
                            selectedColor: color,
                            labelStyle: TextStyle(
                                color: selected ? Colors.white : null),
                            onSelected: (_) =>
                                setState(() => _category = cat),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                              : const Text('Add Expense'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
