import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/expense.dart';
import '../data/repositories/expense_repository.dart';

final expenseProvider =
    AsyncNotifierProvider<ExpenseNotifier, List<Expense>>(ExpenseNotifier.new);

class ExpenseNotifier extends AsyncNotifier<List<Expense>> {
  final _repo = ExpenseRepository();

  @override
  Future<List<Expense>> build() => _repo.getAll();

  Future<void> add(Expense expense) async {
    await _repo.insert(expense);
    state = AsyncData(await _repo.getAll());
  }

  Future<void> edit(Expense expense) async {
    await _repo.update(expense);
    state = AsyncData(await _repo.getAll());
  }

  Future<void> remove(String id) async {
    await _repo.delete(id);
    state = AsyncData(await _repo.getAll());
  }
}
