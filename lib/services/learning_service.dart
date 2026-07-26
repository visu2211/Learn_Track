import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class LearningService {
  late final String baseUrl;
  String? _geminiApiKey;
  static const String _geminiApiKeyPref = 'gemini_api_key';

  LearningService() {
    if (kIsWeb) {
      baseUrl = 'http://localhost:8000/api';
    } else if (Platform.isAndroid) {
      baseUrl = 'http://10.0.2.2:8000/api';
    } else {
      baseUrl = 'http://localhost:8000/api';
    }
  }

  // Get auth token from shared preferences
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Initialize Gemini API key
  Future<void> setGeminiApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiApiKeyPref, apiKey);
    _geminiApiKey = apiKey;
  }

  Future<String?> getGeminiApiKey() async {
    if (_geminiApiKey != null) return _geminiApiKey;

    final prefs = await SharedPreferences.getInstance();
    _geminiApiKey = prefs.getString(_geminiApiKeyPref);
    return _geminiApiKey;
  }

  // Get current courses for the user
  Future<List<Map<String, dynamic>>> getCurrentCourses() async {
    try {
      final token = await _getAuthToken();
      final uid = await _getUserId();

      if (uid == null) {
        return _getMockCurrentCourses();
      }

      // Try to fetch from server first
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/users/$uid/courses'),
          headers: {
            'Authorization': 'Bearer $token',
            'X-User-ID': uid, // Add explicit user ID in header
          },
        );

        if (response.statusCode == 200) {
          final List<dynamic> coursesJson = jsonDecode(response.body);
          final courses = coursesJson.cast<Map<String, dynamic>>();

          // Save to local storage for offline access
          await _saveCoursesToLocalStorage(courses, uid);

          return courses;
        }
      } catch (e) {
        print('Error fetching courses from server: $e');
        // Continue to fallback options
      }

      // If server fetch fails, try to get from local storage
      final localCourses = await _getCoursesFromLocalStorage(uid);
      if (localCourses != null && localCourses.isNotEmpty) {
        return localCourses;
      }

      // If all else fails, return mock data
      return _getMockCurrentCourses();
    } catch (e) {
      print('Error in getCurrentCourses: $e');
      // If error, return mock data for testing
      return _getMockCurrentCourses();
    }
  }

  // Get learning paths for the user
  Future<List<Map<String, dynamic>>> getLearningPaths() async {
    try {
      final token = await _getAuthToken();
      final uid = await _getUserId();

      if (uid == null) {
        return _getMockLearningPaths();
      }

      // Try to fetch from server first
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/users/$uid/paths'),
          headers: {
            'Authorization': 'Bearer $token',
            'X-User-ID': uid, // Add explicit user ID in header
          },
        );

        if (response.statusCode == 200) {
          final List<dynamic> pathsJson = jsonDecode(response.body);
          final paths = pathsJson.cast<Map<String, dynamic>>();

          // Save to local storage for offline access
          await _savePathsToLocalStorage(paths, uid);

          return paths;
        }
      } catch (e) {
        print('Error fetching paths from server: $e');
        // Continue to fallback options
      }

      // If server fetch fails, try to get from local storage
      final localPaths = await _getPathsFromLocalStorage(uid);
      if (localPaths != null && localPaths.isNotEmpty) {
        return localPaths;
      }

      // If all else fails, return mock data
      return _getMockLearningPaths();
    } catch (e) {
      print('Error in getLearningPaths: $e');
      // If error, try to get from local storage
      final uid = await _getUserId();
      if (uid != null) {
        final localPaths = await _getPathsFromLocalStorage(uid);
        if (localPaths != null && localPaths.isNotEmpty) {
          return localPaths;
        }
      }
      return _getMockLearningPaths();
    }
  }

  // Get streak data for the user
  Future<Map<String, dynamic>> getStreakData() async {
    try {
      final token = await _getAuthToken();
      final uid = await _getUserId();

      if (uid == null) {
        return _getMockStreakData();
      }

      final response = await http.get(
        Uri.parse('$baseUrl/users/$uid/streak'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-User-ID': uid, // Add explicit user ID in header
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> streakJson = jsonDecode(response.body);
        // Store the streak data in local preferences to ensure persistence
        await _saveStreakDataToPrefs(streakJson, uid);
        return streakJson;
      } else {
        // Try to load from local storage first before falling back to mock data
        final localStreak = await _getStreakDataFromPrefs(uid);
        if (localStreak != null) {
          return localStreak;
        }
        // If API fails and no local data, return mock data
        return _getMockStreakData();
      }
    } catch (e) {
      // Try to load from local storage first before falling back to mock data
      final uid = await _getUserId();
      if (uid != null) {
        final localStreak = await _getStreakDataFromPrefs(uid);
        if (localStreak != null) {
          return localStreak;
        }
      }
      // If error and no local data, return mock data for testing
      return _getMockStreakData();
    }
  }

  // Update daily streak
  Future<bool> updateDailyStreak(bool completed) async {
    try {
      final token = await _getAuthToken();
      final uid = await _getUserId();

      if (uid == null) {
        // If no user ID, update mock data and return success
        // This makes the feature work in demo mode
        return true;
      }

      // First get current streak data
      Map<String, dynamic> currentStreak;
      try {
        // Try to get from local storage first
        final localStreak = await _getStreakDataFromPrefs(uid);
        currentStreak = localStreak ?? await getStreakData();
      } catch (e) {
        // If error, create a basic structure
        currentStreak = _getMockStreakData();
      }

      // Update the streak data
      final now = DateTime.now();
      final weekday = now.weekday;
      final dayIndex = weekday > 5 ? 4 : weekday - 1;

      if (currentStreak['days'] != null &&
          dayIndex >= 0 &&
          dayIndex < (currentStreak['days'] as List).length) {
        // Update the specific day to completed
        (currentStreak['days'] as List)[dayIndex]['completed'] = completed;

        // Update current streak count if completed
        if (completed) {
          currentStreak['currentStreak'] =
              (currentStreak['currentStreak'] as int? ?? 0) + 1;

          // If current streak is greater than longest streak, update it
          if ((currentStreak['currentStreak'] as int) >
              (currentStreak['longestStreak'] as int? ?? 0)) {
            currentStreak['longestStreak'] = currentStreak['currentStreak'];
          }
        }

        // Update week progress
        final daysCompleted = (currentStreak['days'] as List)
            .where((day) => day['completed'] == true)
            .length;
        currentStreak['weekProgress'] =
            daysCompleted / (currentStreak['days'] as List).length;
      }

      // Save updated streak to local storage for persistence
      await _saveStreakDataToPrefs(currentStreak, uid);

      // Send to server
      final response = await http.post(
        Uri.parse('$baseUrl/users/$uid/streak'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'X-User-ID': uid, // Add explicit user ID in header
        },
        body: jsonEncode({
          'streak_data': currentStreak,
          'completed': completed,
          'date': now.toIso8601String(),
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating streak: $e');
      // Even if there's an API error, we've already saved to local storage
      return true;
    }
  }

  // Save streak data to SharedPreferences
  Future<void> _saveStreakDataToPrefs(
      Map<String, dynamic> streakData, String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'streak_data_$uid';
      await prefs.setString(key, jsonEncode(streakData));
    } catch (e) {
      print('Failed to save streak data to prefs: $e');
    }
  }

  // Get streak data from SharedPreferences
  Future<Map<String, dynamic>?> _getStreakDataFromPrefs(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'streak_data_$uid';
      final data = prefs.getString(key);
      if (data != null) {
        return jsonDecode(data) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Failed to get streak data from prefs: $e');
      return null;
    }
  }

  // Ask Gemini whether a topic name is ambiguous (e.g. "derivatives" could
  // mean calculus or finance). Returns an empty list if unambiguous, or a
  // list of 2-4 distinct, self-contained interpretations if it is.
  Future<List<String>> checkAmbiguity(String topic) async {
    final apiKey = await getGeminiApiKey();
    if (apiKey == null) {
      throw Exception(
          'Gemini API key not set. Please set your API key in settings.');
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: apiKey,
      );

      final prompt = '''
        Someone wants to generate a study/learning path for the topic: "$topic".

        Decide if this topic name is ambiguous - meaning it could reasonably
        refer to two or more distinct, unrelated fields or subjects. For
        example "derivatives" could mean derivatives in calculus (mathematics)
        OR financial derivatives (options, futures, swaps) - two completely
        different subjects that would need completely different learning
        paths.

        If the topic is NOT ambiguous (it clearly refers to one subject),
        respond with exactly: []

        If it IS ambiguous, respond with a JSON array of 2-4 short strings,
        each a specific, self-contained phrasing of one interpretation, e.g.:
        ["Derivatives in calculus (mathematics)", "Financial derivatives (options, futures, and swaps)"]

        Respond with ONLY the JSON array and nothing else.
      ''';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null) return [];

      final jsonStart = text.indexOf('[');
      final jsonEnd = text.lastIndexOf(']') + 1;
      if (jsonStart == -1 || jsonEnd == 0 || jsonStart >= jsonEnd) return [];

      final parsed = jsonDecode(text.substring(jsonStart, jsonEnd));
      if (parsed is List) {
        return parsed.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      // If the ambiguity check itself fails, don't block path generation -
      // just proceed as if the topic were unambiguous.
      print('Ambiguity check failed: $e');
      return [];
    }
  }

  // Generate a learning path using Gemini API
  Future<Map<String, dynamic>> generatePathForTopic(String topic) async {
    // Check if API key is set
    final apiKey = await getGeminiApiKey();
    if (apiKey == null) {
      throw Exception(
          'Gemini API key not set. Please set your API key in settings.');
    }

    try {
      // Use Gemini API to generate learning path
      final model = GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: apiKey,
      );

      final prompt = '''
        Create a structured learning path for someone who wants to learn about "$topic".
        Generate a JSON object with this structure:
        {
          "title": "Learning Path Title",
          "description": "Brief overview of this learning path",
          "estimatedHours": estimate in hours (integer),
          "modules": [
            {
              "title": "Module 1 Title",
              "description": "Description of module",
              "estimatedHours": estimated hours for this module,
              "lessons": [
                {
                  "title": "Lesson title", 
                  "description": "Brief lesson description",
                  "resources": [
                    {"type": "article|video|book|course|tool", "title": "Resource title", "url": "Actual URL to the resource"}
                  ]
                }
              ]
            }
          ]
        }
        
        Make sure to include 3-5 modules with 3-6 lessons each, depending on the complexity of the topic.
        Include a mix of theoretical and practical lessons.
        
        IMPORTANT: Each LESSON should have its own set of 2-3 resources directly related to that specific lesson's content.
        
        For resources, include REAL, SPECIFIC URLs to actual:
        - articles (from websites like medium.com, dev.to, css-tricks.com, smashingmagazine.com)
        - videos (from YouTube with real channel names)
        - courses (from platforms like Coursera, Udemy, edX, Khan Academy) 
        - books (with links to Amazon or Goodreads)
        - tools (with links to their official websites)
        
        DO NOT use placeholder URLs like example.com or fictional URLs.
        Every URL must be a real, functioning website that actually exists.
        Double-check that your URLs point to real content that's relevant to "$topic".
        
        Make sure the learning path is comprehensive but focused specifically on "$topic".
      ''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      // Parse the response
      final text = response.text;
      if (text == null) {
        throw Exception('Failed to generate learning path: Empty response');
      }

      // Extract JSON from response text
      final jsonStart = text.indexOf('{');
      final jsonEnd = text.lastIndexOf('}') + 1;
      if (jsonStart == -1 || jsonEnd == 0 || jsonStart >= jsonEnd) {
        throw Exception('Failed to extract JSON from response');
      }

      final jsonString = text.substring(jsonStart, jsonEnd);
      final Map<String, dynamic> learningPath = jsonDecode(jsonString);

      // Add progress tracking fields
      learningPath['progress'] = 0.0;
      learningPath['createdAt'] = DateTime.now().toIso8601String();

      // Add completed fields to each module
      if (learningPath['modules'] != null) {
        final modules = learningPath['modules'] as List<dynamic>;
        for (int i = 0; i < modules.length; i++) {
          final module = modules[i] as Map<String, dynamic>;
          // Set all modules as incomplete initially (first module is unlocked)
          module['completed'] = false;

          // Add completed fields to each lesson if they exist
          if (module['lessons'] != null) {
            final lessons = module['lessons'] as List<dynamic>;
            for (int j = 0; j < lessons.length; j++) {
              final lesson = lessons[j] as Map<String, dynamic>;
              lesson['completed'] = false;

              // Ensure each lesson has a resources array
              if (lesson['resources'] == null) {
                lesson['resources'] = [];
              }
            }
          }
        }
      }

      // Save to backend
      await _saveLearningPath(learningPath);

      return learningPath;
    } catch (e) {
      throw Exception('Failed to generate learning path: $e');
    }
  }

  // Save learning path to backend
  Future<void> _saveLearningPath(Map<String, dynamic> learningPath) async {
    try {
      final token = await _getAuthToken();
      final uid = await _getUserId();

      if (uid == null) {
        return; // Can't save without user ID
      }

      // Create a new object that includes the user ID
      final Map<String, dynamic> pathWithUser = {
        ...learningPath,
        'userId': uid, // Associate the path with specific user
      };

      // Save to local storage first to ensure we have the data
      final localPaths = await _getPathsFromLocalStorage(uid) ?? [];
      localPaths.add(pathWithUser);
      await _savePathsToLocalStorage(localPaths, uid);

      // Then try to save to server
      await http.post(
        Uri.parse('$baseUrl/users/$uid/paths'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'X-User-ID': uid, // Add explicit user ID in header
        },
        body: jsonEncode(pathWithUser),
      );
    } catch (e) {
      // Fail silently, we already have the path in local storage
      print('Failed to save learning path to server: $e');
    }
  }

  // Helper function to get user ID
  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  // Mock data for testing
  List<Map<String, dynamic>> _getMockCurrentCourses() {
    return []; // Empty list to start with no courses
  }

  List<Map<String, dynamic>> _getMockLearningPaths() {
    return []; // Empty list to start with no paths
  }

  Map<String, dynamic> _getMockStreakData() {
    final now = DateTime.now();
    final weekday = now.weekday; // 1 for Monday, 7 for Sunday

    // Create mock streak data for the current week
    final mockStreak = {
      'currentStreak': 4,
      'longestStreak': 12,
      'totalDays': 23,
      'weekProgress': 0.8, // 80% of goal met for the week
      'days': [
        {
          'day': 'Mon',
          'completed': weekday > 1
        }, // Mark as completed if day has passed
        {'day': 'Tue', 'completed': weekday > 2},
        {'day': 'Wed', 'completed': weekday > 3},
        {'day': 'Thu', 'completed': weekday > 4},
        {'day': 'Fri', 'completed': false}, // Future days not completed
      ]
    };

    return mockStreak;
  }

  // Helper methods for local storage of courses
  Future<void> _saveCoursesToLocalStorage(
      List<Map<String, dynamic>> courses, String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'user_courses_$uid';
      await prefs.setString(key, jsonEncode(courses));
    } catch (e) {
      print('Failed to save courses to local storage: $e');
    }
  }

  Future<List<Map<String, dynamic>>?> _getCoursesFromLocalStorage(
      String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'user_courses_$uid';
      final data = prefs.getString(key);
      if (data != null) {
        final List<dynamic> parsed = jsonDecode(data);
        return parsed.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      print('Failed to get courses from local storage: $e');
      return null;
    }
  }

  // Helper methods for local storage of paths
  Future<void> _savePathsToLocalStorage(
      List<Map<String, dynamic>> paths, String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'user_paths_$uid';
      await prefs.setString(key, jsonEncode(paths));
    } catch (e) {
      print('Failed to save paths to local storage: $e');
    }
  }

  Future<List<Map<String, dynamic>>?> _getPathsFromLocalStorage(
      String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'user_paths_$uid';
      final data = prefs.getString(key);
      if (data != null) {
        final List<dynamic> parsed = jsonDecode(data);
        return parsed.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      print('Failed to get paths from local storage: $e');
      return null;
    }
  }

  // Save current courses
  Future<bool> saveCurrentCourses(List<Map<String, dynamic>> courses) async {
    try {
      final token = await _getAuthToken();
      final uid = await _getUserId();

      if (uid == null) {
        return false; // Can't save without user ID
      }

      // Save to local storage first
      await _saveCoursesToLocalStorage(courses, uid);

      // Try to save to server
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/users/$uid/courses'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'X-User-ID': uid,
          },
          body: jsonEncode({
            'courses': courses,
          }),
        );

        return response.statusCode == 200 || response.statusCode == 201;
      } catch (e) {
        print('Failed to save courses to server: $e');
        // We already saved to local storage, so we consider it successful
        return true;
      }
    } catch (e) {
      print('Error in saveCurrentCourses: $e');
      return false;
    }
  }

  // Save learning paths to local storage
  Future<void> saveLearningPaths(List<Map<String, dynamic>> paths) async {
    try {
      final uid = await _getUserId();
      if (uid == null) return;

      // Save to local storage for offline access
      await _savePathsToLocalStorage(paths, uid);

      // Try to save to server
      try {
        final token = await _getAuthToken();
        final response = await http.post(
          Uri.parse('$baseUrl/users/$uid/paths'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'X-User-ID': uid,
          },
          body: jsonEncode({'paths': paths}),
        );
      } catch (e) {
        print('Failed to save paths to server: $e');
        // Still saved to local storage, so not a critical error
      }
    } catch (e) {
      print('Error saving learning paths: $e');
    }
  }
}
