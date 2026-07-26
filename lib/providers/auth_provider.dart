import 'package:flutter/material.dart';
import '../services/auth_service.dart';

// Holds the current auth session and exposes it reactively to the widget
// tree. This is the ChangeNotifier that AuthenticationWrapper (main.dart)
// watches to decide between showing the landing page or the dashboard, and
// that LearningProvider (via ChangeNotifierProxyProvider) watches to know
// when to load/clear a user's learning data. AuthService does the actual
// HTTP calls and SharedPreferences persistence; this class is the
// UI-facing state layer on top of it.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _userData;
  bool _serverConnected = false;

  AuthProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _serverConnected = await _authService.checkServerConnectivity();
      print('Server connected: $_serverConnected');

      await _authService.initialize();
      _user = _authService.currentUser;
      if (_user != null) {
        _fetchUserData();
      }
      _authService.authStateChanges.addListener(_onAuthStateChanged);
    } catch (e) {
      _error = e.toString();
      print('Initialization error: $e');
    }
    notifyListeners();
  }

  void _onAuthStateChanged() {
    _user = _authService.authStateChanges.value;
    if (_user == null) {
      _userData = null;
    } else {
      _fetchUserData();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _authService.authStateChanges.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  Map<String, dynamic>? get userData => _userData;

  // Helper methods to access common user data
  String? get fullName => _userData?['name'] as String?;
  int? get age => _userData?['age'] as int?;
  String? get email => _user?.email;

  bool get serverConnected => _serverConnected;

  Future<bool> checkServerConnection() async {
    try {
      _serverConnected = await _authService.checkServerConnectivity();
      print('Server connection check: $_serverConnected');
      notifyListeners();
      return _serverConnected;
    } catch (e) {
      print('Server connection check error: $e');
      _serverConnected = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signUp(
      String email, String password, String name, int age) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check server connectivity first
      if (!await checkServerConnection()) {
        throw "Server is not reachable. Please check your connection.";
      }

      await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        age: age,
      );
      await _fetchUserData();

      // Authentication state change will trigger learning provider refresh
    } catch (e) {
      _error = e.toString();
      print('Signup error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check server connectivity first
      if (!await checkServerConnection()) {
        throw "Server is not reachable. Please check your connection.";
      }

      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _fetchUserData();

      // Authentication state change will trigger learning provider refresh
    } catch (e) {
      _error = e.toString();
      print('Login error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signOut();
      _userData = null;

      // Additional cleanup happens through provider listeners
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendPasswordReset(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchUserData() async {
    try {
      _userData = await _authService.getCurrentUserData();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
