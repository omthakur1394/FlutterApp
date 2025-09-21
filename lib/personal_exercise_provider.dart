import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert'; // For jsonEncode and jsonDecode
import 'package:shared_preferences/shared_preferences.dart'; // For local storage

// Imports for Local Notifications
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:myapp/main.dart'; // To access flutterLocalNotificationsPlugin

class PersonalExercise {
  final String id;
  final String name;
  bool isCompleted;

  PersonalExercise({
    required this.id,
    required this.name,
    this.isCompleted = false,
  });

  // To JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isCompleted': isCompleted,
  };

  // From JSON
  factory PersonalExercise.fromJson(Map<String, dynamic> json) {
    return PersonalExercise(
      id: json['id'] as String,
      name: json['name'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false, // Handle potential null from older data
    );
  }
}

class PersonalExerciseProvider with ChangeNotifier {
  final List<PersonalExercise> _exercises = [];
  final Uuid _uuid = const Uuid();
  static const String _storageKey = 'personal_exercises';

  PersonalExerciseProvider() {
    _loadData(); // Load data when the provider is created
  }

  List<PersonalExercise> get exercises => List.unmodifiable(_exercises);

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> exercisesJson = _exercises.map((ex) => jsonEncode(ex.toJson())).toList();
    await prefs.setStringList(_storageKey, exercisesJson);
    print('Personal exercises saved');
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? exercisesJson = prefs.getStringList(_storageKey);
    if (exercisesJson != null) {
      _exercises.clear();
      _exercises.addAll(exercisesJson.map((exJson) => PersonalExercise.fromJson(jsonDecode(exJson) as Map<String, dynamic>)));
    }
    notifyListeners();
    print('Personal exercises loaded');
  }

  Future<void> _showCompletionNotification(String exerciseName) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'exercise_completion_channel', 
      'Exercise Completions',        
      channelDescription: 'Notifications for completing personal exercises',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch % 100000, 
      'Exercise Complete: $exerciseName',
      'Well done bro!',
      platformChannelSpecifics,
      payload: 'ExerciseComplete|$exerciseName',
    );
    print('Showed completion notification for: $exerciseName');
  }

  void addExercise(String name) {
    if (name.trim().isEmpty) return;
    final newExercise = PersonalExercise(id: _uuid.v4(), name: name.trim()); 
    _exercises.add(newExercise);
    _saveData(); // Save after modification
    notifyListeners();
    print('Added personal exercise: ${newExercise.name}');
  }

  void removeExercise(String id) {
    _exercises.removeWhere((exercise) => exercise.id == id);
    _saveData(); // Save after modification
    notifyListeners();
    print('Removed personal exercise with id: $id');
  }

  void toggleExerciseCompletion(String exerciseId) {
    try {
      final exercise = _exercises.firstWhere((ex) => ex.id == exerciseId);
      exercise.isCompleted = !exercise.isCompleted;
      
      if (exercise.isCompleted) {
        _showCompletionNotification(exercise.name);
      }
      _saveData(); // Save after modification
      notifyListeners();
      print('Toggled completion for ${exercise.name} to ${exercise.isCompleted}');
    } catch (e) {
      print('Error toggling completion for exercise ID $exerciseId: $e');
    }
  }
}
