import 'database_service.dart';

class ApiService {
  // ── Tests ──────────────────────────────────────────
  static Future<List<dynamic>> getTests() => DatabaseService.getTests();
  
  static Future<Map<String, dynamic>> addTest(Map<String, dynamic> t) async {
    final id = await DatabaseService.addTest(t);
    return {'id': id};
  }

  static Future<void> updateTest(int id, Map<String, dynamic> t) =>
      DatabaseService.updateTest(id, t);

  static Future<void> deleteTest(int id) => DatabaseService.deleteTest(id);

  // ── Companies ──────────────────────────────────────
  static Future<List<dynamic>> getCompanies() => DatabaseService.getCompanies();
  static Future<Map<String, dynamic>> addCompany(Map<String, dynamic> c) async {
    final id = await DatabaseService.addCompany(c);
    return {'id': id};
  }
  static Future<void> updateCompany(int id, Map<String, dynamic> c) =>
      DatabaseService.updateCompany(id, c);
  static Future<void> deleteCompany(int id) => DatabaseService.deleteCompany(id);

  // ── Patients ───────────────────────────────────────
  static Future<List<dynamic>> getPatients() => DatabaseService.getPatients();
  static Future<List<dynamic>> searchPatients(String q) =>
      DatabaseService.searchPatients(q);
  static Future<Map<String, dynamic>> addPatient(Map<String, dynamic> p) async {
    final id = await DatabaseService.addPatient(p);
    return {'id': id};
  }
  static Future<void> updatePatient(int id, Map<String, dynamic> p) =>
      DatabaseService.updatePatient(id, p);
  static Future<Map<String, dynamic>?> getPatientById(int id) =>
      DatabaseService.getPatientById(id);

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
}