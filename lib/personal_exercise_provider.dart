import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart'; // For generating unique IDs

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
}

class PersonalExerciseProvider with ChangeNotifier {
  final List<PersonalExercise> _exercises = [];
  final Uuid _uuid = const Uuid();

  List<PersonalExercise> get exercises => _exercises;

  Future<void> _showCompletionNotification(String exerciseName) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'exercise_completion_channel', 
      'Exercise Completions',        
      channelDescription: 'Notifications for completing personal exercises',
      importance: Importance.high, // Corrected from .default
      priority: Priority.high,   // Corrected from .default
      playSound: true,              
      // sound: RawResourceAndroidNotificationSound('notification_sound'), // Example for custom sound
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
    notifyListeners();
    print('Added personal exercise: ${newExercise.name}');
  }

  void removeExercise(String id) {
    _exercises.removeWhere((exercise) => exercise.id == id);
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
      
      notifyListeners();
      print('Toggled completion for ${exercise.name} to ${exercise.isCompleted}');
    } catch (e) {
      print('Error toggling completion for exercise ID $exerciseId: $e');
    }
  }
}
