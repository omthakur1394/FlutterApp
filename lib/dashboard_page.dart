import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/therapy_provider.dart';
import 'package:myapp/booking_page.dart';
import 'package:myapp/personal_training_page.dart'; // Import PersonalTrainingPage

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
    'Personal Training', // Added new title
    'Schedule Session'   // For the navigation action
  ];

  User? get currentUser => FirebaseAuth.instance.currentUser;

  Widget _buildDashboardContent(TherapyProvider therapyProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Upcoming Sessions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListView.separated(
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
          ListView.separated(
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

    // List of widgets for the body, corresponding to bottom nav items
    // Order: Dashboard, Profile, Training
    final List<Widget> pages = [
      _buildDashboardContent(therapyProvider), // Index 0
      _buildProfilePage(),                   // Index 1
      const PersonalTrainingPage(),          // Index 2 (New Page)
      // Index 3 (Scheduling) navigates away, so no specific page widget here.
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
      ),
      body: Builder(
        builder: (BuildContext scaffoldContext) {
          // Ensure we don't try to access an out-of-bounds index if _bottomNavIndex is for Scheduling
          if (_bottomNavIndex < pages.length) {
             return pages[_bottomNavIndex];
          } 
          return Container(); // Fallback for scheduling tab if it were to show a body
        }
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomNavIndex > 2 ? 0 : _bottomNavIndex, // Keep selection on a valid tab
        onTap: (index) {
          if (index == 3) { // Scheduling tab (now at index 3)
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const BookingPage()),
            );
            // Optionally, reset _bottomNavIndex to the previous tab or default (e.g., 0)
            // This prevents the "Scheduling" tab from appearing selected when returning.
            // For now, it will revert to the last visually selected tab based on currentIndex logic above.
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
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Training'), // New Tab
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
