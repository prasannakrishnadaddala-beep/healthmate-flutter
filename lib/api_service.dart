import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ── Change this to your Railway URL ─────────────────────────────────────────
  static const String baseUrl = 'https://web-production-e4d47.up.railway.app';

  static String? _sessionCookie;

  // ── Cookie / session handling ─────────────────────────────────────────────
  static Future<void> _loadCookie() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionCookie = prefs.getString('session_cookie');
  }

  static Future<void> _saveCookie(String cookie) async {
    _sessionCookie = cookie;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_cookie', cookie);
  }

  static Future<void> clearSession() async {
    _sessionCookie = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_cookie');
  }

  static Map<String, String> get _headers {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_sessionCookie != null) h['Cookie'] = _sessionCookie!;
    return h;
  }

  static void _extractCookie(http.Response res) {
    final raw = res.headers['set-cookie'];
    if (raw != null && raw.isNotEmpty) {
      // Extract just the session value
      final match = RegExp(r'session=[^;]+').firstMatch(raw);
      if (match != null) _saveCookie(match.group(0)!);
    }
  }

  // ── Generic request helpers ───────────────────────────────────────────────
  static Future<Map<String, dynamic>> _get(String path) async {
    await _loadCookie();
    final res = await http
        .get(Uri.parse('$baseUrl$path'), headers: _headers)
        .timeout(const Duration(seconds: 30));
    _extractCookie(res);
    if (res.statusCode == 401) throw UnauthorizedException();
    return json.decode(res.body) as Map<String, dynamic>;
  }

  static Future<List<dynamic>> _getList(String path) async {
    await _loadCookie();
    final res = await http
        .get(Uri.parse('$baseUrl$path'), headers: _headers)
        .timeout(const Duration(seconds: 30));
    _extractCookie(res);
    if (res.statusCode == 401) throw UnauthorizedException();
    final body = json.decode(res.body);
    return body is List ? body : [];
  }

  static Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> data) async {
    await _loadCookie();
    final res = await http
        .post(Uri.parse('$baseUrl$path'),
            headers: _headers, body: json.encode(data))
        .timeout(const Duration(seconds: 60));
    _extractCookie(res);
    if (res.statusCode == 401) throw UnauthorizedException();
    return json.decode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> _patch(String path, Map<String, dynamic> data) async {
    await _loadCookie();
    final res = await http
        .patch(Uri.parse('$baseUrl$path'),
            headers: _headers, body: json.encode(data))
        .timeout(const Duration(seconds: 30));
    _extractCookie(res);
    if (res.statusCode == 401) throw UnauthorizedException();
    return json.decode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> _delete(String path) async {
    await _loadCookie();
    final res = await http
        .delete(Uri.parse('$baseUrl$path'), headers: _headers)
        .timeout(const Duration(seconds: 30));
    _extractCookie(res);
    if (res.statusCode == 401) throw UnauthorizedException();
    return json.decode(res.body) as Map<String, dynamic>;
  }

  // ── Auth ─────────────────────────────────────────────────────────────────
  static Future<bool> login(String username, String password) async {
    await _loadCookie();
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': username, 'password': password},
    ).timeout(const Duration(seconds: 30));
    _extractCookie(res);
    // Successful login redirects (302) or returns 200 with dashboard
    return res.statusCode == 302 || res.statusCode == 200 && !res.body.contains('Invalid username');
  }

  static Future<void> logout() async {
    try { await _get('/logout'); } catch (_) {}
    await clearSession();
  }

  static Future<bool> register(String username, String password, String fullName, String email) async {
    await _loadCookie();
    final res = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'username': username, 'password': password,
        'full_name': fullName, 'email': email,
      },
    ).timeout(const Duration(seconds: 30));
    _extractCookie(res);
    return res.statusCode == 302 || (res.statusCode == 200 && !res.body.contains('error'));
  }

  // ── Vitals ────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getVitals() => _getList('/api/vitals');

  static Future<Map<String, dynamic>> addVital(Map<String, dynamic> data) =>
      _post('/api/vitals', data);

  // ── Medications ───────────────────────────────────────────────────────────
  static Future<List<dynamic>> getMedications() => _getList('/api/medications');

  static Future<Map<String, dynamic>> addMedication(Map<String, dynamic> data) =>
      _post('/api/medications', data);

  static Future<Map<String, dynamic>> deleteMedication(int id) =>
      _delete('/api/medications/$id');

  static Future<Map<String, dynamic>> logMedication(Map<String, dynamic> data) =>
      _post('/api/medications/log', data);

  // ── Diet ──────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getDiet(String date) => _getList('/api/diet?date=$date');

  static Future<Map<String, dynamic>> addDiet(Map<String, dynamic> data) =>
      _post('/api/diet', data);

  static Future<Map<String, dynamic>> updateDiet(int id, Map<String, dynamic> data) =>
      _patch('/api/diet/$id', data);

  static Future<Map<String, dynamic>> deleteDiet(int id) => _delete('/api/diet/$id');

  static Future<Map<String, dynamic>> analyzeNutrition(String foodItems) =>
      _post('/api/analyze-nutrition', {'food_items': foodItems});

  static Future<Map<String, dynamic>> analyzeFoodPhoto(File imageFile) async {
    await _loadCookie();
    final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/analyze-food-photo'));
    if (_sessionCookie != null) req.headers['Cookie'] = _sessionCookie!;
    req.files.add(await http.MultipartFile.fromPath('photo', imageFile.path));
    final streamed = await req.send().timeout(const Duration(seconds: 90));
    final res = await http.Response.fromStream(streamed);
    _extractCookie(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getDietAnalysis(String date) =>
      _post('/api/diet-analysis', {'date': date});

  static Future<Map<String, dynamic>> sendDietEmail() =>
      _post('/api/send-diet-email', {});

  // ── Appointments ──────────────────────────────────────────────────────────
  static Future<List<dynamic>> getAppointments() => _getList('/api/appointments');

  static Future<Map<String, dynamic>> addAppointment(Map<String, dynamic> data) =>
      _post('/api/appointments', data);

  static Future<Map<String, dynamic>> updateAppointment(int id, Map<String, dynamic> data) =>
      _patch('/api/appointments/$id', data);

  static Future<Map<String, dynamic>> deleteAppointment(int id) =>
      _delete('/api/appointments/$id');

  // ── Chat ─────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> chat(String message) =>
      _post('/api/chat', {'message': message});

  static Future<List<dynamic>> getChatHistory() => _getList('/api/chat/history');

  static Future<Map<String, dynamic>> clearChat() => _post('/api/chat/clear', {});

  // ── Profile ───────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getProfile() => _get('/api/profile');

  static Future<Map<String, dynamic>> saveProfile(Map<String, dynamic> data) =>
      _post('/api/profile', data);

  static Future<Map<String, dynamic>> getPatientCard() => _get('/api/patient-card');

  // ── Doctors & Emergency Contacts ─────────────────────────────────────────
  static Future<List<dynamic>> getDoctors() => _getList('/api/doctors');
  static Future<Map<String, dynamic>> addDoctor(Map<String, dynamic> d) => _post('/api/doctors', d);
  static Future<Map<String, dynamic>> deleteDoctor(int id) => _delete('/api/doctors/$id');

  static Future<List<dynamic>> getEmergencyContacts() => _getList('/api/emergency-contacts');
  static Future<Map<String, dynamic>> addEmergencyContact(Map<String, dynamic> d) =>
      _post('/api/emergency-contacts', d);
  static Future<Map<String, dynamic>> deleteEmergencyContact(int id) =>
      _delete('/api/emergency-contacts/$id');

  // ── Cycle ─────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getCycle() => _getList('/api/cycle');
  static Future<Map<String, dynamic>> addCycle(Map<String, dynamic> d) => _post('/api/cycle', d);

  // ── Records ───────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getRecords() => _getList('/api/records');

  static Future<Map<String, dynamic>> uploadRecord(File imageFile) async {
    await _loadCookie();
    final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/records/upload'));
    if (_sessionCookie != null) req.headers['Cookie'] = _sessionCookie!;
    req.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    final streamed = await req.send().timeout(const Duration(seconds: 90));
    final res = await http.Response.fromStream(streamed);
    _extractCookie(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> deleteRecord(int id) => _delete('/api/records/$id');
}

class UnauthorizedException implements Exception {
  @override
  String toString() => 'Session expired. Please log in again.';
}
