<<<<<<< HEAD
import 'database_service.dart';

class ApiService {
  // ── Tests ──────────────────────────────────────────
  static Future<List<dynamic>> getTests() => DatabaseService.getTests();
  static Future<Map<String, dynamic>> addTest(Map<String, dynamic> t) async {
    final id = await DatabaseService.addTest(t);
    return {'id': id};
=======
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
>>>>>>> 4206e3521fff64e92ee245ff95be2df62502e99f
  }
  static Future<void> updateTest(int id, Map<String, dynamic> t) =>
      DatabaseService.updateTest(id, t);
  static Future<void> deleteTest(int id) => DatabaseService.deleteTest(id);

<<<<<<< HEAD
  // ── Companies ──────────────────────────────────────
  static Future<List<dynamic>> getCompanies() => DatabaseService.getCompanies();
  static Future<Map<String, dynamic>> addCompany(Map<String, dynamic> c) async {
    final id = await DatabaseService.addCompany(c);
    return {'id': id};
=======
  static Future<Map<String, dynamic>> addTest(Map<String, dynamic> test) async {
    final db = await database;
    int id = await db.insert('tests', test);
    return {...test, 'id': id};
>>>>>>> 4206e3521fff64e92ee245ff95be2df62502e99f
  }
  static Future<void> updateCompany(int id, Map<String, dynamic> c) =>
      DatabaseService.updateCompany(id, c);
  static Future<void> deleteCompany(int id) => DatabaseService.deleteCompany(id);

<<<<<<< HEAD
  // ── Patients ───────────────────────────────────────
  static Future<List<dynamic>> getPatients() => DatabaseService.getPatients();
  static Future<List<dynamic>> searchPatients(String q) =>
      DatabaseService.searchPatients(q);
  static Future<Map<String, dynamic>> addPatient(Map<String, dynamic> p) async {
    final id = await DatabaseService.addPatient(p);
    return {'id': id};
=======
  static Future<Map<String, dynamic>> updateTest(int id, Map<String, dynamic> test) async {
    final db = await database;
    await db.update(
      'tests',
      test,
      where: 'id = ?',
      whereArgs: [id],
    );
    return test;
>>>>>>> 4206e3521fff64e92ee245ff95be2df62502e99f
  }
  static Future<void> updatePatient(int id, Map<String, dynamic> p) =>
      DatabaseService.updatePatient(id, p);
  static Future<Map<String, dynamic>?> getPatientById(int id) =>
      DatabaseService.getPatientById(id);

<<<<<<< HEAD
  // ── Visits ─────────────────────────────────────────
  static Future<List<dynamic>> getVisits() => DatabaseService.getVisits();
  static Future<List<dynamic>> getVisitsByPatient(int pid) =>
      DatabaseService.getVisitsByPatient(pid);
  static Future<List<dynamic>> getVisitsByDateRange(String from, String to) =>
      DatabaseService.getVisitsByDateRange(from, to);
  static Future<int> addVisit(Map<String, dynamic> v) =>
      DatabaseService.addVisit(v);

  // ── Visit Tests ────────────────────────────────────
  static Future<List<dynamic>> getVisitTests(int visitId) =>
      DatabaseService.getVisitTests(visitId);
  static Future<List<dynamic>> getPendingResults() =>
      DatabaseService.getPendingResults();
  static Future<void> addVisitTest(Map<String, dynamic> vt) =>
      DatabaseService.addVisitTest(vt);
  static Future<void> updateVisitTestResult(int id, String result) =>
      DatabaseService.updateVisitTestResult(id, result);
  static Future<List<dynamic>> getAllVisitTests() =>
      DatabaseService.getAllVisitTests();

  // ── Users ──────────────────────────────────────────
  static Future<Map<String, dynamic>?> login(String u, String p) =>
      DatabaseService.login(u, p);
  static Future<List<dynamic>> getUsers() => DatabaseService.getUsers();
  static Future<void> addUser(Map<String, dynamic> u) =>
      DatabaseService.addUser(u);
  static Future<void> updateUser(int id, Map<String, dynamic> u) =>
      DatabaseService.updateUser(id, u);
  static Future<void> deleteUser(int id) => DatabaseService.deleteUser(id);
  static Future<void> seedAdmin() => DatabaseService.seedAdminIfNeeded();
=======
  static Future<void> deleteTest(int id) async {
    final db = await database;
    await db.delete(
      'tests',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
>>>>>>> 4206e3521fff64e92ee245ff95be2df62502e99f
}