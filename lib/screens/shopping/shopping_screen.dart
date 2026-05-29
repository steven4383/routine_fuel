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
              subtitle:
                  'Items will auto-appear when stock runs low, or you can add manually.',
              actionLabel: 'Add Item',
              onAction: () => _showAddSheet(context),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                // Progress
                if (items.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ProgressCard(
                      label:
                          '${shopping.purchased.length} of ${items.length} purchased',
                      value: items.isEmpty
                          ? 0
                          : shopping.purchased.length / items.length,
                      subtitle: '${shopping.pending.length} remaining',
                      color: Colors.green.shade600,
                    ),
                  ),

                // Auto-generated items
                if (shopping.autoItems.isNotEmpty) ...[
                  SectionHeader(
                    title: 'Auto-generated (low stock)',
                    trailing: Tooltip(
                      message:
                          'These items were added automatically because stock is low',
                      child: Icon(Icons.info_outline_rounded,
                          size: 16, color: Colors.grey.shade400),
                    ),
                  ),
                  ...shopping.autoItems
                      .map((i) => _ShoppingItemCard(item: i)),
                ],

                // Manual items
                if (shopping.manualItems.isNotEmpty) ...[
                  const SectionHeader(title: 'Manual items'),
                  ...shopping.manualItems
                      .map((i) => _ShoppingItemCard(item: i)),
                ],
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

class _ShoppingItemCard extends StatelessWidget {
  final ShoppingItem item;
  const _ShoppingItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () =>
            context.read<ShoppingProvider>().togglePurchased(item.id),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: item.isPurchased
                      ? Colors.green.shade600
                      : Colors.transparent,
                  border: Border.all(
                    color: item.isPurchased
                        ? Colors.green.shade600
                        : Colors.grey.shade400,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: item.isPurchased
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 18)
                    : null,
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                            decoration: item.isPurchased
                                ? TextDecoration.lineThrough
                                : null,
                            color: item.isPurchased
                                ? Colors.grey.shade400
                                : null,
                          ),
                    ),
                    Text(
                      'Need: ${item.quantityNeeded % 1 == 0 ? item.quantityNeeded.toInt() : item.quantityNeeded} ${item.unit}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),

              // Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: item.isAutoGenerated
                      ? Colors.teal.shade50
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.isAutoGenerated ? 'Auto' : 'Manual',
                  style: TextStyle(
                    fontSize: 11,
                    color: item.isAutoGenerated
                        ? Colors.teal.shade700
                        : Colors.grey.shade600,
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
                onPressed: () =>
                    context.read<ShoppingProvider>().deleteItem(item.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddShoppingItemSheet extends StatefulWidget {
  const _AddShoppingItemSheet();

  @override
  State<_AddShoppingItemSheet> createState() =>
      _AddShoppingItemSheetState();
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
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 16),
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
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Add to Shopping List',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Item Name *',
                prefixIcon: Icon(Icons.shopping_bag_rounded),
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _qtyCtrl,
                    decoration: const InputDecoration(labelText: 'Qty *'),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      return n == null || n <= 0 ? 'Invalid' : null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _unit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: ['pcs', 'kg', 'g', 'L', 'pkt']
                        .map((u) =>
                            DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) => setState(() => _unit = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Add to List'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
