import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/item_model.dart';
import '../models/category_model.dart';

// RUBRIK: Relational Database - Singleton service untuk manajemen 2 tabel yang berelasi
class SqliteService {
  // Singleton pattern - hanya satu instance yang digunakan
  static final SqliteService _instance = SqliteService._internal();
  factory SqliteService() => _instance;
  SqliteService._internal();

  Database? _database;

  static const String _dbName = 'campus_lost.db';
  static const String _itemsTable = 'items';
  static const String _categoriesTable = 'categories';

  /// Mendapatkan instance database, membuat jika belum ada
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Inisialisasi dan konfigurasi database SQLite
  Future<Database> _initDatabase() async {
    try {
      final String dbPath = await getDatabasesPath();
      final String path = join(dbPath, _dbName);

      return await openDatabase(
        path,
        version: 3,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        // RUBRIK: Relational Database - Aktifkan foreign key support di SQLite
        onOpen: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      );
    } catch (e) {
      throw Exception('Gagal menginisialisasi database: $e');
    }
  }

  /// Membuat semua tabel saat database pertama kali dibuat
  Future<void> _onCreate(Database db, int version) async {
    // RUBRIK: Relational Database - Tabel 1: categories (tabel induk/parent)
    await db.execute('''
      CREATE TABLE $_categoriesTable (
        id   INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT    NOT NULL UNIQUE
      )
    ''');

    // RUBRIK: Relational Database - Tabel 2: items, berelasi ke categories via FOREIGN KEY
    await db.execute('''
      CREATE TABLE $_itemsTable (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        namaBarang  TEXT    NOT NULL,
        deskripsi   TEXT    NOT NULL,
        fotoPath    TEXT    NOT NULL,
        lokasi      TEXT    NOT NULL,
        userId      TEXT    NOT NULL,
        isSynced    INTEGER NOT NULL DEFAULT 0,
        category_id INTEGER NOT NULL DEFAULT 1 REFERENCES $_categoriesTable(id)
      )
    ''');

    // Isi data awal kategori (seed data)
    await _seedDefaultCategories(db);
  }

  /// Migrasi database ke versi baru
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Reset total karena perubahan skema besar
    await db.execute('DROP TABLE IF EXISTS $_itemsTable');
    await db.execute('DROP TABLE IF EXISTS $_categoriesTable');
    await _onCreate(db, newVersion);
  }

  /// Mengisi data kategori default ke dalam database
  Future<void> _seedDefaultCategories(Database db) async {
    final defaultCategories = [
      'Elektronik',
      'Dompet & Tas',
      'Pakaian',
      'Dokumen & Kartu',
      'Kunci',
      'Alat Tulis',
      'Lainnya',
    ];
    for (final name in defaultCategories) {
      await db.insert(_categoriesTable, {'name': name});
    }
  }

  // ══════════════════════════════════════
  // CRUD UNTUK TABEL: categories
  // ══════════════════════════════════════

  // RUBRIK: Relational Database - READ categories
  /// Mengambil semua kategori dari tabel categories
  Future<List<Category>> getAllCategories() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _categoriesTable,
        orderBy: 'id ASC',
      );
      return maps.map((m) => Category.fromMap(m)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil daftar kategori: $e');
    }
  }

  // RUBRIK: Relational Database - INSERT category
  /// Menambahkan kategori baru
  Future<int> insertCategory(Category category) async {
    try {
      final db = await database;
      return await db.insert(
        _categoriesTable,
        category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } catch (e) {
      throw Exception('Gagal menyimpan kategori: $e');
    }
  }

  // ══════════════════════════════════════
  // CRUD UNTUK TABEL: items
  // ══════════════════════════════════════

  // RUBRIK: CRUD SQLite - INSERT
  /// Menyimpan item baru ke database lokal sebagai Draft
  Future<int> insertItem(Item item) async {
    try {
      final db = await database;
      return await db.insert(
        _itemsTable,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw Exception('Gagal menyimpan item ke database lokal: $e');
    }
  }

  // RUBRIK: CRUD SQLite - READ (JOIN dengan tabel categories)
  /// Mengambil semua item yang belum disinkronisasi, sekaligus JOIN ke tabel categories
  Future<List<Item>> getUnsyncedItems() async {
    try {
      final db = await database;
      // RUBRIK: Relational Database - JOIN query untuk menggabungkan 2 tabel
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT 
          i.id, i.namaBarang, i.deskripsi, i.fotoPath, i.lokasi,
          i.userId, i.isSynced, i.category_id,
          c.name AS categoryName
        FROM $_itemsTable i
        LEFT JOIN $_categoriesTable c ON i.category_id = c.id
        WHERE i.isSynced = 0
        ORDER BY i.id DESC
      ''');
      return maps.map((map) => Item.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil daftar draft: $e');
    }
  }

  // RUBRIK: CRUD SQLite - UPDATE (edit draft sebelum sync)
  /// Memperbarui data item yang sudah ada di database lokal
  Future<void> updateItem(Item item) async {
    try {
      final db = await database;
      await db.update(
        _itemsTable,
        item.toMap(),
        where: 'id = ?',
        whereArgs: [item.id],
      );
    } catch (e) {
      throw Exception('Gagal memperbarui item: $e');
    }
  }

  // RUBRIK: CRUD SQLite - DELETE
  /// Menghapus item dari database lokal setelah berhasil disinkronisasi
  Future<void> deleteItem(int id) async {
    try {
      final db = await database;
      await db.delete(
        _itemsTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Gagal menghapus item dari database lokal: $e');
    }
  }

  /// Menutup koneksi database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
