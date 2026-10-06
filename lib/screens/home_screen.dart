import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/filter_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/csv_exporter.dart';
import '../utils/formatters.dart';
import '../utils/page_transitions.dart';
import '../widgets/expense_tile.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_filter_bar.dart';
import 'add_edit_expense_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final TextEditingController _searchController;
  bool _fabOpen = false;

  @override
  void initState() {
    super.initState();
    _searchController =
        TextEditingController(text: ref.read(searchTextProvider));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _shiftMonth(int delta) {
    HapticFeedback.selectionClick();
    final current = ref.read(selectedMonthProvider);
    ref.read(selectedMonthProvider.notifier).state =
        DateTime(current.year, current.month + delta);
  }

  void _jumpToCurrentMonth() {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    ref.read(selectedMonthProvider.notifier).state =
        DateTime(now.year, now.month);
  }

  Future<void> _deleteWithUndo(Expense item) async {
    HapticFeedback.mediumImpact();
    await ref.read(expenseProvider.notifier).remove(item.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('Deleted "${item.title}"'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              ref.read(expenseProvider.notifier).add(item);
            },
          ),
        ),
      );
  }

  void _toggleTheme() {
    final current = ref.read(themeModeProvider);
    final isDark = current == ThemeMode.dark ||
        (current == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    ref.read(themeModeProvider.notifier).state =
        isDark ? ThemeMode.light : ThemeMode.dark;
  }

  Future<void> _exportCsv() async {
    final items = ref.read(filteredExpensesProvider);
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to export for this view')),
      );
      return;
    }

    try {
      await exportCsv(items);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _openAdd({bool? asIncome}) async {
    setState(() => _fabOpen = false);
    await Navigator.of(context).push(
      slideUpRoute(
        AddEditExpenseScreen(initialIsIncome: asIncome),
      ),
    );
  }

  Future<void> _openEdit(Expense item) async {
    await Navigator.of(context).push(
      slideUpRoute(AddEditExpenseScreen(expense: item)),
    );
  }

  Future<void> _refresh() async {
    ref.invalidate(expenseProvider);
    await ref.read(expenseProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final month = ref.watch(selectedMonthProvider);
    final expensesAsync = ref.watch(expenseProvider);
    final searchText = ref.watch(searchTextProvider);
    final themeMode = ref.watch(themeModeProvider);
    final filter = ref.watch(transactionFilterProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    final now = DateTime.now();
    final isCurrentMonth = month.year == now.year && month.month == now.month;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('SpendWise'),
        actions: [
          IconButton(
            tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
            onPressed: _toggleTheme,
            style: IconButton.styleFrom(
              foregroundColor: scheme.onSurfaceVariant,
            ),
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Export CSV',
            onPressed: _exportCsv,
            style: IconButton.styleFrom(
              foregroundColor: scheme.onSurfaceVariant,
            ),
            icon: const Icon(Icons.ios_share_rounded),
          ),
          IconButton(
            tooltip: 'Statistics',
            onPressed: () {
              Navigator.of(context).push(slideUpRoute(const StatsScreen()));
            },
            style: IconButton.styleFrom(
              foregroundColor: scheme.onSurfaceVariant,
            ),
            icon: const Icon(Icons.pie_chart_rounded),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(68),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  style: TextStyle(color: scheme.onSurface),
                  onChanged: (value) {
                    ref.read(searchTextProvider.notifier).state = value;
                  },
                  decoration: InputDecoration(
                    hintText: 'Search title, category, or note',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: searchText.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear',
                            onPressed: () {
                              _searchController.clear();
                              ref.read(searchTextProvider.notifier).state = '';
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
              ),
              Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          expensesAsync.when(
            loading: () => const _LoadingState(),
            error: (error, _) => _ErrorState(
              message: error.toString(),
              onRetry: () => ref.invalidate(expenseProvider),
            ),
            data: (_) {
              final expenses = ref.watch(displayedExpensesProvider);
              final balance = ref.watch(balanceProvider);
              final income = ref.watch(totalIncomeProvider);
              final expenseTotal = ref.watch(totalExpenseProvider);

              return RefreshIndicator(
                color: scheme.primary,
                onRefresh: _refresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: _MonthSelector(
                          label: monthYearFormat.format(month),
                          showToday: !isCurrentMonth,
                          onPrevious: () => _shiftMonth(-1),
                          onNext: () => _shiftMonth(1),
                          onToday: _jumpToCurrentMonth,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: SummaryCard(
                          balance: balance,
                          income: income,
                          expense: expenseTotal,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 18, 20, 0),
                        child: TransactionFilterBar(),
                      ),
                    ),
                    if (expenses.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(
                          hasSearch: searchText.trim().isNotEmpty,
                          filter: filter,
                          onAddIncome: () => _openAdd(asIncome: true),
                          onAddExpense: () => _openAdd(asIncome: false),
                        ),
                      )
                    else ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                          child: Row(
                            children: [
                              Text(
                                'Transactions',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerHighest
                                      .withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${expenses.length}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                        sliver: SliverList.separated(
                          itemCount: expenses.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = expenses[index];
                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: Duration(
                                milliseconds: 220 + (index.clamp(0, 8) * 40),
                              ),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 12 * (1 - value)),
                                    child: child,
                                  ),
                                );
                              },
                              child: ExpenseTile(
                                expense: item,
                                onTap: () => _openEdit(item),
                                onDismissed: () => _deleteWithUndo(item),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          if (_fabOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _fabOpen = false),
                child: AnimatedOpacity(
                  opacity: _fabOpen ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.28),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_fabOpen) ...[
            _QuickAddChip(
              label: 'Add income',
              icon: Icons.south_west_rounded,
              color: const Color(0xFF2E7D32),
              onTap: () => _openAdd(asIncome: true),
            ),
            const SizedBox(height: 10),
            _QuickAddChip(
              label: 'Add expense',
              icon: Icons.north_east_rounded,
              color: const Color(0xFFC62828),
              onTap: () => _openAdd(asIncome: false),
            ),
            const SizedBox(height: 12),
          ],
          FloatingActionButton.extended(
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _fabOpen = !_fabOpen);
            },
            icon: AnimatedRotation(
              turns: _fabOpen ? 0.125 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(_fabOpen ? Icons.close_rounded : Icons.add_rounded),
            ),
            label: Text(_fabOpen ? 'Close' : 'Add'),
          ),
        ],
      ),
    );
  }
}

class _QuickAddChip extends StatelessWidget {
  const _QuickAddChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainer,
      elevation: 3,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.label,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    required this.showToday,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final bool showToday;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.55),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'Previous month',
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                ),
                if (showToday)
                  TextButton(
                    onPressed: onToday,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 24),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Jump to this month'),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: 'Next month',
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 42,
            height: 42,
            child: CircularProgressIndicator(color: scheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your expenses...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: scheme.error),
            const SizedBox(height: 12),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.hasSearch,
    required this.filter,
    required this.onAddIncome,
    required this.onAddExpense,
  });

  final bool hasSearch;
  final TransactionFilter filter;
  final VoidCallback onAddIncome;
  final VoidCallback onAddExpense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    String title;
    String subtitle;
    IconData icon;

    if (hasSearch) {
      title = 'No matches found';
      subtitle = 'Try a different search term for this month.';
      icon = Icons.search_off_rounded;
    } else if (filter == TransactionFilter.income) {
      title = 'No income yet';
      subtitle = 'Log a salary or other income to see it here.';
      icon = Icons.south_west_rounded;
    } else if (filter == TransactionFilter.expense) {
      title = 'No expenses yet';
      subtitle = 'Track a purchase or bill to fill this list.';
      icon = Icons.north_east_rounded;
    } else {
      title = 'No transactions yet';
      subtitle =
          'Add your first income or expense to start tracking this month.';
      icon = Icons.receipt_long_rounded;
    }

    return Padding(
      padding: const EdgeInsets.all(36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.55),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: scheme.primary),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          if (!hasSearch) ...[
            const SizedBox(height: 22),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.tonalIcon(
                  onPressed: onAddIncome,
                  icon: const Icon(Icons.south_west_rounded),
                  label: const Text('Add income'),
                ),
                FilledButton.icon(
                  onPressed: onAddExpense,
                  icon: const Icon(Icons.north_east_rounded),
                  label: const Text('Add expense'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
