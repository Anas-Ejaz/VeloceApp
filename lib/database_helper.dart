import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('veloce_fleet.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE vehicles (
        id TEXT PRIMARY KEY,
        name TEXT,
        brand TEXT,
        category TEXT,
        horsepower REAL,
        zeroToSixty REAL,
        perDayCharges REAL,
        imageUrl TEXT,
        description TEXT,
        isAvailable INTEGER,
        features TEXT,
        rating REAL,
        reviewCount INTEGER,
        color TEXT,
        year INTEGER
      )
    ''');
  }

  // Local caching/sync functionality
  Future<void> insertOrUpdateLocal(Vehicle vehicle) async {
    final db = await instance.database;
    await db.insert('vehicles', vehicle.toSqfliteMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteLocal(String id) async {
    final db = await instance.database;
    await db.delete('vehicles', where: 'id = ?', whereArgs: [id]);
  }

  // Local Sqflite se saari cached gaariyan uthane ke liye function
  Future<List<Vehicle>> getCachedVehicles() async {
    final db = await instance.database;
    final result = await db.query('vehicles', orderBy: 'brand');
    return result.map((json) => Vehicle.fromSqflite(json)).toList();
  }

  // Local Sqflite se top 6 featured gaariyan uthane ke liye function
  Future<List<Vehicle>> getFeaturedCachedVehicles() async {
    final db = await instance.database;
    final result = await db.query('vehicles', orderBy: 'brand', limit: 6);
    return result.map((json) => Vehicle.fromSqflite(json)).toList();
  }

}