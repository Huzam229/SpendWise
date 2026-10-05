import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spendwise/data/models/expense.dart';
import 'package:spendwise/providers/expense_provider.dart';
import 'package:spendwise/providers/filter_provider.dart';

class _FakeExpenseNotifier extends ExpenseNotifier {
  _FakeExpenseNotifier(this._items);

  final List<Expense> _items;

  @override
  Future<List<Expense>> build() async => _items;
}

void main() {
  group('Expense toMap/fromMap', () {
    test('round trips all fields', () {
      final original = Expense(
        id: 'abc-123',
        title: 'Weekly groceries',
        amount: 42.5,
        isIncome: false,
        category: 'Food',
        date: DateTime(2026, 10, 5, 14, 30),
        note: 'Market run',
      );

      final restored = Expense.fromMap(original.toMap());

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.amount, original.amount);
      expect(restored.isIncome, original.isIncome);
      expect(restored.category, original.category);
      expect(restored.date, original.date);
      expect(restored.note, original.note);
    });

    test('round trips income with null note', () {
      final original = Expense(
        id: 'pay-1',
        title: 'Salary',
        amount: 2500,
        isIncome: true,
        category: 'Salary',
        date: DateTime.utc(2026, 10, 1),
      );

      final map = original.toMap();
      expect(map['is_income'], 1);
      expect(map['note'], isNull);

      final restored = Expense.fromMap(map);
      expect(restored.isIncome, isTrue);
      expect(restored.note, isNull);
      expect(restored.amount, 2500);
    });
  });

  group('balance calculation', () {
    test('balance is income minus expense for selected month', () async {
      final month = DateTime(2026, 10, 15);
      final items = [
        Expense(
          id: '1',
          title: 'Salary',
          amount: 1000,
          isIncome: true,
          category: 'Salary',
          date: DateTime(2026, 10, 1),
        ),
        Expense(
          id: '2',
          title: 'Rent',
          amount: 400,
          isIncome: false,
          category: 'Bills',
          date: DateTime(2026, 10, 2),
        ),
        Expense(
          id: '3',
          title: 'Food',
          amount: 75.5,
          isIncome: false,
          category: 'Food',
          date: DateTime(2026, 10, 3),
        ),
        Expense(
          id: '4',
          title: 'Old expense',
          amount: 999,
          isIncome: false,
          category: 'Other',
          date: DateTime(2026, 9, 20),
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          expenseProvider.overrideWith(() => _FakeExpenseNotifier(items)),
          selectedMonthProvider.overrideWith((ref) => month),
          searchTextProvider.overrideWith((ref) => ''),
        ],
      );
      addTearDown(container.dispose);

      await container.read(expenseProvider.future);

      expect(container.read(totalIncomeProvider), 1000);
      expect(container.read(totalExpenseProvider), 475.5);
      expect(container.read(balanceProvider), 524.5);
    });
  });
}
