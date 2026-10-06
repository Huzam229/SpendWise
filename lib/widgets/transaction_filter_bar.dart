import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/filter_provider.dart';

class TransactionFilterBar extends ConsumerWidget {
  const TransactionFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(transactionFilterProvider);
    final scheme = Theme.of(context).colorScheme;

    Widget chip({
      required TransactionFilter value,
      required String label,
      required IconData icon,
      Color? accent,
    }) {
      final isSelected = selected == value;
      final color = accent ?? scheme.primary;

      return FilterChip(
        selected: isSelected,
        showCheckmark: false,
        avatar: Icon(
          icon,
          size: 16,
          color: isSelected ? color : scheme.onSurfaceVariant,
        ),
        label: Text(label),
        labelStyle: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? color : scheme.onSurfaceVariant,
        ),
        selectedColor: color.withValues(alpha: 0.16),
        backgroundColor: scheme.surfaceContainer,
        side: BorderSide(
          color: isSelected
              ? color.withValues(alpha: 0.45)
              : scheme.outlineVariant.withValues(alpha: 0.45),
        ),
        onSelected: (_) {
          ref.read(transactionFilterProvider.notifier).state = value;
        },
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip(
          value: TransactionFilter.all,
          label: 'All',
          icon: Icons.list_alt_rounded,
        ),
        chip(
          value: TransactionFilter.income,
          label: 'Income',
          icon: Icons.south_west_rounded,
          accent: const Color(0xFF2E7D32),
        ),
        chip(
          value: TransactionFilter.expense,
          label: 'Expense',
          icon: Icons.north_east_rounded,
          accent: const Color(0xFFC62828),
        ),
      ],
    );
  }
}
