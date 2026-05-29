import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/inventory_model.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/shopping_provider.dart';
import '../../utils/app_utils.dart';

class AddEditInventorySheet extends StatefulWidget {
  final InventoryItem? item;
  const AddEditInventorySheet({super.key, this.item});

  @override
  State<AddEditInventorySheet> createState() =>
      _AddEditInventorySheetState();
}

class _AddEditInventorySheetState extends State<AddEditInventorySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _minCtrl;
  late final TextEditingController _priceCtrl;
  late UnitType _unit;
  late InventoryCategory _category;
  bool _saving = false;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameCtrl = TextEditingController(text: item?.name ?? '');
    _qtyCtrl = TextEditingController(
        text: item != null
            ? (item.quantity % 1 == 0
                ? item.quantity.toInt().toString()
                : item.quantity.toString())
            : '');
    _minCtrl = TextEditingController(
        text: item?.minimumThreshold.toInt().toString() ?? '2');
    _priceCtrl = TextEditingController(
        text: item?.pricePerUnit != null && item!.pricePerUnit > 0
            ? item.pricePerUnit.toStringAsFixed(0)
            : '');
    _unit = item?.unit ?? UnitType.piece;
    _category = item?.category ?? InventoryCategory.other;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _minCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<InventoryProvider>();

    // Check for duplicates
    if (provider.hasDuplicate(_nameCtrl.text.trim(),
        excludeId: widget.item?.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An item with this name already exists.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final qty = double.parse(_qtyCtrl.text.trim());
    final min = double.parse(_minCtrl.text.trim());
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;

    if (_isEditing) {
      final updated = widget.item!.copyWith(
        name: _nameCtrl.text.trim(),
        quantity: qty,
        unit: _unit,
        minimumThreshold: min,
        pricePerUnit: price,
        category: _category,
      );
      await provider.updateItem(updated);
    } else {
      final item = provider.createItem(
        name: _nameCtrl.text.trim(),
        quantity: qty,
        unit: _unit,
        minimumThreshold: min,
        pricePerUnit: price,
        category: _category,
      );
      await provider.addItem(item);
    }

    // Sync shopping list
    await context
        .read<ShoppingProvider>()
        .syncFromInventory(provider.lowStockItems);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
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
                  Text(
                    _isEditing ? 'Edit Item' : 'New Inventory Item',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
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
                      // Name
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Item Name *',
                          hintText: 'e.g. Eggs',
                          prefixIcon: Icon(Icons.label_rounded),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) =>
                            AppUtils.validateRequired(v, 'Name'),
                      ),
                      const SizedBox(height: 14),

                      // Quantity + Unit row
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _qtyCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Quantity *',
                                prefixIcon:
                                    Icon(Icons.numbers_rounded),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              validator: (v) =>
                                  AppUtils.validatePositiveNumber(
                                      v, 'Quantity'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<UnitType>(
                              value: _unit,
                              decoration: const InputDecoration(
                                  labelText: 'Unit'),
                              items: UnitType.values
                                  .map((u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(_unitLabel(u))))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _unit = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Min threshold
                      TextFormField(
                        controller: _minCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Minimum Threshold *',
                          hintText: 'Trigger low stock alert',
                          prefixIcon:
                              Icon(Icons.warning_amber_rounded),
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true),
                        validator: (v) =>
                            AppUtils.validatePositiveNumber(
                                v, 'Threshold'),
                      ),
                      const SizedBox(height: 14),

                      // Price
                      TextFormField(
                        controller: _priceCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Price per Unit (optional)',
                          prefixIcon: Icon(Icons.currency_rupee),
                          hintText: '0',
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true),
                      ),
                      const SizedBox(height: 20),

                      // Category
                      Text('Category',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: InventoryCategory.values.map((cat) {
                          final selected = _category == cat;
                          final color =
                              AppUtils.categoryColor(cat, context);
                          return ChoiceChip(
                            label: Text(cat.categoryLabel),
                            avatar: Icon(AppUtils.categoryIcon(cat),
                                size: 16,
                                color:
                                    selected ? Colors.white : color),
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
                              : Text(_isEditing
                                  ? 'Save Changes'
                                  : 'Add Item'),
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

  String _unitLabel(UnitType u) {
    switch (u) {
      case UnitType.piece:
        return 'Pieces';
      case UnitType.kg:
        return 'Kilogram';
      case UnitType.gram:
        return 'Gram';
      case UnitType.litre:
        return 'Litre';
      case UnitType.packet:
        return 'Packet';
    }
  }
}
