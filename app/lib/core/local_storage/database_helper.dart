import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('cart.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const defaultIdType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';
    const boolType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE cart (
  id $defaultIdType,
  name $textType,
  imagePath $textType,
  price $realType,
  unit $textType,
  quantity $integerType,
  brand $textType,
  isOrganic $boolType,
  rating $realType,
  reviewCount $integerType
)
''');

    await db.execute('''
CREATE TABLE recent_searches (
  query $defaultIdType,
  timestamp $integerType
)
''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
CREATE TABLE recent_searches (
  query TEXT PRIMARY KEY,
  timestamp INTEGER NOT NULL
)
''');
    }
  }

  // Cart is now synced to Supabase — these stubs prevent call-site breakage
  // during migration. They can be fully removed if no other code calls them.
  Future<void> saveCart(List<dynamic> items) async {}
  Future<List<dynamic>> getCart() async => [];
  Future<void> clearCart() async {}

  Future<void> addRecentSearch(String query) async {
    final db = await instance.database;
    await db.insert('recent_searches', {
      'query': query,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // Keep only top 10
    final maps = await db.query('recent_searches', orderBy: 'timestamp DESC');
    if (maps.length > 10) {
      final oldQueries = maps.sublist(10).map((m) => m['query']).toList();
      for (final old in oldQueries) {
        await db.delete(
          'recent_searches',
          where: 'query = ?',
          whereArgs: [old],
        );
      }
    }
  }

  Future<List<String>> getRecentSearches() async {
    final db = await instance.database;
    final maps = await db.query('recent_searches', orderBy: 'timestamp DESC');
    return maps.map((map) => map['query'] as String).toList();
  }

  Future<void> clearRecentSearches() async {
    final db = await instance.database;
    await db.delete('recent_searches');
  }
}
