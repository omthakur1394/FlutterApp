import 'package:flutter/foundation.dart';
import 'dart:convert'; // For jsonEncode and jsonDecode
import 'package:shared_preferences/shared_preferences.dart'; // For local storage

// Represents a single therapy session
class TherapySession {
  final String name;
  final String time;
  TherapySession({required this.name, required this.time});

  // To JSON
  Map<String, dynamic> toJson() => {
    'name': name,
    'time': time,
  };

  // From JSON
  factory TherapySession.fromJson(Map<String, dynamic> json) {
    return TherapySession(
      name: json['name'] as String,
      time: json['time'] as String,
    );
  }
}

// Represents the progress for a specific therapy type
class TherapyProgress {
  final String name;
  double progress; // Value between 0.0 and 1.0
  TherapyProgress({required this.name, this.progress = 0.0});

  // To JSON
  Map<String, dynamic> toJson() => {
    'name': name,
    'progress': progress,
  };

  // From JSON
  factory TherapyProgress.fromJson(Map<String, dynamic> json) {
    return TherapyProgress(
      name: json['name'] as String,
      progress: (json['progress'] as num).toDouble(), // Ensure progress is double
    );
  }
}

class TherapyProvider with ChangeNotifier {
  final List<TherapySession> _sessions = [];
  final Map<String, TherapyProgress> _progress = {};

  static const String _sessionsKey = 'therapy_sessions';
  static const String _progressKey = 'therapy_progress';

  TherapyProvider() {
    _loadData(); // Load data when the provider is created
  }

  List<TherapySession> get sessions => _sessions;
  List<TherapyProgress> get progressList => _progress.values.toList();

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    // Save sessions
    List<String> sessionsJson = _sessions.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_sessionsKey, sessionsJson);
    // Save progress
    Map<String, String> progressJsonMap = 
        _progress.map((key, value) => MapEntry(key, jsonEncode(value.toJson())));
    // SharedPreferences doesn't directly support Map<String, String>, so we save the encoded map string
    await prefs.setString(_progressKey, jsonEncode(progressJsonMap));
    print('Therapy data saved');
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    // Load sessions
    List<String>? sessionsJson = prefs.getStringList(_sessionsKey);
    if (sessionsJson != null) {
      _sessions.clear();
      _sessions.addAll(sessionsJson.map((s) => TherapySession.fromJson(jsonDecode(s) as Map<String, dynamic>)));
    }
    // Load progress
    String? progressJsonString = prefs.getString(_progressKey);
    if (progressJsonString != null) {
      Map<String, dynamic> progressJsonMap = jsonDecode(progressJsonString) as Map<String, dynamic>; 
      _progress.clear();
      progressJsonMap.forEach((key, value) {
        _progress[key] = TherapyProgress.fromJson(jsonDecode(value as String) as Map<String, dynamic>);
      });
    }
    notifyListeners();
    print('Therapy data loaded');
  }

  void addSession(String therapyName, String time) {
    _sessions.add(TherapySession(name: therapyName, time: time));
    if (!_progress.containsKey(therapyName)) {
      _progress[therapyName] = TherapyProgress(name: therapyName);
    }
    _saveData(); // Save after modification
    notifyListeners();
  }

  void completeSession(TherapySession session) {
    if (_progress.containsKey(session.name)) {
      _progress[session.name]!.progress = (_progress[session.name]!.progress + 0.1).clamp(0.0, 1.0);
      _sessions.removeWhere((s) => s.name == session.name && s.time == session.time); 
      _saveData(); // Save after modification
      notifyListeners();
    }
  }

  void skipSession(TherapySession session) {
    if (_progress.containsKey(session.name)) {
      _progress[session.name]!.progress = (_progress[session.name]!.progress - 0.1).clamp(0.0, 1.0);
      _sessions.removeWhere((s) => s.name == session.name && s.time == session.time);
      _saveData(); // Save after modification
      notifyListeners();
    }
  }
}
