import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';

class ApiService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    // الحصول على مسار AppData/Local
    final String localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
    final String appDir = join(localAppData, 'AlFadiLab');
    
    // إنشاء المجلد إذا لم يكن موجوداً
    await Directory(appDir).create(recursive: true);
    final path = join(appDir, 'lab_system.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // إنشاء جدول الفحوصات
        await db.execute('''
          CREATE TABLE tests (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            price REAL NOT NULL,
            normal_range TEXT,
            category TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
          )
        ''');
        // إنشاء جدول الشركات
        await db.execute('''
          CREATE TABLE companies (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            discount_percentage REAL DEFAULT 0,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      },
    );
  }

  static Future<List<dynamic>> getTests() async {
    final db = await database;
    return await db.query('tests', orderBy: 'id DESC');
  }

  static Future<Map<String, dynamic>> addTest(Map<String, dynamic> test) async {
    final db = await database;
    int id = await db.insert('tests', test);
    return {...test, 'id': id};
  }

  static Future<Map<String, dynamic>> updateTest(int id, Map<String, dynamic> test) async {
    final db = await database;
    await db.update(
      'tests',
      test,
      where: 'id = ?',
      whereArgs: [id],
    );
    return test;
  }

  static Future<void> deleteTest(int id) async {
    final db = await database;
    await db.delete(
      'tests',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}