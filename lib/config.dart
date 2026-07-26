import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// Base URL for the LearnTrack Flask API.
///
/// Override at build time to point at a deployed backend, e.g.:
///   flutter build web --dart-define=API_BASE_URL=https://your-backend.onrender.com/api
///
/// Defaults to localhost for local development (with the Android emulator's
/// special-cased loopback address when no override is given).
const String _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

String get apiBaseUrl {
  if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
  if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:8000/api';
  return 'http://localhost:8000/api';
}
