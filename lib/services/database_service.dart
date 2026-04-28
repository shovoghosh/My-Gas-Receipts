import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/receipt.dart';

class DatabaseService {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = await getDatabasesPath();
    final dbPath = join(path, 'gas_receipts.db');

    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE receipts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            imagePath TEXT NOT NULL,
            amount REAL,
            date TEXT NOT NULL,
            stationName TEXT,
            notes TEXT,
            createdAt TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertReceipt(Receipt receipt) async {
    final db = await database;
    return db.insert('receipts', receipt.toMap());
  }

  Future<List<Receipt>> getReceipts({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;

    String? where;
    List<dynamic>? whereArgs;

    if (startDate != null && endDate != null) {
      where = 'date BETWEEN ? AND ?';
      whereArgs = [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ];
    } else if (startDate != null) {
      where = 'date >= ?';
      whereArgs = [startDate.toIso8601String()];
    } else if (endDate != null) {
      where = 'date <= ?';
      whereArgs = [endDate.toIso8601String()];
    }

    final maps = await db.query(
      'receipts',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );

    return maps.map((m) => Receipt.fromMap(m)).toList();
  }

  Future<void> deleteReceipt(int id) async {
    final db = await database;
    await db.delete('receipts', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalExpenses({DateTime? startDate, DateTime? endDate}) async {
    final db = await database;

    String? where;
    List<dynamic>? whereArgs;

    if (startDate != null && endDate != null) {
      where = 'date BETWEEN ? AND ?';
      whereArgs = [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ];
    }

    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM receipts ${where != null ? 'WHERE $where' : ''}',
      whereArgs,
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
