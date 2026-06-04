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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
        children: [
          _ExpenseSummaryCard(
            todayValue: AppUtils.formatAmountFull(expenses.todayTotal, symbol),
            monthValue: AppUtils.formatAmountFull(monthSpend, symbol),
            budgetValue: budget > 0 ? (monthSpend / budget).clamp(0, 1).toDouble() : 0,
            budgetSubtitle: '$symbol${monthSpend.toStringAsFixed(0)} / $symbol${budget.toStringAsFixed(0)}',
            budgetColor: monthSpend > budget * 0.9 ? Colors.red.shade600 : const Color(0xFFFF3B0A),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(
                children: [
                  SectionHeader(
                    title: 'Recent Expenses',
                    trailing: TextButton.icon(
                      onPressed: () => _showAddSheet(context),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add'),
                    ),
                  ),
                  if (expenses.expenses.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: EmptyState(
                        icon: Icons.receipt_long_rounded,
                        title: 'No expenses yet',
                        subtitle: 'Track your grocery spending here.',
                        actionLabel: 'Add Expense',
                        onAction: () => _showAddSheet(context),
                      ),
                    )
                  else
                    ...expenses.expenses.map((e) => _ExpenseRow(expense: e, symbol: symbol)),
                ],
              ),
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

class _ExpenseSummaryCard extends StatelessWidget {
  final String todayValue;
  final String monthValue;
  final double budgetValue;
  final String budgetSubtitle;
  final Color budgetColor;

  const _ExpenseSummaryCard({
    required this.todayValue,
    required this.monthValue,
    required this.budgetValue,
    required this.budgetSubtitle,
    required this.budgetColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Monthly Spend'),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: _MiniMetric(
                    label: 'Today',
                    value: todayValue,
                    icon: Icons.today_rounded,
                    dark: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniMetric(
                    label: 'This Month',
                    value: monthValue,
                    icon: Icons.calendar_month_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: Text('Budget', style: Theme.of(context).textTheme.titleSmall)),
                Text(
                  '${(budgetValue * 100).toInt()}%',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: budgetColor, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: budgetValue,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: budgetColor.withOpacity(0.14),
              valueColor: AlwaysStoppedAnimation(budgetColor),
            ),
            const SizedBox(height: 8),
            Text(budgetSubtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool dark;

  const _MiniMetric({
    required this.label,
    required this.value,
    required this.icon,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = dark ? Colors.white : const Color(0xFF17151A);
    return Container(
      height: 116,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF211D22) : const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: dark ? Colors.transparent : const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: foreground.withOpacity(0.72)))),
              Icon(icon, color: foreground, size: 18),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: foreground),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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

class _ExpenseRow extends StatelessWidget {
  final ExpenseModel expense;
  final String symbol;

  const _ExpenseRow({required this.expense, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final color = AppUtils.expenseCategoryColor(expense.category);
    return InkWell(
      onLongPress: () => _deleteExpense(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.receipt_rounded, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(expense.itemName, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    '${expense.categoryLabel} · ${AppUtils.formatDate(expense.purchaseDate)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$symbol${expense.totalAmount.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: const Color(0xFFFF3B0A),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  'qty ${expense.quantity % 1 == 0 ? expense.quantity.toInt() : expense.quantity}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
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
