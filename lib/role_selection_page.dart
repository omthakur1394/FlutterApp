import 'package:flutter/material.dart';
import 'package:myapp/dashboard_page.dart';
import 'package:myapp/doctor_home_page.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added
import 'package:cloud_firestore/cloud_firestore.dart'; // Added

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  bool _isLoading = false; // To show loading indicator

  Future<void> _selectRole(String role) async {
    setState(() {
      _isLoading = true;
    });

    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      print('[RoleSelectionPage] Error: No current user found to save role.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User not logged in. Please restart the app.')),
        );
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Save role to Firestore
      await FirebaseFirestore.instance
          .collection('users') // Collection name
          .doc(currentUser.uid)  // Document ID is user's UID
          .set({'role': role});   // Data to save

      print('[RoleSelectionPage] Saved role: $role to Firestore for user ${currentUser.uid}'); // Corrected

      if (!mounted) return;

      if (role == 'user') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardPage()),
        );
      } else if (role == 'doctor') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DoctorHomePage()),
        );
      }
    } catch (e) {
      print('[RoleSelectionPage] Error saving role to Firestore: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving role: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Role'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isLoading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text(
                      'Choose your primary role in the app. This will be linked to your account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      onPressed: () => _selectRole('user'),
                      child: const Text('I am a User'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      onPressed: () => _selectRole('doctor'),
                      child: const Text('I am a Doctor'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
