import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/receipt.dart';
import '../models/vehicle.dart';
import '../models/mileage_entry.dart';

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
      version: 2,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _migrateV1ToV2(db);
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE receipts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        imagePath TEXT NOT NULL,
        amount REAL,
        date TEXT NOT NULL,
        stationName TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL,
        vehicleId INTEGER,
        category TEXT DEFAULT 'gas',
        isArchived INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        make TEXT,
        model TEXT,
        year INTEGER,
        isDefault INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE mileage_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicleId INTEGER,
        date TEXT NOT NULL,
        startOdometer REAL NOT NULL,
        endOdometer REAL NOT NULL,
        purpose TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _migrateV1ToV2(Database db) async {
    await db.execute('''
      CREATE TABLE receipts_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        imagePath TEXT NOT NULL,
        amount REAL,
        date TEXT NOT NULL,
        stationName TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL,
        vehicleId INTEGER,
        category TEXT DEFAULT 'gas',
        isArchived INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      INSERT INTO receipts_new (id, imagePath, amount, date, stationName, notes, createdAt)
      SELECT id, imagePath, amount, date, stationName, notes, createdAt FROM receipts
    ''');

    await db.execute('DROP TABLE receipts');
    await db.execute('ALTER TABLE receipts_new RENAME TO receipts');

    await db.execute('''
      CREATE TABLE vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        make TEXT,
        model TEXT,
        year INTEGER,
        isDefault INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE mileage_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicleId INTEGER,
        date TEXT NOT NULL,
        startOdometer REAL NOT NULL,
        endOdometer REAL NOT NULL,
        purpose TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  // Receipt CRUD
  Future<int> insertReceipt(Receipt receipt) async {
    final db = await database;
    return db.insert('receipts', receipt.toMap());
  }

  Future<List<Receipt>> getReceipts({
    DateTime? startDate,
    DateTime? endDate,
    int? vehicleId,
    String? category,
    bool includeArchived = false,
  }) async {
    final db = await database;

    final conditions = <String>[];
    final whereArgs = <dynamic>[];

    if (startDate != null && endDate != null) {
      conditions.add('date BETWEEN ? AND ?');
      whereArgs.addAll([startDate.toIso8601String(), endDate.toIso8601String()]);
    } else if (startDate != null) {
      conditions.add('date >= ?');
      whereArgs.add(startDate.toIso8601String());
    } else if (endDate != null) {
      conditions.add('date <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    if (vehicleId != null) {
      conditions.add('vehicleId = ?');
      whereArgs.add(vehicleId);
    }

    if (category != null) {
      conditions.add('category = ?');
      whereArgs.add(category);
    }

    if (!includeArchived) {
      conditions.add('isArchived = 0');
    }

    final where = conditions.isNotEmpty ? conditions.join(' AND ') : null;

    final maps = await db.query(
      'receipts',
      where: where,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'date DESC',
    );

    return maps.map((m) => Receipt.fromMap(m)).toList();
  }

  Future<void> deleteReceipt(int id) async {
    final db = await database;
    await db.delete('receipts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> archiveReceipts(List<int> ids) async {
    final db = await database;
    for (final id in ids) {
      await db.update(
        'receipts',
        {'isArchived': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<double> getTotalExpenses({
    DateTime? startDate,
    DateTime? endDate,
    int? vehicleId,
    String? category,
    bool includeArchived = false,
  }) async {
    final db = await database;

    final conditions = <String>[];
    final whereArgs = <dynamic>[];

    if (startDate != null && endDate != null) {
      conditions.add('date BETWEEN ? AND ?');
      whereArgs.addAll([startDate.toIso8601String(), endDate.toIso8601String()]);
    }

    if (vehicleId != null) {
      conditions.add('vehicleId = ?');
      whereArgs.add(vehicleId);
    }

    if (category != null) {
      conditions.add('category = ?');
      whereArgs.add(category);
    }

    if (!includeArchived) {
      conditions.add('isArchived = 0');
    }

    final where = conditions.isNotEmpty ? conditions.join(' AND ') : null;

    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM receipts ${where != null ? 'WHERE $where' : ''}',
      whereArgs.isNotEmpty ? whereArgs : null,
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Vehicle CRUD
  Future<int> insertVehicle(Vehicle vehicle) async {
    final db = await database;
    return db.insert('vehicles', vehicle.toMap());
  }

  Future<List<Vehicle>> getVehicles() async {
    final db = await database;
    final maps = await db.query('vehicles', orderBy: 'name ASC');
    return maps.map((m) => Vehicle.fromMap(m)).toList();
  }

  Future<Vehicle?> getDefaultVehicle() async {
    final db = await database;
    final maps = await db.query(
      'vehicles',
      where: 'isDefault = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Vehicle.fromMap(maps.first);
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    final db = await database;
    await db.update(
      'vehicles',
      vehicle.toMap(),
      where: 'id = ?',
      whereArgs: [vehicle.id],
    );
  }

  Future<void> deleteVehicle(int id) async {
    final db = await database;
    await db.delete('vehicles', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setDefaultVehicle(int id) async {
    final db = await database;
    await db.update('vehicles', {'isDefault': 0});
    await db.update(
      'vehicles',
      {'isDefault': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Mileage CRUD
  Future<int> insertMileageEntry(MileageEntry entry) async {
    final db = await database;
    return db.insert('mileage_entries', entry.toMap());
  }

  Future<List<MileageEntry>> getMileageEntries({
    DateTime? startDate,
    DateTime? endDate,
    int? vehicleId,
  }) async {
    final db = await database;

    final conditions = <String>[];
    final whereArgs = <dynamic>[];

    if (startDate != null && endDate != null) {
      conditions.add('date BETWEEN ? AND ?');
      whereArgs.addAll([startDate.toIso8601String(), endDate.toIso8601String()]);
    }

    if (vehicleId != null) {
      conditions.add('vehicleId = ?');
      whereArgs.add(vehicleId);
    }

    final where = conditions.isNotEmpty ? conditions.join(' AND ') : null;

    final maps = await db.query(
      'mileage_entries',
      where: where,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'date DESC',
    );

    return maps.map((m) => MileageEntry.fromMap(m)).toList();
  }

  Future<double> getTotalMiles({
    DateTime? startDate,
    DateTime? endDate,
    int? vehicleId,
  }) async {
    final db = await database;

    final conditions = <String>[];
    final whereArgs = <dynamic>[];

    if (startDate != null && endDate != null) {
      conditions.add('date BETWEEN ? AND ?');
      whereArgs.addAll([startDate.toIso8601String(), endDate.toIso8601String()]);
    }

    if (vehicleId != null) {
      conditions.add('vehicleId = ?');
      whereArgs.add(vehicleId);
    }

    final where = conditions.isNotEmpty ? conditions.join(' AND ') : null;

    final result = await db.rawQuery(
      'SELECT SUM(endOdometer - startOdometer) as total FROM mileage_entries ${where != null ? 'WHERE $where' : ''}',
      whereArgs.isNotEmpty ? whereArgs : null,
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<void> deleteMileageEntry(int id) async {
    final db = await database;
    await db.delete('mileage_entries', where: 'id = ?', whereArgs: [id]);
  }
}
