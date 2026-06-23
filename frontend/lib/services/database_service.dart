import 'package:sembast/sembast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    hide Database, DatabaseFactory;
import 'package:sembast_sqflite/sembast_sqflite.dart';
import 'package:sembast_web/sembast_web.dart';

class DatabaseService {
  static Database? _db;
  static const String dbName = 'alfadi_lab.db';

  static Future<Database> get database async {
    if (_db != null) return _db!;

    String dbPath;
    DatabaseFactory factory;

    if (kIsWeb) {
      factory = databaseFactoryWeb;
      dbPath = dbName;
    } else {
      if (Platform.isWindows || Platform.isLinux) {
        sqfliteFfiInit();
      }
      factory = getDatabaseFactorySqflite(databaseFactoryFfi);

      if (Platform.isWindows) {
        final String exePath = File(Platform.resolvedExecutable).parent.path;
        dbPath = join(exePath, dbName);
      } else {
        final appDocumentDir = await getApplicationDocumentsDirectory();
        dbPath = join(appDocumentDir.path, dbName);
      }
    }

    _db = await factory.openDatabase(dbPath);
    return _db!;
  }

  // ══════════════════════════════════════════
  // TESTS
  // ══════════════════════════════════════════
  static final _tests = intMapStoreFactory.store('tests');

  static Future<List<Map<String, dynamic>>> getTests() async {
    final db = await database;
    final records = await _tests.find(db,
        finder: Finder(sortOrders: [SortOrder('name')]));
    return records.map((r) => {'id': r.key, ...r.value}).toList();
  }

  static Future<int> addTest(Map<String, dynamic> data) async {
    final db = await database;
    return await _tests.add(db, Map<String, dynamic>.from(data));
  }

  static Future<void> updateTest(int id, Map<String, dynamic> data) async {
    final db = await database;
    await _tests.record(id).update(db, Map<String, dynamic>.from(data));
  }

  static Future<void> deleteTest(int id) async {
    final db = await database;
    await _tests.record(id).delete(db);
  }

  // ══════════════════════════════════════════
  // COMPANIES
  // ══════════════════════════════════════════
  static final _companies = intMapStoreFactory.store('companies');

  static Future<List<Map<String, dynamic>>> getCompanies() async {
    final db = await database;
    final records = await _companies.find(db,
        finder: Finder(sortOrders: [SortOrder('name')]));
    return records.map((r) => {'id': r.key, ...r.value}).toList();
  }

  static Future<int> addCompany(Map<String, dynamic> data) async {
    final db = await database;
    return await _companies.add(db, Map<String, dynamic>.from(data));
  }

  static Future<void> updateCompany(int id, Map<String, dynamic> data) async {
    final db = await database;
    await _companies.record(id).update(db, Map<String, dynamic>.from(data));
  }

  static Future<void> deleteCompany(int id) async {
    final db = await database;
    await _companies.record(id).delete(db);
  }

  // ══════════════════════════════════════════
  // PATIENTS
  // ══════════════════════════════════════════
  static final _patients = intMapStoreFactory.store('patients');

  static Future<List<Map<String, dynamic>>> getPatients() async {
    final db = await database;
    final records = await _patients.find(db,
        finder: Finder(sortOrders: [SortOrder('name')]));
    return records.map((r) => {'id': r.key, ...r.value}).toList();
  }

  static Future<List<Map<String, dynamic>>> searchPatients(
      String query) async {
    final all = await getPatients();
    final q = query.toLowerCase();
    return all
        .where((p) =>
            p['name'].toString().toLowerCase().contains(q) ||
            (p['phone'] ?? '').toString().contains(q))
        .toList();
  }

  static Future<int> addPatient(Map<String, dynamic> data) async {
    final db = await database;
    return await _patients.add(db, Map<String, dynamic>.from(data));
  }

  static Future<void> updatePatient(int id, Map<String, dynamic> data) async {
    final db = await database;
    await _patients.record(id).update(db, Map<String, dynamic>.from(data));
  }

  static Future<Map<String, dynamic>?> getPatientById(int id) async {
    final db = await database;
    final record = await _patients.record(id).get(db);
    if (record == null) return null;
    return {'id': id, ...record};
  }

