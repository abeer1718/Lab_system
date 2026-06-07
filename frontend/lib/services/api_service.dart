import 'dart:convert';
import 'package:http/http.dart' as http;

const String baseUrl = 'http://localhost:5000';

class ApiService {
  static Future<List<dynamic>> getTests() async {
    final response = await http.get(Uri.parse('$baseUrl/tests'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('فشل في تحميل الفحوصات');
    }
  }

  static Future<Map<String, dynamic>> addTest(Map<String, dynamic> test) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tests'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(test),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('فشل في إضافة الفحص');
    }
  }

  static Future<Map<String, dynamic>> updateTest(int id, Map<String, dynamic> test) async {
    final response = await http.put(
      Uri.parse('$baseUrl/tests/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(test),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('فشل في تعديل الفحص');
    }
  }

  static Future<void> deleteTest(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/tests/$id'));
    if (response.statusCode != 200) {
      throw Exception('فشل في حذف الفحص');
    }
  }
}