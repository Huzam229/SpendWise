import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/filter_provider.dart';
import '../utils/formatters.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  int? _touchedIndex;

  Map<String, double> _expensesByCategory(
    List<Expense> expenses,
    DateTime month,
  ) {
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
  Widget build(BuildContext context) {
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

          final sections = List.generate(entries.length, (index) {
            final entry = entries[index];
            final category = categoryOf(entry.key);
            final percent = total == 0 ? 0.0 : (entry.value / total) * 100;
            final isTouched = index == _touchedIndex;

            return PieChartSectionData(
              color: category.color,
              value: entry.value,
              title: percent >= 8 || isTouched
                  ? '${percent.toStringAsFixed(0)}%'
                  : '',
              radius: isTouched ? 82 : 70,
              titleStyle: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: isTouched ? 15 : 12,
              ),
            );
          });

          final focused = _touchedIndex != null && _touchedIndex! < entries.length
              ? entries[_touchedIndex!]
              : null;

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
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 58,
                        sections: sections,
                        borderData: FlBorderData(show: false),
                        pieTouchData: PieTouchData(
                          touchCallback: (event, response) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  response == null ||
                                  response.touchedSection == null) {
                                _touchedIndex = null;
                                return;
                              }
                              _touchedIndex = response
                                  .touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          focused?.key ?? 'Total',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormat.format(focused?.value ?? total),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap a slice for details',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              Text(
                'Legend',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              ...entries.asMap().entries.map((indexed) {
                final index = indexed.key;
                final entry = indexed.value;
                final category = categoryOf(entry.key);
                final percent = total == 0 ? 0.0 : (entry.value / total) * 100;
                final isFocused = index == _touchedIndex;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isFocused
                          ? category.color.withValues(alpha: 0.12)
                          : scheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isFocused
                            ? category.color.withValues(alpha: 0.45)
                            : scheme.outlineVariant.withValues(
                                alpha:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
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
