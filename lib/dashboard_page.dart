import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/therapy_provider.dart';
import 'package:myapp/booking_page.dart';
import 'package:myapp/personal_training_page.dart';
import 'package:myapp/doctor_list_page.dart'; // Import DoctorListPage

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _bottomNavIndex = 0; // Default to Dashboard tab

  final List<String> _appBarTitles = const [
    'Dashboard',
    'Profile',
    'Personal Training',
    'Schedule Session'
  ];

  User? get currentUser => FirebaseAuth.instance.currentUser;

  Future<void> _signOut() async {
    print('[DashboardPage] _signOut method called.');
    try {
      await FirebaseAuth.instance.signOut();
      print('[DashboardPage] FirebaseAuth.instance.signOut() completed.');
    } catch (e) {
      print('[DashboardPage] Error during signOut: $e');
    }
  }

  Widget _buildDashboardContent(BuildContext context, TherapyProvider therapyProvider) { // Added context
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card to navigate to Doctor List Page
          Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DoctorListPage()),
                );
              },
              borderRadius: BorderRadius.circular(12.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.medical_services_outlined, color: Colors.green[700], size: 36),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Find Doctors & Therapy Centers',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),

          const Text('Upcoming Sessions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          therapyProvider.sessions.isEmpty
            ? const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Text("No upcoming sessions.", style: TextStyle(color: Colors.grey)),
              ))
            : ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: therapyProvider.sessions.length,
                itemBuilder: (context, index) {
                  final session = therapyProvider.sessions[index];
                  return _buildSessionCard(session, therapyProvider);
                },
                separatorBuilder: (context, index) => const SizedBox(height: 12),
              ),
          const SizedBox(height: 24),
          const Text('Therapy Progress', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
           therapyProvider.progressList.isEmpty
            ? const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Text("No progress to show yet.", style: TextStyle(color: Colors.grey)),
              ))
            : ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: therapyProvider.progressList.length,
                itemBuilder: (context, index) {
                  final progress = therapyProvider.progressList[index];
                  return _buildProgressCard(progress);
                },
                separatorBuilder: (context, index) => const SizedBox(height: 12),
              ),
        ],
      ),
    );
  }

  Widget _buildProfilePage() {
    String displayName = currentUser?.displayName ?? 'N/A';
    String? email = currentUser?.email;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Profile',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          if (currentUser != null)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_outline, color: Colors.green[700], size: 28),
                        const SizedBox(width: 12),
                        Text(
                          displayName,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    if (email != null && email.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.email_outlined, color: Colors.green[700], size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              email,
                              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                            ),
                          ),
                        ],
                      ),
                    ]
                  ],
                ),
              ),
            )
          else
            const Center(child: Text('User data not available. Please log in again.')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final therapyProvider = Provider.of<TherapyProvider>(context);

    final List<Widget> pages = [
      _buildDashboardContent(context, therapyProvider), // Pass context here
      _buildProfilePage(),                   
      const PersonalTrainingPage(),          
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        title: Text(_appBarTitles[_bottomNavIndex], style: const TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {
            // TODO: Implement drawer functionality if needed
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            tooltip: 'Logout',
            onPressed: () async {
              print('[DashboardPage] Logout button pressed.');
              await _signOut();
            },
          ),
        ],
      ),
      body: Builder(
        builder: (BuildContext scaffoldContext) {
          if (_bottomNavIndex < pages.length) {
             return pages[_bottomNavIndex];
          } 
          return Container(); 
        }
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomNavIndex > 2 ? 0 : _bottomNavIndex, 
        onTap: (index) {
          if (index == 3) { 
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const BookingPage()),
            );
          } else {
            setState(() {
              _bottomNavIndex = index;
            });
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Training'), 
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Scheduling'),
        ],
      ),
    );
  }

  Widget _buildSessionCard(TherapySession session, TherapyProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(8.0)),
              child: Icon(Icons.calendar_today, color: Colors.green[800]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(session.time, style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: () => provider.completeSession(session),
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () => provider.skipSession(session),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(TherapyProgress progress) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(progress.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${(progress.progress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress.progress,
              backgroundColor: Colors.grey[200],
              color: Colors.green,
              minHeight: 8,
            ),
          ],
        ),
      ),
    );
  }
}
