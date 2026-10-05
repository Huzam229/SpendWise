import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/models/expense.dart';
import 'expense_provider.dart';

final selectedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

final searchTextProvider = StateProvider<String>((ref) => '');

final filteredExpensesProvider = Provider<List<Expense>>((ref) {
  final expenses = ref.watch(expenseProvider).value ?? [];
  final month = ref.watch(selectedMonthProvider);
  final search = ref.watch(searchTextProvider).trim().toLowerCase();

  return expenses.where((e) {
    final inMonth = e.date.year == month.year && e.date.month == month.month;
    if (!inMonth) return false;
    if (search.isEmpty) return true;
    return e.title.toLowerCase().contains(search) ||
        e.category.toLowerCase().contains(search) ||
        (e.note?.toLowerCase().contains(search) ?? false);
  }).toList();
});

final totalIncomeProvider = Provider<double>((ref) {
  final list = ref.watch(filteredExpensesProvider);
  return list.where((e) => e.isIncome).fold(0.0, (sum, e) => sum + e.amount);
});

final totalExpenseProvider = Provider<double>((ref) {
  final list = ref.watch(filteredExpensesProvider);
  return list.where((e) => !e.isIncome).fold(0.0, (sum, e) => sum + e.amount);
});

final balanceProvider = Provider<double>((ref) {
  return ref.watch(totalIncomeProvider) - ref.watch(totalExpenseProvider);
});
