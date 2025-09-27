import 'package:flutter/material.dart';
// No need to import FirebaseAuth directly here if using AuthService
import 'package:myapp/auth_service.dart'; // Import AuthService

class DoctorHomePage extends StatefulWidget {
  const DoctorHomePage({super.key});

  @override
  State<DoctorHomePage> createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends State<DoctorHomePage> {
  final AuthService _authService = AuthService(); // Create instance here

  Future<void> _performSignOut() async {
    print('[DoctorHomePage] _performSignOut method called.');
    print('[DoctorHomePage] Using _authService.signOut()');
    await _authService.signOut();
    // AuthWrapper in main.dart will handle navigation
  }

  @override
  Widget build(BuildContext context) {
    print('[DoctorHomePage] Build method called.');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Portal'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              print('[DoctorHomePage] Logout button pressed.');
              _performSignOut();
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Hi Doctor!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
