import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/habit_model.dart';
import '../../providers/habit_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../utils/app_utils.dart';

class AddEditHabitSheet extends StatefulWidget {
  final HabitModel? habit;
  const AddEditHabitSheet({super.key, this.habit});

  @override
  State<AddEditHabitSheet> createState() => _AddEditHabitSheetState();
}

class _AddEditHabitSheetState extends State<AddEditHabitSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late HabitCategory _category;
  late RepeatType _repeatType;
  TimeOfDay? _scheduledTime;
  final List<LinkedInventoryItem> _linkedItems = [];
  bool _saving = false;

  bool get _isEditing => widget.habit != null;

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    _titleCtrl = TextEditingController(text: h?.title ?? '');
    _descCtrl = TextEditingController(text: h?.description ?? '');
    _category = h?.category ?? HabitCategory.morning;
    _repeatType = h?.repeatType ?? RepeatType.daily;
    if (h?.scheduledTime != null) {
      final parts = h!.scheduledTime!.split(':');
      _scheduledTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    if (h != null) {
      _linkedItems.addAll(h.linkedItems);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _scheduledTime ?? TimeOfDay.now());
    if (picked != null) setState(() => _scheduledTime = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final provider = context.read<HabitProvider>();
    final timeStr = _scheduledTime != null
        ? '${_scheduledTime!.hour.toString().padLeft(2, '0')}:${_scheduledTime!.minute.toString().padLeft(2, '0')}'
        : null;

    if (_isEditing) {
      final updated = widget.habit!.copyWith(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _category,
        scheduledTime: timeStr,
        repeatType: _repeatType,
        linkedItems: _linkedItems,
      );
      await provider.updateHabit(updated);
    } else {
      final habit = provider.createHabit(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _category,
        scheduledTime: timeStr,
        repeatType: _repeatType,
        linkedItems: _linkedItems,
      );
      await provider.addHabit(habit);
    }

    if (mounted) Navigator.pop(context);
  }

  void _showLinkInventoryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _LinkInventoryDialog(
        existingLinks: _linkedItems,
        onSave: (links) => setState(() {
          _linkedItems
            ..clear()
            ..addAll(links);
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(_isEditing ? 'Edit Habit' : 'New Habit', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
                      // Title
                      TextFormField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Habit Title *',
                          hintText: 'e.g. Morning Breakfast',
                          prefixIcon: Icon(Icons.title_rounded),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => AppUtils.validateRequired(v, 'Title'),
                      ),
                      const SizedBox(height: 14),

                      // Description
                      TextFormField(
                        controller: _descCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Optional notes',
                          prefixIcon: Icon(Icons.notes_rounded),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20),

                      // Category
                      Text('Category', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: HabitCategory.values.map((cat) {
                          final selected = _category == cat;
                          final color = AppUtils.habitCategoryColor(cat);
                          return ChoiceChip(
                            label: Text(_catLabel(cat)),
                            avatar: Icon(
                              AppUtils.habitCategoryIcon(cat),
                              size: 16,
                              color: selected ? Colors.white : color,
                            ),
                            selected: selected,
                            selectedColor: color,
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : null,
                              fontWeight: selected ? FontWeight.w600 : null,
                            ),
                            onSelected: (_) => setState(() => _category = cat),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Repeat type
                      Text('Repeat', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Row(
                        children: RepeatType.values.map((type) {
                          final selected = _repeatType == type;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(_repeatLabel(type)),
                              selected: selected,
                              onSelected: (_) => setState(() => _repeatType = type),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Scheduled time
                      Text('Scheduled Time', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.access_time_rounded),
                        label: Text(_scheduledTime != null ? _scheduledTime!.format(context) : 'Set time (optional)'),
                      ),
                      if (_scheduledTime != null)
                        TextButton(
                          onPressed: () => setState(() => _scheduledTime = null),
                          child: const Text('Clear time'),
                        ),
                      const SizedBox(height: 20),

                      // Linked inventory items
                      Row(
                        children: [
                          Text('Linked Inventory Items', style: Theme.of(context).textTheme.titleSmall),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _showLinkInventoryDialog,
                            icon: const Icon(Icons.link_rounded, size: 16),
                            label: const Text('Link'),
                          ),
                        ],
                      ),
                      if (_linkedItems.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Link inventory items to auto-deduct when you complete this habit.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
                          ),
                        )
                      else
                        ..._linkedItems.map((link) {
                          final item = context.read<InventoryProvider>().getById(link.inventoryItemId);
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.inventory_2_rounded, size: 18, color: Colors.teal),
                            title: Text(item?.name ?? link.inventoryItemId),
                            trailing: Text(
                              '${link.quantity % 1 == 0 ? link.quantity.toInt() : link.quantity} ${item?.unitLabel ?? ''}',
                            ),
                          );
                        }),
                      const SizedBox(height: 32),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(_isEditing ? 'Save Changes' : 'Add Habit'),
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

  String _catLabel(HabitCategory cat) {
    switch (cat) {
      case HabitCategory.morning:
        return 'Morning';
      case HabitCategory.afternoon:
        return 'Afternoon';
      case HabitCategory.evening:
        return 'Evening';
      case HabitCategory.anytime:
        return 'Anytime';
    }
  }

  String _repeatLabel(RepeatType type) {
    switch (type) {
      case RepeatType.daily:
        return 'Daily';
      case RepeatType.weekly:
        return 'Weekly';
      case RepeatType.none:
        return 'Once';
    }
  }
}

// ─── Link Inventory Dialog ────────────────────────────────────────────────────

class _LinkInventoryDialog extends StatefulWidget {
  final List<LinkedInventoryItem> existingLinks;
  final void Function(List<LinkedInventoryItem>) onSave;

  const _LinkInventoryDialog({required this.existingLinks, required this.onSave});

  @override
  State<_LinkInventoryDialog> createState() => _LinkInventoryDialogState();
}

class _LinkInventoryDialogState extends State<_LinkInventoryDialog> {
  final List<LinkedInventoryItem> _links = [];
  final Map<String, TextEditingController> _qtyControllers = {};

  @override
  void initState() {
    super.initState();
    _links.addAll(widget.existingLinks);
    for (final link in _links) {
      _qtyControllers[link.inventoryItemId] = TextEditingController(text: link.quantity.toString());
    }
  }

  @override
  void dispose() {
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool _isLinked(String id) => _links.any((l) => l.inventoryItemId == id);

  void _toggle(String id, String unitLabel) {
    setState(() {
      if (_isLinked(id)) {
        _links.removeWhere((l) => l.inventoryItemId == id);
        _qtyControllers.remove(id);
      } else {
        _links.add(LinkedInventoryItem(inventoryItemId: id, quantity: 1));
        _qtyControllers[id] = TextEditingController(text: '1');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = context.read<InventoryProvider>().items;

    return AlertDialog(
      title: const Text('Link Inventory Items'),
      content: SizedBox(
        width: double.maxFinite,
        child: items.isEmpty
            ? const Text('No inventory items yet. Add items first.')
            : ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  final linked = _isLinked(item.id);
                  return Column(
                    children: [
                      CheckboxListTile(
                        dense: true,
                        value: linked,
                        onChanged: (_) => _toggle(item.id, item.unitLabel),
                        title: Text(item.name),
                        subtitle: Text('${item.quantity} ${item.unitLabel} in stock'),
                        secondary: Icon(
                          AppUtils.categoryIcon(item.category),
                          color: AppUtils.categoryColor(item.category, context),
                          size: 20,
                        ),
                      ),
                      if (linked)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: TextFormField(
                            controller: _qtyControllers[item.id],
                            decoration: InputDecoration(
                              labelText: 'Quantity to deduct',
                              suffixText: item.unitLabel,
                              isDense: true,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (val) {
                              final qty = double.tryParse(val) ?? 1;
                              final idx = _links.indexWhere((l) => l.inventoryItemId == item.id);
                              if (idx >= 0) {
                                _links[idx] = LinkedInventoryItem(inventoryItemId: item.id, quantity: qty);
                              }
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_links);
            Navigator.pop(context);
          },
          child: const Text('Save Links'),
        ),
      ],
    );
  }
}
