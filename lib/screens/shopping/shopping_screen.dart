import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/shopping_model.dart';
import '../../providers/shopping_provider.dart';
import '../../widgets/shared_widgets.dart';

class ShoppingScreen extends StatelessWidget {
  const ShoppingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shopping = context.watch<ShoppingProvider>();
    final items = shopping.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        actions: [
          if (shopping.purchased.isNotEmpty)
            TextButton.icon(
              onPressed: () => _clearPurchased(context),
              icon: const Icon(Icons.clear_all_rounded, size: 18),
              label: const Text('Clear done'),
            ),
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
      body: items.isEmpty
          ? EmptyState(
              icon: Icons.shopping_cart_rounded,
              title: 'Shopping list is clear',
              subtitle: 'Items will auto-appear when stock runs low, or you can add manually.',
              actionLabel: 'Add Item',
              onAction: () => _showAddSheet(context),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
              children: [
                _ShoppingProgressCard(
                  purchased: shopping.purchased.length,
                  total: items.length,
                  remaining: shopping.pending.length,
                ),
                if (shopping.autoItems.isNotEmpty)
                  _ShoppingSectionCard(
                    title: 'Low Stock',
                    trailing: Tooltip(
                      message: 'These items were added automatically because stock is low',
                      child: Icon(Icons.info_outline_rounded, size: 16, color: Colors.grey.shade400),
                    ),
                    items: shopping.autoItems,
                  ),
                if (shopping.manualItems.isNotEmpty)
                  _ShoppingSectionCard(
                    title: 'Manual Items',
                    items: shopping.manualItems,
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
      builder: (_) => const _AddShoppingItemSheet(),
    );
  }

  Future<void> _clearPurchased(BuildContext context) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Clear Purchased',
      message: 'Remove all purchased items from the list?',
      confirmLabel: 'Clear',
      confirmColor: Colors.orange,
    );
    if (confirm) {
      context.read<ShoppingProvider>().clearPurchased();
    }
  }
}

class _ShoppingProgressCard extends StatelessWidget {
  final int purchased;
  final int total;
  final int remaining;

  const _ShoppingProgressCard({
    required this.purchased,
    required this.total,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final value = total == 0 ? 0.0 : purchased / total;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Shopping Progress'),
            Row(
              children: [
                Text('$purchased of $total purchased', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                Text(
                  '${(value * 100).toInt()}%',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: const Color(0xFFFF3B0A), fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: value,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: const Color(0xFFFF3B0A).withOpacity(0.14),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFFF3B0A)),
            ),
            const SizedBox(height: 8),
            Text('$remaining remaining', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ShoppingSectionCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final List<ShoppingItem> items;

  const _ShoppingSectionCard({
    required this.title,
    required this.items,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          children: [
            SectionHeader(title: title, trailing: trailing),
            ...items.map((i) => _ShoppingItemCard(item: i)),
          ],
        ),
      ),
    );
  }
}

class _ShoppingItemCard extends StatelessWidget {
  final ShoppingItem item;
  const _ShoppingItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.read<ShoppingProvider>().togglePurchased(item.id),
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
              // Checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: item.isPurchased ? Colors.green.shade600 : Colors.transparent,
                  border: Border.all(color: item.isPurchased ? Colors.green.shade600 : Colors.grey.shade400, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: item.isPurchased ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        decoration: item.isPurchased ? TextDecoration.lineThrough : null,
                        color: item.isPurchased ? Colors.grey.shade400 : null,
                      ),
                    ),
                    Text(
                      'Need: ${item.quantityNeeded % 1 == 0 ? item.quantityNeeded.toInt() : item.quantityNeeded} ${item.unit}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),

              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: item.isAutoGenerated ? Colors.teal.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.isAutoGenerated ? 'Auto' : 'Manual',
                  style: TextStyle(
                    fontSize: 11,
                    color: item.isAutoGenerated ? Colors.teal.shade700 : Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Delete
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                iconSize: 18,
                color: Colors.grey.shade400,
                onPressed: () => context.read<ShoppingProvider>().deleteItem(item.id),
              ),
            ],
        ),
      ),
    );
  }
}

class _AddShoppingItemSheet extends StatefulWidget {
  const _AddShoppingItemSheet();

  @override
  State<_AddShoppingItemSheet> createState() => _AddShoppingItemSheetState();
}

class _AddShoppingItemSheetState extends State<_AddShoppingItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  String _unit = 'pcs';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final item = context.read<ShoppingProvider>().createManualItem(
      name: _nameCtrl.text.trim(),
      quantityNeeded: double.parse(_qtyCtrl.text.trim()),
      unit: _unit,
    );
    await context.read<ShoppingProvider>().addItem(item);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Add to Shopping List', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Item Name *', prefixIcon: Icon(Icons.shopping_bag_rounded)),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
              validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _qtyCtrl,
                    decoration: const InputDecoration(labelText: 'Qty *'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      return n == null || n <= 0 ? 'Invalid' : null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _ShoppingUnitPickerField(unit: _unit, onChanged: (unit) => setState(() => _unit = unit)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _save, child: const Text('Add to List')),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ShoppingUnitPickerField extends StatelessWidget {
  final String unit;
  final ValueChanged<String> onChanged;

  const _ShoppingUnitPickerField({required this.unit, required this.onChanged});

  static const _units = ['pcs', 'kg', 'g', 'L', 'pkt'];

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showPicker(context),
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: const InputDecoration(labelText: 'Unit', suffixIcon: Icon(Icons.keyboard_arrow_down_rounded)),
        child: Text(_labelFor(unit), style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              Row(
                children: [
                  Text('Unit', style: Theme.of(ctx).textTheme.titleLarge),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const SizedBox(height: 4),
              ..._units.map((item) {
                final selected = item == unit;
                return InkWell(
                  onTap: () {
                    onChanged(item);
                    Navigator.pop(ctx);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    margin: const EdgeInsets.only(bottom: 6),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFFF3B0A) : const Color(0xFFF7F7F7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: selected ? const Color(0xFFFF3B0A) : const Color(0xFFE8E8E8)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _labelFor(item),
                            style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                              color: selected ? Colors.white : const Color(0xFF111111),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (selected) const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  String _labelFor(String value) {
    switch (value) {
      case 'kg':
        return 'Kilogram';
      case 'g':
        return 'Gram';
      case 'L':
        return 'Litre';
      case 'pkt':
        return 'Packet';
      default:
        return 'Pieces';
    }
  }
}
