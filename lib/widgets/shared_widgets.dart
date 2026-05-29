import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

// ─── Section Header ───────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({super.key, required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

// ─── Progress Indicator Card ─────────────────────────────────────────────────

class ProgressCard extends StatelessWidget {
  final String label;
  final double value; // 0.0 – 1.0
  final String subtitle;
  final Color color;

  const ProgressCard({
    super.key,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Monthly Budget'),
            Gap(10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleSmall),
                Text(
                  '${(value * 100).toInt()}%',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: value,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade400),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              Container(
                height: 50,
                child: ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Stock Bar ────────────────────────────────────────────────────────────────

class StockBar extends StatelessWidget {
  final double quantity;
  final double threshold;
  final String unitLabel;

  const StockBar({super.key, required this.quantity, required this.threshold, required this.unitLabel});

  @override
  Widget build(BuildContext context) {
    final isLow = quantity <= threshold;
    final max = threshold * 4;
    final percent = (quantity / max).clamp(0.0, 1.0);
    final color = isLow ? Colors.red.shade500 : Colors.green.shade600;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${quantity % 1 == 0 ? quantity.toInt() : quantity.toStringAsFixed(1)} $unitLabel',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isLow ? Colors.red.shade600 : Colors.grey.shade600,
            fontWeight: isLow ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

// ─── Alert Banner ────────────────────────────────────────────────────────────

class AlertBanner extends StatelessWidget {
  final String message;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const AlertBanner({super.key, required this.message, required this.color, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 13, color: color.withOpacity(0.9), fontWeight: FontWeight.w500),
              ),
            ),
            if (onTap != null) Icon(Icons.arrow_forward_ios_rounded, size: 12, color: color),
          ],
        ),
      ),
    );
  }
}

// ─── Confirm Dialog ───────────────────────────────────────────────────────────

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  Color? confirmColor,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: confirmColor ?? Colors.red),
              child: Text(confirmLabel),
            ),
          ],
        ),
      ) ??
      false;
}
