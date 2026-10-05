import '../db/database_helper.dart';
import '../models/expense.dart';

class ExpenseRepository {
  Future<List<Expense>> getAll() async {
    final db = await DatabaseHelper.instance.db;
    final rows = await db.query('expenses', orderBy: 'date DESC');
    return rows.map(Expense.fromMap).toList();
  }

  Future<int> insert(Expense expense) async {
    final db = await DatabaseHelper.instance.db;
    return db.insert('expenses', expense.toMap());
  }

  Future<int> update(Expense expense) async {
    final db = await DatabaseHelper.instance.db;
    return db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> delete(String id) async {
    final db = await DatabaseHelper.instance.db;
    return db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
