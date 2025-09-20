import 'package:flutter/foundation.dart';

// Represents a single therapy session
class TherapySession {
  final String name;
  final String time;
  TherapySession({required this.name, required this.time});
}

// Represents the progress for a specific therapy type
class TherapyProgress {
  final String name;
  double progress; // Value between 0.0 and 1.0
  // Default progress for a new therapy type is now 0.0
  TherapyProgress({required this.name, this.progress = 0.0}); 
}

class TherapyProvider with ChangeNotifier {
  // List of upcoming sessions - starts empty
  final List<TherapySession> _sessions = [];

  // Map to hold progress for each therapy type - starts empty
  final Map<String, TherapyProgress> _progress = {};

  // Getters to access the data from the UI
  List<TherapySession> get sessions => _sessions;
  List<TherapyProgress> get progressList => _progress.values.toList();

  // Method to add a new session
  void addSession(String therapyName, String time) {
    _sessions.add(TherapySession(name: therapyName, time: time));

    // If this is a new type of therapy, add a progress tracker for it (will default to 0.0 progress)
    if (!_progress.containsKey(therapyName)) {
      _progress[therapyName] = TherapyProgress(name: therapyName);
    }
    
    notifyListeners();
  }

  // Method to mark a session as complete
  void completeSession(TherapySession session) {
    if (_progress.containsKey(session.name)) {
      _progress[session.name]!.progress = (_progress[session.name]!.progress + 0.1).clamp(0.0, 1.0);
      _sessions.remove(session); 
      notifyListeners();
    }
  }

  // Method to mark a session as skipped
  void skipSession(TherapySession session) {
    if (_progress.containsKey(session.name)) {
      _progress[session.name]!.progress = (_progress[session.name]!.progress - 0.1).clamp(0.0, 1.0);
      _sessions.remove(session);
      notifyListeners();
    }
  }
}
