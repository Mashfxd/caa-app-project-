import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('caa_local.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final fullPath = join(dbPath, fileName);

    return await openDatabase(
      fullPath,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        icon_path TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE pictograms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        palabra TEXT NOT NULL,
        parte_de_la_palabra TEXT,
        is_core INTEGER NOT NULL,
        image_path TEXT NOT NULL,
        category_id INTEGER,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE board_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pictogram_id INTEGER,
        position_x INTEGER NOT NULL,
        position_y INTEGER NOT NULL,
        is_hidden INTEGER DEFAULT 0,
        FOREIGN KEY (pictogram_id) REFERENCES pictograms (id)
      )
    ''');

    // Datos semilla locales para uso 100% offline desde el primer arranque
    await db.rawInsert(
        'INSERT INTO categories (id, nombre, icon_path) VALUES (1, "Comida y Bebida", "https://api.arasaac.org/v1/pictograms/2443")');

    await db.rawInsert(
        'INSERT INTO pictograms (id, palabra, parte_de_la_palabra, is_core, image_path, category_id) VALUES (1, "Yo", "pronombre", 1, "https://api.arasaac.org/v1/pictograms/31807", NULL)');
    await db.rawInsert(
        'INSERT INTO pictograms (id, palabra, parte_de_la_palabra, is_core, image_path, category_id) VALUES (2, "Quiero", "verbo", 1, "https://api.arasaac.org/v1/pictograms/5441", NULL)');
    await db.rawInsert(
        'INSERT INTO pictograms (id, palabra, parte_de_la_palabra, is_core, image_path, category_id) VALUES (3, "Mamá", "sustantivo", 1, "https://api.arasaac.org/v1/pictograms/2458", NULL)');
    await db.rawInsert(
        'INSERT INTO pictograms (id, palabra, parte_de_la_palabra, is_core, image_path, category_id) VALUES (4, "Comida", "sustantivo", 0, "https://api.arasaac.org/v1/pictograms/2443", 1)');
    await db.rawInsert(
        'INSERT INTO pictograms (id, palabra, parte_de_la_palabra, is_core, image_path, category_id) VALUES (5, "Agua", "sustantivo", 0, "https://api.arasaac.org/v1/pictograms/2248", 1)');
    await db.rawInsert(
        'INSERT INTO pictograms (id, palabra, parte_de_la_palabra, is_core, image_path, category_id) VALUES (6, "Manzana", "sustantivo", 0, "https://api.arasaac.org/v1/pictograms/2462", 1)');

    await db.rawInsert(
        'INSERT INTO board_items (pictogram_id, position_x, position_y) VALUES (1, 0, 0)');
    await db.rawInsert(
        'INSERT INTO board_items (pictogram_id, position_x, position_y) VALUES (2, 0, 1)');
    await db.rawInsert(
        'INSERT INTO board_items (pictogram_id, position_x, position_y) VALUES (3, 0, 2)');
    await db.rawInsert(
        'INSERT INTO board_items (pictogram_id, position_x, position_y) VALUES (4, 1, 0)');
  }

  Future<List<Map<String, dynamic>>> getBoardItems() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT bi.id, bi.pictogram_id, bi.position_x, bi.position_y, bi.is_hidden,
             p.palabra, p.parte_de_la_palabra, p.is_core, p.image_path, p.category_id 
      FROM board_items bi
      JOIN pictograms p ON bi.pictogram_id = p.id
      WHERE bi.is_hidden = 0
    ''');
  }

  Future<List<Map<String, dynamic>>> getCategoryPictograms(int categoryId) async {
    final db = await database;
    return await db.query(
      'pictograms',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
  }

  /// Sincroniza los datos recibidos del endpoint /sync de FastAPI hacia SQLite local
  Future<void> syncFromBackend(Map<String, dynamic> data) async {
    final db = await database;
    await db.transaction((txn) async {
      final categories = data['categories'] as List<dynamic>? ?? [];
      for (final c in categories) {
        await txn.insert(
          'categories',
          {
            'id': c['id'],
            'nombre': c['nombre'],
            'icon_path': c['icon_url'] ?? '',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      final pictograms = data['pictograms'] as List<dynamic>? ?? [];
      for (final p in pictograms) {
        await txn.insert(
          'pictograms',
          {
            'id': p['id'],
            'palabra': p['palabra'],
            'parte_de_la_palabra': p['parte_de_la_palabra'],
            'is_core': (p['is_core'] == true || p['is_core'] == 1) ? 1 : 0,
            'image_path': p['image_url'] ?? p['image_path'] ?? '',
            'category_id': p['category_id'],
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      final boardItems = data['board_items'] as List<dynamic>? ?? [];
      for (final b in boardItems) {
        await txn.insert(
          'board_items',
          {
            'id': b['id'],
            'pictogram_id': b['pictogram_id'],
            'position_x': b['position_x'],
            'position_y': b['position_y'],
            'is_hidden': (b['is_hidden'] == true || b['is_hidden'] == 1) ? 1 : 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}
