import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/models/expense.dart';

Future<void> exportCsv(List<Expense> items) async {
  final rows = [
    ['Date', 'Title', 'Category', 'Type', 'Amount', 'Note'],
    ...items.map((e) => [
          e.date.toIso8601String(),
          e.title,
          e.category,
          e.isIncome ? 'Income' : 'Expense',
          e.amount,
          e.note ?? '',
        ]),
  ];
  final csv = const ListToCsvConverter().convert(rows);
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/spendwise_export.csv');
  await file.writeAsString(csv);
  await Share.shareXFiles([XFile(file.path)]);
}
