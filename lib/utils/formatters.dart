import 'package:intl/intl.dart';

import '../core/constants.dart';
import '../data/models/category.dart';

final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
final monthYearFormat = DateFormat('MMMM yyyy');
final shortDateFormat = DateFormat('MMM d, yyyy');

Category categoryOf(String name) {
  return kCategories.firstWhere(
    (c) => c.name == name,
    orElse: () => kCategories.last,
  );
}

String formatSignedAmount(double amount, {required bool isIncome}) {
  final formatted = currencyFormat.format(amount);
  return isIncome ? '+$formatted' : '-$formatted';
}
