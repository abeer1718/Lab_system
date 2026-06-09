import 'package:sembast/sembast.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DatabaseService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await databaseFactoryWeb.openDatabase('alfadi_lab.db');
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

  static Future<List<Map<String, dynamic>>> searchPatients(String query) async {
    final db = await database;
    final all = await getPatients();
    final q = query.toLowerCase();
    return all.where((p) =>
      p['name'].toString().toLowerCase().contains(q) ||
      (p['phone'] ?? '').toString().contains(q)
    ).toList();
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

  static Future<List<Map<String, dynamic>>> getVisitsByPatient(int patientId) async {
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

  static Future<List<Map<String, dynamic>>> getVisitTests(int visitId) async {
    final db = await database;
    final records = await _visitTests.find(db,
        finder: Finder(filter: Filter.equals('visit_id', visitId)));
    return records.map((r) => {'id': r.key, ...r.value}).toList();
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

  static Future<void> updateVisitTestResult(int id, String result) async {
    final db = await database;
    await _visitTests.record(id).update(db, {
      'result': result,
      'result_date': DateTime.now().toIso8601String(),
    });
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
}