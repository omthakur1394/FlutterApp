import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class DoctorListPage extends StatelessWidget {
  const DoctorListPage({super.key});

  Future<void> _launchUrl(String urlString, BuildContext context) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      print('Could not launch $urlString');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open: $urlString')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Doctors & Centers'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('doctor_profiles')
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print('Error fetching doctors: ${snapshot.error}');
            print('Stack trace: ${snapshot.stackTrace}');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Something went wrong. Please try again.\nError: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No doctors or centers found yet.'));
          }

          final doctors = snapshot.data!.docs;

          return ListView.builder(
            itemCount: doctors.length,
            padding: const EdgeInsets.only(bottom: 16, top: 8),
            itemBuilder: (context, index) {
              try {
                final doctorData = doctors[index].data() as Map<String, dynamic>;
                final name = doctorData['name'] as String? ?? 'N/A';
                final specialization = doctorData['specialization'] as String? ?? 'N/A';
                final clinicName = doctorData['clinicName'] as String? ?? 'N/A';
                final imageUrl = doctorData['profileImageUrl'] as String?;
                final phone = doctorData['phone'] as String?;
                final email = doctorData['email'] as String?;
                final address = doctorData['address'] as String? ?? 'Address not available'; // Provide a default for address
                final workingHours = doctorData['workingHours'] as String?;
                
                // Get latitude and longitude
                final latitude = doctorData['latitude'] as double?;
                final longitude = doctorData['longitude'] as double?;
                final bool hasPinnedLocation = latitude != null && longitude != null;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                                  ? NetworkImage(imageUrl)
                                  : null,
                              child: (imageUrl == null || imageUrl.isEmpty)
                                  ? Icon(Icons.business_center, size: 35, color: Colors.grey[400])
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  if (specialization.isNotEmpty)
                                    Text(specialization, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                                  if (clinicName.isNotEmpty)
                                    Text(clinicName, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20, thickness: 1),
                        if (workingHours != null && workingHours.isNotEmpty)
                          _buildDetailRow(context, Icons.schedule, 'Hours: $workingHours'),
                        
                        // Display Address - Tappable if lat/lon exist to open Google Maps
                        _buildDetailRow(
                          context, 
                          Icons.location_on,
                          address, // Displaying the textual address
                          onTap: hasPinnedLocation
                                   ? () {
                                       final String mapsUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
                                       _launchUrl(mapsUrl, context);
                                     }
                                   : null, 
                          isLink: hasPinnedLocation
                        ),

                        if (phone != null && phone.isNotEmpty)
                          _buildDetailRow(context, Icons.phone, phone, onTap: () => _launchUrl('tel:$phone', context), isLink: true),
                        if (email != null && email.isNotEmpty)
                          _buildDetailRow(context, Icons.email, email, onTap: () => _launchUrl('mailto:$email', context), isLink: true),
                      ],
                    ),
                  ),
                );
              } catch (e, s) {
                print('Error processing doctor data at index $index: $e');
                print('Stack trace for data processing error: $s');
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.red[100],
                  child: ListTile(
                    title: Text('Error displaying this doctor'),
                    subtitle: Text('$e'),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String text, {VoidCallback? onTap, bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0), 
          child: Row(
            children: [
              Icon(icon, size: 18, color: Colors.green[700]),
              const SizedBox(width: 8),
              Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: isLink ? Theme.of(context).primaryColor : Colors.black87))),
              if (onTap != null) Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }
}
