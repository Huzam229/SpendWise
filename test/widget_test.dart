import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spendwise/app.dart';
import 'package:spendwise/data/models/expense.dart';
import 'package:spendwise/providers/expense_provider.dart';

class _FakeExpenseNotifier extends ExpenseNotifier {
  @override
  Future<List<Expense>> build() async => const [];
}

void main() {
  testWidgets('SpendWise app shows home branding', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expenseProvider.overrideWith(_FakeExpenseNotifier.new),
        ],
        child: const SpendWiseApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SpendWise'), findsOneWidget);
    expect(find.text('No transactions yet'), findsOneWidget);
  });
}
