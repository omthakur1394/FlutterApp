import 'dart:io'; // For File
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // For ImagePicker
import 'package:firebase_auth/firebase_auth.dart'; // For current user UID
import 'package:firebase_storage/firebase_storage.dart'; // For image upload
import 'package:cloud_firestore/cloud_firestore.dart'; // For saving data
import 'package:geolocator/geolocator.dart'; // For getting device location

class DoctorForm extends StatefulWidget {
  @override
  _DoctorFormState createState() => _DoctorFormState();
}

class _DoctorFormState extends State<DoctorForm> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile; // For newly selected image
  String? _existingImageUrl; // For image URL fetched from Firestore
  bool _isLoading = false;
  bool _profileLoaded = false; // To prevent multiple loads and control UI

  // Location state variables
  double? _currentLatitude;
  double? _currentLongitude;
  String _locationMessage = "No location pinned yet. Tap button to fetch.";
  bool _isFetchingLocation = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController qualificationController = TextEditingController();
  final TextEditingController specializationController = TextEditingController();
  final TextEditingController clinicNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController(); // Address is still useful for display
  final TextEditingController workingHoursController = TextEditingController();
  final TextEditingController feesController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDoctorProfile();
  }

  Future<void> _loadDoctorProfile() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Not logged in. Cannot load profile.")),
        );
        setState(() => _profileLoaded = true);
      }
      return;
    }

    try {
      DocumentSnapshot profileDoc = await FirebaseFirestore.instance
          .collection('doctor_profiles')
          .doc(currentUser.uid)
          .get();

      if (mounted && profileDoc.exists) {
        final data = profileDoc.data() as Map<String, dynamic>;
        nameController.text = data['name'] ?? '';
        qualificationController.text = data['qualification'] ?? '';
        specializationController.text = data['specialization'] ?? '';
        clinicNameController.text = data['clinicName'] ?? '';
        addressController.text = data['address'] ?? '';
        workingHoursController.text = data['workingHours'] ?? '';
        feesController.text = data['fees'] ?? '';
        phoneController.text = data['phone'] ?? '';
        emailController.text = data['email'] ?? '';
        setState(() {
          _existingImageUrl = data['profileImageUrl'] as String?;
          _currentLatitude = data['latitude'] as double?;
          _currentLongitude = data['longitude'] as double?;
          if (_currentLatitude != null && _currentLongitude != null) {
            _locationMessage = "Location pinned: Lat: ${_currentLatitude!.toStringAsFixed(4)}, Lon: ${_currentLongitude!.toStringAsFixed(4)}";
          } else {
            _locationMessage = "No location pinned yet. Tap button to fetch.";
          }
        });
      }
    } catch (e) {
      print("Error loading profile: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading profile: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _profileLoaded = true);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isFetchingLocation = true;
      _locationMessage = "Fetching location...";
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationMessage = "Location services are disabled. Please enable them.";
          _isFetchingLocation = false;
        });
        if (mounted) Geolocator.openLocationSettings(); // Prompt user to open settings
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationMessage = "Location permission denied. Cannot pin location.";
            _isFetchingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationMessage = "Location permission permanently denied. Enable in app settings.";
          _isFetchingLocation = false;
        });
         if (mounted) Geolocator.openAppSettings(); // Prompt user to open app settings
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentLatitude = position.latitude;
        _currentLongitude = position.longitude;
        _locationMessage = "Location pinned: Lat: ${_currentLatitude!.toStringAsFixed(4)}, Lon: ${_currentLongitude!.toStringAsFixed(4)}";
        _isFetchingLocation = false;
      });
    } catch (e) {
      print("Error fetching location: $e");
      setState(() {
        _locationMessage = "Error fetching location: $e";
        _isFetchingLocation = false;
      });
    }
  }
  
  @override
  void dispose() {
    nameController.dispose();
    qualificationController.dispose();
    specializationController.dispose();
    clinicNameController.dispose();
    addressController.dispose();
    workingHoursController.dispose();
    feesController.dispose();
    phoneController.dispose();
    emailController.dispose();
    // googleMapsLinkController no longer exists
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    // ... (keep existing _pickImage logic)
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
      }
    } catch (e) {
      print("Image picking error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error picking image: $e")),
        );
      }
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    // ... (keep existing _showImageSourceActionSheet logic)
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Photo Library'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Camera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitForm() async {
    // ... (existing validation and user check)
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fix the errors in the form.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: No user signed in.")),
        );
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }
    String doctorUid = currentUser.uid;
    String? finalImageUrl = _existingImageUrl;

    try {
      if (_imageFile != null) {
        final String fileName = 'profile_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('doctor_profiles')
            .child(doctorUid)
            .child(fileName);
        final UploadTask uploadTask = storageRef.putFile(File(_imageFile!.path));
        final TaskSnapshot snapshot = await uploadTask;
        finalImageUrl = await snapshot.ref.getDownloadURL();
      }

      Map<String, dynamic> profileData = {
        'doctorId': doctorUid,
        'name': nameController.text.trim(),
        'qualification': qualificationController.text.trim(),
        'specialization': specializationController.text.trim(),
        'clinicName': clinicNameController.text.trim(),
        'address': addressController.text.trim(),
        'workingHours': workingHoursController.text.trim(),
        'fees': feesController.text.trim(),
        'phone': phoneController.text.trim(),
        'email': emailController.text.trim(),
        'profileImageUrl': finalImageUrl,
        'latitude': _currentLatitude, // Save latitude
        'longitude': _currentLongitude, // Save longitude
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('doctor_profiles')
          .doc(doctorUid)
          .set(profileData, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile saved successfully!")),
        );
        Navigator.of(context).pop();
      }
    } catch (e, s) {
      print("Error submitting profile: $e");
      print("Stacktrace: $s");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving profile: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  ImageProvider? _getImageProvider() {
    // ... (keep existing _getImageProvider logic)
    if (_imageFile != null) {
      return FileImage(File(_imageFile!.path));
    }
    if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      return NetworkImage(_existingImageUrl!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (!_profileLoaded) {
      return Scaffold(
        appBar: AppBar(title: Text("Doctor / Therapy Center Profile")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text("Doctor / Therapy Center Profile")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ... (Image selection UI - keep existing)
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _getImageProvider(),
                        child: _getImageProvider() == null 
                            ? Icon(Icons.business_center, size: 60, color: Colors.grey[400]) 
                            : null,
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: InkWell(
                          onTap: () => _showImageSourceActionSheet(context),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    icon: Icon(Icons.image),
                    label: Text(_imageFile == null && (_existingImageUrl == null || _existingImageUrl!.isEmpty) 
                                ? "Select Center/Profile Image" 
                                : "Change Image"),
                    onPressed: () => _showImageSourceActionSheet(context),
                  ),
                ),
                SizedBox(height: 20),
                _buildTextField("Doctor / Therapist Name", nameController),
                _buildTextField("Qualification", qualificationController),
                _buildTextField("Specialization", specializationController),
                _buildTextField("Center / Clinic Name", clinicNameController),
                _buildTextField("Center Address (Street, City)", addressController), // Keep address for display
                
                // Location Pinner Section
                SizedBox(height: 20),
                Text("Center Location:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(_locationMessage, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                SizedBox(height: 8),
                _isFetchingLocation
                  ? Center(child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ))
                  : ElevatedButton.icon(
                      icon: Icon(Icons.location_pin),
                      label: Text("Pin My Current Location"),
                      onPressed: _getCurrentLocation,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[700]),
                    ),
                SizedBox(height: 20),

                _buildTextField("Working Hours (e.g., 9 AM - 5 PM, Mon-Fri)", workingHoursController),
                _buildTextField("Consultation Fees", feesController, keyboard: TextInputType.number),
                _buildTextField("Phone Number", phoneController, keyboard: TextInputType.phone),
                _buildTextField("Email", emailController, keyboard: TextInputType.emailAddress),
                SizedBox(height: 30),
                _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16)),
                      onPressed: _submitForm,
                      child: Text("Save Profile", style: TextStyle(fontSize: 18)),
                    )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboard = TextInputType.text, bool isRequired = true}) {
    // ... (keep existing _buildTextField logic, ensure no validator for googleMapsLink anymore)
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: (value) {
          if (isRequired && (value == null || value.trim().isEmpty)) {
            return "This field is required";
          }
          if (label == "Email" && value != null && value.isNotEmpty) {
            final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
            if (!emailRegex.hasMatch(value)) {
              return "Please enter a valid email address";
            }
          }
          // Removed validator for Google Maps Link as the field is removed
          return null;
        },
      ),
    );
  }
}
