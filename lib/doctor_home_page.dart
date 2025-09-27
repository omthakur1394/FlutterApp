import 'package:flutter/material.dart';
import 'package:myapp/auth_service.dart'; // Import AuthService
import 'package:myapp/doctor_profile_form_page.dart'; // Import the new form page

class DoctorHomePage extends StatefulWidget {
  const DoctorHomePage({super.key});

  @override
  State<DoctorHomePage> createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends State<DoctorHomePage> {
  final AuthService _authService = AuthService();

  Future<void> _performSignOut() async {
    print('[DoctorHomePage] _performSignOut method called.');
    await _authService.signOut();
    // AuthWrapper in main.dart will handle navigation
  }

  void _navigateToProfileForm() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DoctorForm()), // Navigate to DoctorForm
    );
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Hi Doctor!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Welcome to your portal.',
                style: TextStyle(fontSize: 18, color: Colors.blueGrey),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.edit_document),
                label: const Text('Manage My Profile/Center Info'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16)
                ),
                onPressed: _navigateToProfileForm,
              ),
              // You can add more doctor-specific widgets here later
            ],
          ),
        ),
      ),
    );
  }
}
