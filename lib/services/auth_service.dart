import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class User {
  final String uid;
  final String email;
  final String? name;

  User({required this.uid, required this.email, this.name});
}

class AuthService {
  late final String baseUrl;

  AuthService() {
    baseUrl = apiBaseUrl;
    checkServerConnectivity();
  }

  User? _currentUser;

  User? get currentUser => _currentUser;

  final ValueNotifier<User?> _authStateChanges = ValueNotifier<User?>(null);
  ValueNotifier<User?> get authStateChanges => _authStateChanges;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/auth/validate'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          final userData = jsonDecode(response.body);
          _currentUser = User(
            uid: userData['uid'],
            email: userData['email'],
            name: userData['name'],
          );
          _authStateChanges.value = _currentUser;
        } else {
          await prefs.remove('auth_token');
        }
      } catch (e) {
        await prefs.remove('auth_token');
      }
    }
  }

  Future<User?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required int age,
  }) async {
    try {
      final url = '$baseUrl/auth/signup';
      final response = await http
          .post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'age': age,
        }),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw 'Connection timed out. Please check if the server is running.';
        },
      );

      if (response.body.isEmpty) {
        throw 'Server returned empty response. Please check server logs.';
      }

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        throw 'Invalid response from server. Please check server logs.';
      }

      if (response.statusCode == 201) {
        final token = data['token'];

        if (token == null) {
          throw 'Server response missing token';
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        final userId = data['uid'] ?? 'unknown';
        await prefs.setString('user_id', userId);

        _currentUser = User(
          uid: userId,
          email: email,
          name: name,
        );
        _authStateChanges.value = _currentUser;

        return _currentUser;
      } else {
        throw data['message'] ?? 'An error occurred during sign up.';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final url = '$baseUrl/auth/login';
      final response = await http
          .post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw 'Connection timed out. Please check if the server is running.';
        },
      );

      if (response.body.isEmpty) {
        throw 'Server returned empty response. Please check server logs.';
      }

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        throw 'Invalid response from server. Please check server logs.';
      }

      if (response.statusCode == 200) {
        final token = data['token'];

        if (token == null) {
          throw 'Server response missing token';
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        final userId = data['uid'] ?? 'unknown';
        await prefs.setString('user_id', userId);

        _currentUser = User(
          uid: userId,
          email: email,
          name: data['name'],
        );
        _authStateChanges.value = _currentUser;

        return _currentUser;
      } else {
        throw data['message'] ?? 'An error occurred during sign in.';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_id');
      _currentUser = null;
      _authStateChanges.value = null;
    } catch (e) {
      throw 'An error occurred while signing out.';
    }
  }

  // Password reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw error['message'] ??
            'An error occurred while sending password reset email.';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // Get user data
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      if (_currentUser == null) return null;

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/users/${_currentUser!.uid}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw error['message'] ?? 'An error occurred while getting user data.';
      }
    } catch (e) {
      throw 'Error getting user data: $e';
    }
  }

  // Check if the server is running
  Future<bool> checkServerConnectivity() async {
    try {
      final serverUrl = baseUrl.replaceAll('/api', '/healthcheck');
      final response = await http
          .get(
        Uri.parse(serverUrl),
      )
          .timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          return http.Response('', 408);
        },
      );

      try {
        final data = jsonDecode(response.body);
        return data != null &&
            response.statusCode == 200 &&
            data['status'] == 'ok';
      } catch (e) {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
