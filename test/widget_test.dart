import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spendwise/app.dart';

void main() {
  testWidgets('SpendWise app shows home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SpendWiseApp()),
    );

    expect(find.text('SpendWise'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });
}
