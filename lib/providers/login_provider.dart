import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  String? _token;
  int? _userId;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get token => _token;
  int? get userId => _userId;

  Future<void> login({
    required String baseUrl,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('📥 Login Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final userId = data['id'];

        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          await prefs.setInt('user_id', userId);

          _token = token;
          _userId = userId;
          print('✅ Login successful. Token saved.');
        } else {
          _errorMessage = "Invalid login response (no token found)";
        }
      } else {
        _errorMessage = "Login failed: ${response.statusCode}";
      }
    } catch (e) {
      _errorMessage = "Network error: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _userId = prefs.getInt('user_id');
    notifyListeners();
    return _token != null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    _token = null;
    _userId = null;
    notifyListeners();
  }
}
