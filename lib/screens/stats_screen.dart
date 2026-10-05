import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/filter_provider.dart';
import '../utils/formatters.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  Map<String, double> _expensesByCategory(List<Expense> expenses, DateTime month) {
    final totals = <String, double>{};

    for (final expense in expenses) {
      final inMonth =
          expense.date.year == month.year && expense.date.month == month.month;
      if (!inMonth || expense.isIncome) continue;
      totals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    return totals;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final month = ref.watch(selectedMonthProvider);
    final expensesAsync = ref.watch(expenseProvider);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Statistics'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (expenses) {
          final byCategory = _expensesByCategory(expenses, month);
          final total = byCategory.values.fold(0.0, (sum, v) => sum + v);

          if (byCategory.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.pie_chart_outline_rounded,
                      size: 56,
                      color: scheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No expenses this month',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add some expenses in ${monthYearFormat.format(month)} to see the breakdown.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }

          final entries = byCategory.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          final sections = entries.map((entry) {
            final category = categoryOf(entry.key);
            final percent = total == 0 ? 0.0 : (entry.value / total) * 100;

            return PieChartSectionData(
              color: category.color,
              value: entry.value,
              title: percent >= 8 ? '${percent.toStringAsFixed(0)}%' : '',
              radius: 72,
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            );
          }).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Text(
                monthYearFormat.format(month),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Spending by category · ${currencyFormat.format(total)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 28),
              AspectRatio(
                aspectRatio: 1.15,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 48,
                    sections: sections,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Legend',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              ...entries.map((entry) {
                final category = categoryOf(entry.key);
                final percent = total == 0 ? 0.0 : (entry.value / total) * 100;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(
                          alpha: Theme.of(context).brightness == Brightness.dark
                              ? 0.35
                              : 0.55,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: category.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(category.icon, size: 18, color: category.color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurface,
                                ),
                          ),
                        ),
                        Text(
                          '${percent.toStringAsFixed(0)}%',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          currencyFormat.format(entry.value),
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onSurface,
                                  ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
