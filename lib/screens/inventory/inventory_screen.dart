import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/inventory_model.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/shopping_provider.dart';
import '../../utils/app_utils.dart';
import '../../widgets/shared_widgets.dart';
import 'add_edit_inventory_sheet.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryProvider>();
    final allItems = inventory.items;
    final lowStock = inventory.lowStockItems;

    final filtered = _search.isEmpty
        ? allItems
        : allItems
            .where((i) =>
                i.name.toLowerCase().contains(_search.toLowerCase()))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
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
      body: allItems.isEmpty
          ? EmptyState(
              icon: Icons.inventory_2_rounded,
              title: 'No items yet',
              subtitle: 'Add grocery items to track your stock.',
              actionLabel: 'Add Item',
              onAction: () => _showAddSheet(context),
            )
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search items...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () => setState(() => _search = ''),
                            )
                          : null,
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),

                // Low stock summary
                if (lowStock.isNotEmpty && _search.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: AlertBanner(
                      message:
                          '${lowStock.length} item${lowStock.length > 1 ? 's are' : ' is'} low on stock',
                      color: Colors.orange.shade700,
                      icon: Icons.warning_amber_rounded,
                    ),
                  ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    children: _buildGroupedList(context, filtered),
                  ),
                ),
              ],
            ),
    );
  }

  List<Widget> _buildGroupedList(
      BuildContext context, List<InventoryItem> items) {
    if (items.isEmpty) {
      return [
        const SizedBox(height: 60),
        const Center(child: Text('No items match your search.')),
      ];
    }

    // Group by category
    final grouped = <InventoryCategory, List<InventoryItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    final widgets = <Widget>[];
    for (final entry in grouped.entries) {
      widgets.add(SectionHeader(
        title: entry.key.name.toUpperCase(),
        trailing: Icon(
          AppUtils.categoryIcon(entry.key),
          size: 16,
          color: AppUtils.categoryColor(entry.key, context),
        ),
      ));
      for (final item in entry.value) {
        widgets.add(_InventoryCard(item: item));
      }
    }
    return widgets;
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const AddEditInventorySheet(),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final InventoryItem item;
  const _InventoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isLow = item.isLowStock;
    final catColor = AppUtils.categoryColor(item.category, context);

    return Card(
      child: InkWell(
        onLongPress: () => _showOptions(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: (isLow ? Colors.red : catColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isLow
                      ? Icons.warning_amber_rounded
                      : AppUtils.categoryIcon(item.category),
                  color: isLow ? Colors.red.shade600 : catColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(item.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall),
                        ),
                        if (isLow)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Low',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    StockBar(
                      quantity: item.quantity,
                      threshold: item.minimumThreshold,
                      unitLabel: item.unitLabel,
                    ),
                    if (item.pricePerUnit > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '₹${item.pricePerUnit.toStringAsFixed(0)} / ${item.unitLabel}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey.shade400),
                        ),
                      ),
                  ],
                ),
              ),

              IconButton(
                icon: const Icon(Icons.more_vert_rounded),
                iconSize: 18,
                color: Colors.grey.shade400,
                onPressed: () => _showOptions(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Edit Item'),
              onTap: () {
                Navigator.pop(ctx);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => AddEditInventorySheet(item: item),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_rounded, color: Colors.green),
              title: const Text('Update Stock'),
              onTap: () {
                Navigator.pop(ctx);
                _showUpdateStockDialog(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_rounded,
                  color: Colors.red.shade600),
              title: Text('Delete',
                  style: TextStyle(color: Colors.red.shade600)),
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await showConfirmDialog(
                  context,
                  title: 'Delete Item',
                  message:
                      'Delete "${item.name}"? This cannot be undone.',
                );
                if (confirm) {
                  context.read<InventoryProvider>().deleteItem(item.id);
                  // Sync shopping list
                  final shopping = context.read<ShoppingProvider>();
                  final invProvider = context.read<InventoryProvider>();
                  await shopping
                      .syncFromInventory(invProvider.lowStockItems);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateStockDialog(BuildContext context) {
    final ctrl = TextEditingController(
        text: item.quantity % 1 == 0
            ? item.quantity.toInt().toString()
            : item.quantity.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update Stock: ${item.name}'),
        content: TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'New quantity',
            suffixText: item.unitLabel,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final qty = double.tryParse(ctrl.text);
              if (qty != null && qty >= 0) {
                final updated = item.copyWith(quantity: qty);
                await context
                    .read<InventoryProvider>()
                    .updateItem(updated);
                await context
                    .read<ShoppingProvider>()
                    .syncFromInventory(
                        context.read<InventoryProvider>().lowStockItems);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