  // ══════════════════════════════════════════
  // VISITS
  // ══════════════════════════════════════════
  static final _visits = intMapStoreFactory.store('visits');

  static Future<List<Map<String, dynamic>>> getVisits() async {
    final db = await database;
    final records = await _visits.find(db,
        finder: Finder(sortOrders: [SortOrder('date', false)]));
    return records.map((r) => {'id': r.key, ...r.value}).toList();
  }

  static Future<List<Map<String, dynamic>>> getVisitsByPatient(
      int patientId) async {
    final db = await database;
    final records = await _visits.find(db,
        finder: Finder(
          filter: Filter.equals('patient_id', patientId),
          sortOrders: [SortOrder('date', false)],
        ));
    return records.map((r) => {'id': r.key, ...r.value}).toList();
  }

  static Future<List<Map<String, dynamic>>> getVisitsByDateRange(
      String from, String to) async {
    final db = await database;
    final records = await _visits.find(db,
        finder: Finder(
          filter: Filter.and([
            Filter.greaterThanOrEquals('date', from),
            Filter.lessThanOrEquals('date', to),
          ]),
          sortOrders: [SortOrder('date', false)],
        ));
    return records.map((r) => {'id': r.key, ...r.value}).toList();
  }

  static Future<int> addVisit(Map<String, dynamic> data) async {
    final db = await database;
    return await _visits.add(db, Map<String, dynamic>.from(data));
  }

  // ══════════════════════════════════════════
  // VISIT TESTS
  // ══════════════════════════════════════════
  static final _visitTests = intMapStoreFactory.store('visit_tests');

  /// جيب فحوصات الزيارة مع إثراءها بـ unit و category من جدول الفحوصات
  static Future<List<Map<String, dynamic>>> getVisitTests(
      int visitId) async {
    final db = await database;
    final records = await _visitTests.find(db,
        finder: Finder(filter: Filter.equals('visit_id', visitId)));

    final result = <Map<String, dynamic>>[];
    for (final r in records) {
      final vt = {'id': r.key, ...r.value};

      // جيب بيانات الفحص الأصلي عشان تاخد unit و category
      final testId = vt['test_id'] as int?;
      if (testId != null) {
        final testRecord = await _tests.record(testId).get(db);
        if (testRecord != null) {
          // unit: لو محفوظة في visit_tests خد منها، لو لأ خد من tests
          vt['unit'] = (vt['unit'] as String? ?? '').isNotEmpty
              ? vt['unit']
              : (testRecord['unit'] ?? '');
          // category دايماً من جدول الفحوصات
          vt['category'] = testRecord['category'] ?? 'أخرى';
        }
      }
      result.add(vt);
    }
    return result;
  }

  static Future<List<Map<String, dynamic>>> getPendingResults() async {
    final db = await database;
    final records = await _visitTests.find(db,
        finder: Finder(
          filter: Filter.or([
            Filter.isNull('result'),
            Filter.equals('result', ''),
          ]),
        ));
    return records.map((r) => {'id': r.key, ...r.value}).toList();
  }

  static Future<int> addVisitTest(Map<String, dynamic> data) async {
    final db = await database;
    return await _visitTests.add(db, Map<String, dynamic>.from(data));
  }

  /// تحديث النتيجة مع حفظ الوحدة
  static Future<void> updateVisitTestResult(
      int id, String result, {String unit = ''}) async {
    final db = await database;
    final updateData = <String, dynamic>{
      'result': result,
      'result_date': DateTime.now().toIso8601String(),
    };
    if (unit.isNotEmpty) {
      updateData['unit'] = unit;
    }
    await _visitTests.record(id).update(db, updateData);
  }

  static Future<List<Map<String, dynamic>>> getAllVisitTests() async {
    final db = await database;
    final records = await _visitTests.find(db);
    return records.map((r) => {'id': r.key, ...r.value}).toList();
  }

  // ══════════════════════════════════════════
  // USERS
  // ══════════════════════════════════════════
  static final _users = intMapStoreFactory.store('users');

  static String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  static Future<void> seedAdminIfNeeded() async {
    final db = await database;
    final count = await _users.count(db);
    if (count == 0) {
      await _users.add(db, {
        'username': 'admin',
        'password': _hashPassword('admin123'),
        'name': 'مدير النظام',
        'role': 'admin',
        'email': 'admin@alfadi-lab.com',
        'active': true,
      });
    }
  }

