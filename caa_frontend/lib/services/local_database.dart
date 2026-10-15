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

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    const path = 'caa_local.db'; // nombre del archivo local en el celular
    final fullPath = join(dbPath, path);

    return await openDatabase(
      fullPath,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // 1. Crear tabla de Categorías
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        icon_path TEXT
      )
    ''');

    // 2. Crear tabla de Pictogramas
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

    // 3. Crear tabla de Tablero (Posiciones X, Y)
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

    // --- SEED DE DATOS INICIALES (OFFLINE) ---
    await db.rawInsert('INSERT INTO categories (id, nombre, icon_path) VALUES (1, "Comida y Bebida", "assets/icons/comida.png")');

    await db.rawInsert('INSERT INTO pictograms (id, palabra, parte_de_la_palabra, is_core, image_path, category_id) VALUES (1, "Yo", "pronombre", 1, "assets/icons/yo.png", NULL)');
    await db.rawInsert('INSERT INTO pictograms (id, palabra, parte_de_la_palabra, is_core, image_path, category_id) VALUES (2, "Quiero", "verbo", 1, "assets/icons/quiero.png", NULL)');
    await db.rawInsert('INSERT INTO pictograms (id, palabra, parte_de_la_palabra, is_core, image_path, category_id) VALUES (3, "Mamá", "sustantivo", 1, "assets/icons/mama.png", NULL)');
    await db.rawInsert('INSERT INTO pictograms (id, palabra, parte_de_la_palabra, is_core, image_path, category_id) VALUES (4, "Comida", "sustantivo", 0, "assets/icons/comida.png", 1)');
    await db.rawInsert('INSERT INTO pictograms (id, palabra, parte_de_la_palabra, is_core, image_path, category_id) VALUES (5, "Agua", "sustantivo", 0, "assets/icons/agua.png", 1)');
    await db.rawInsert('INSERT INTO pictograms (id, palabra, parte_de_la_palabra, is_core, image_path, category_id) VALUES (6, "Manzana", "sustantivo", 0, "assets/icons/manzana.png", 1)');

    await db.rawInsert('INSERT INTO board_items (pictogram_id, position_x, position_y) VALUES (1, 0, 0)');
    await db.rawInsert('INSERT INTO board_items (pictogram_id, position_x, position_y) VALUES (2, 0, 1)');
    await db.rawInsert('INSERT INTO board_items (pictogram_id, position_x, position_y) VALUES (3, 0, 2)');
    await db.rawInsert('INSERT INTO board_items (pictogram_id, position_x, position_y) VALUES (4, 1, 0)');
  }

  // Métodos para consultar localmente sin internet
  Future<List<Map<String, dynamic>>> getBoardItems() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT bi.*, p.palabra, p.parte_de_la_palabra, p.is_core, p.image_path, p.category_id 
      FROM board_items bi
      JOIN pictograms p ON bi.pictogram_id = p.id
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
}