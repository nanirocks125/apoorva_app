import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:apoorva_app/model/category/category.dart';

class CategoryLocalDatabase {
  static final CategoryLocalDatabase instance = CategoryLocalDatabase._init();
  static Database? _database;

  CategoryLocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('apoorva_categories.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        currentStock REAL,
        isHotkey INTEGER,
        billMachineNumber INTEGER
      )
    ''');
  }

  // 1. లోకల్ SQLite నుంచి కేటగిరీలను సురక్షితంగా తెచ్చుకోవడం (Type Safe Mapping)
  Future<List<Category>> getCachedCategories() async {
    final db = await instance.database;
    final result = await db.query(
      'categories',
      orderBy: 'billMachineNumber ASC',
    );

    if (result.isEmpty) return [];

    return result.map((jsonMap) {
      // 🟢 SQLite ఇచ్చే int (0 లేదా 1) ని bool కి సేఫ్‌గా కన్వర్ట్ చేస్తున్నాం
      final mutableMap = Map<String, dynamic>.from(jsonMap);
      final hotkeyVal = mutableMap['isHotkey'];

      if (hotkeyVal is int) {
        mutableMap['isHotkey'] = hotkeyVal == 1;
      } else if (hotkeyVal is String) {
        mutableMap['isHotkey'] = hotkeyVal.toLowerCase() == 'true';
      }

      return Category.fromJson(mutableMap);
    }).toList();
  }

  // 2. రిమోట్ నుంచి వచ్చిన డేటాని లోకల్‌లో సేవ్ చేయడం (Sync / Cache)
  Future<void> cacheCategories(List<Category> categories) async {
    final db = await instance.database;
    final batch = db.batch();

    for (var cat in categories) {
      batch.insert('categories', {
        'id': cat.id,
        'name': cat.name,
        'currentStock': cat.currentStock,
        'isHotkey': cat.isHotkey
            ? 1
            : 0, // 🟢 bool నుండి int (1 లేదా 0) కి మార్చి సేవ్ చేస్తున్నాం
        'billMachineNumber': cat.billMachineNumber,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }
}