  static Future<Map<String, dynamic>?> login(
      String username, String password) async {
    final db = await database;
    final records = await _users.find(db,
        finder: Finder(
          filter: Filter.and([
            Filter.equals('username', username),
            Filter.equals('password', _hashPassword(password)),
            Filter.equals('active', true),
          ]),
        ));
    if (records.isEmpty) return null;
    final r = records.first;
    return {'id': r.key, ...r.value};
  }

  static Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    final records = await _users.find(db);
    return records.map((r) => {'id': r.key, ...r.value}).toList();
  }

  static Future<int> addUser(Map<String, dynamic> data) async {
    final db = await database;
    final toSave = Map<String, dynamic>.from(data);
    toSave['password'] = _hashPassword(toSave['password']);
    return await _users.add(db, toSave);
  }

  static Future<void> updateUser(int id, Map<String, dynamic> data) async {
    final db = await database;
    final toSave = Map<String, dynamic>.from(data);
    if (toSave.containsKey('password') && toSave['password'] != '') {
      toSave['password'] = _hashPassword(toSave['password']);
    } else {
      toSave.remove('password');
    }
    await _users.record(id).update(db, toSave);
  }

  static Future<void> deleteUser(int id) async {
    final db = await database;
    await _users.record(id).delete(db);
  }

  // ══════════════════════════════════════════
  // SHIFTS
  // ══════════════════════════════════════════
  static final _shifts = intMapStoreFactory.store('shifts');

  static Future<List<Map<String, dynamic>>> getShifts() async {
    final db = await database;
    final records = await _shifts.find(db,
        finder: Finder(sortOrders: [SortOrder('start_time')]));
    return records.map((r) => {'id': r.key, ...r.value}).toList();
  }

  static Future<int> addShift(Map<String, dynamic> data) async {
    final db = await database;
    return await _shifts.add(db, Map<String, dynamic>.from(data));
  }

  static Future<void> updateShift(int id, Map<String, dynamic> data) async {
    final db = await database;
    await _shifts.record(id).update(db, Map<String, dynamic>.from(data));
  }

  static Future<void> deleteShift(int id) async {
    final db = await database;
    await _shifts.record(id).delete(db);
  }

  static Future<Map<String, dynamic>?> getShiftForTime(
      String timeStr) async {
    final shifts = await getShifts();
    for (final s in shifts) {
      final start = s['start_time'] as String;
      final end   = s['end_time']   as String;
      if (_timeInRange(timeStr, start, end)) return s;
    }
    return null;
  }

  static bool _timeInRange(String time, String start, String end) {
    int toMinutes(String t) {
      final parts = t.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }

    final t = toMinutes(time);
    final s = toMinutes(start);
    final e = toMinutes(end);
    if (s <= e) return t >= s && t < e;
    return t >= s || t < e;
  }

  // ══════════════════════════════════════════
  // SHIFT SESSIONS
  // ══════════════════════════════════════════
  static final _shiftSessions = intMapStoreFactory.store('shift_sessions');

  static Future<int> openShiftSession(Map<String, dynamic> data) async {
    final db = await database;
    return await _shiftSessions.add(db, Map<String, dynamic>.from(data));
  }

  static Future<void> closeShiftSession(int id, String endTime) async {
    final db = await database;
    await _shiftSessions.record(id).update(db, {
      'end_time': endTime,
      'status': 'closed',
    });
  }

  static Future<Map<String, dynamic>?> getOpenSession(int userId) async {
    final db = await database;
    final records = await _shiftSessions.find(db,
        finder: Finder(
          filter: Filter.and([
            Filter.equals('user_id', userId),
            Filter.equals('status', 'open'),
          ]),
        ));
    if (records.isEmpty) return null;
    final r = records.first;
    return {'id': r.key, ...r.value};
  }

  static Future<List<Map<String, dynamic>>> getVisitsBySession(
      int sessionId) async {
    final db = await database;
    final records = await _visits.find(db,
        finder: Finder(
          filter: Filter.equals('session_id', sessionId),
          sortOrders: [SortOrder('date', false)],
        ));
    return records.map((r) => {'id': r.key, ...r.value}).toList();
  }
}