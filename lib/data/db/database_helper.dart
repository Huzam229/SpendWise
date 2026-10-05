import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  DatabaseHelper._();
  Database? _db;

  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'spendwise.db');
    return openDatabase(path, version: 1, onCreate: (db, _) {
      return db.execute('''
        CREATE TABLE expenses(
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          amount REAL NOT NULL,
          is_income INTEGER NOT NULL,
          category TEXT NOT NULL,
          date TEXT NOT NULL,
          note TEXT
        )''');
    });
  }
}
