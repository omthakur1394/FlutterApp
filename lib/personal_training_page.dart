import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/personal_exercise_provider.dart';

class PersonalTrainingPage extends StatelessWidget {
  const PersonalTrainingPage({super.key});

  void _showAddExerciseDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add New Exercise'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: 'Enter exercise name (e.g., Yoga Poses)'),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  Provider.of<PersonalExerciseProvider>(context, listen: false)
                      .addExercise(nameController.text);
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Training',
            style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.grey[50],
        elevation: 0,
      ),
      body: Consumer<PersonalExerciseProvider>(
        builder: (context, exerciseProvider, child) {
          if (exerciseProvider.exercises.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No personal exercises yet. Tap + to add your first one and track your progress!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: exerciseProvider.exercises.length,
            itemBuilder: (context, index) {
              final exercise = exerciseProvider.exercises[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: Checkbox(
                    value: exercise.isCompleted,
                    onChanged: (bool? value) {
                      exerciseProvider.toggleExerciseCompletion(exercise.id);
                    },
                    activeColor: Colors.green,
                  ),
                  title: Text(
                    exercise.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      decoration: exercise.isCompleted 
                          ? TextDecoration.lineThrough 
                          : TextDecoration.none,
                      color: exercise.isCompleted ? Colors.grey : Colors.black,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.timer_outlined, color: Colors.blueAccent),
                        tooltip: 'Start Timer',
                        onPressed: () {
                          // TODO: Implement Timer functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text('Timer for ${exercise.name} coming soon!')));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        tooltip: 'Delete Exercise',
                        onPressed: () {
                          exerciseProvider.removeExercise(exercise.id);
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text('${exercise.name} removed.')));
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    // Toggle completion on tap of the list tile itself as well
                    exerciseProvider.toggleExerciseCompletion(exercise.id);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExerciseDialog(context),
        backgroundColor: Colors.green,
        tooltip: 'Add New Exercise',
        child: const Icon(Icons.add),
      ),
    );
  }
}
