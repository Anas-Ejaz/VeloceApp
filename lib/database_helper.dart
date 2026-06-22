import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _db;

  static const String _tableName = 'vehicles_cache';

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'veloce_cache.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
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
      },
    );
  }

  // ─── Read all cached vehicles ────────────────────────────────────────────
  Future<List<Vehicle>> getCachedVehicles() async {
    final db = await database;
    final rows = await db.query(_tableName, orderBy: 'brand ASC');
    return rows.map(_vehicleFromRow).toList();
  }

  Future<void> replaceAll(List<Vehicle> vehicles) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(_tableName);
      for (final v in vehicles) {
        await txn.insert(
          _tableName,
          _vehicleToRow(v),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> clearCache() async {
    final db = await database;
    await db.delete(_tableName);
  }

  Map<String, dynamic> _vehicleToRow(Vehicle v) => {
    'id': v.id,
    'name': v.name,
    'brand': v.brand,
    'category': v.category,
    'horsepower': v.horsepower,
    'zeroToSixty': v.zeroToSixty,
    'perDayCharges': v.perDayCharges,
    'imageUrl': v.imageUrl,
    'description': v.description,
    'isAvailable': v.isAvailable ? 1 : 0,
    'features': v.features.join('||'),
    'rating': v.rating,
    'reviewCount': v.reviewCount,
    'color': v.color,
    'year': v.year,
  };

  Vehicle _vehicleFromRow(Map<String, dynamic> row) => Vehicle(
    id: row['id'] as String,
    name: row['name'] as String? ?? '',
    brand: row['brand'] as String? ?? '',
    category: row['category'] as String? ?? 'Sports',
    horsepower: (row['horsepower'] as num?)?.toDouble() ?? 0,
    zeroToSixty: (row['zeroToSixty'] as num?)?.toDouble() ?? 0,
    perDayCharges: (row['perDayCharges'] as num?)?.toDouble() ?? 0,
    imageUrl: row['imageUrl'] as String? ?? '',
    description: row['description'] as String? ?? '',
    isAvailable: (row['isAvailable'] as int? ?? 1) == 1,
    features: (row['features'] as String? ?? '')
        .split('||')
        .where((f) => f.isNotEmpty)
        .toList(),
    rating: (row['rating'] as num?)?.toDouble() ?? 4.8,
    reviewCount: (row['reviewCount'] as int?) ?? 124,
    color: row['color'] as String? ?? 'Midnight Black',
    year: (row['year'] as int?) ?? 2024,
  );
}