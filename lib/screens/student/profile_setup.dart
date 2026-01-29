import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart'; // Required for Geolocator and Position
import 'package:geocoding/geocoding.dart';   // Required for Placemark and placemarkFromCoordinates

class StudentProfileSetupScreen extends StatefulWidget {
  const StudentProfileSetupScreen({super.key});

  @override
  State<StudentProfileSetupScreen> createState() => _StudentProfileSetupScreenState();
}

class _StudentProfileSetupScreenState extends State<StudentProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers & Variables
  String? _selectedGrade;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  // State variables
  List<String> _selectedSubjects = [];
  Map<String, bool> _availability = {
    'Mon': false, 'Tue': false, 'Wed': false, 'Thu': false, 'Fri': false, 'Sat': false, 'Sun': false
  };
  bool _isLoading = false;

  // Default List
  final List<String> _subjectsList = ['Math', 'Science', 'English', 'History', 'Physics', 'Chemistry', 'Biology'];

  // Grade Options (1 to 10)
  final List<String> _gradeOptions = List.generate(10, (index) => (index + 1).toString());

  // --- FUNCTION: Add Custom Subject ---
  void _showAddSubjectDialog() {
    TextEditingController customSubjectController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Subject"),
        content: TextField(
          controller: customSubjectController,
          decoration: const InputDecoration(hintText: "Enter subject name (e.g. Coding)"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (customSubjectController.text.isNotEmpty) {
                setState(() {
                  _selectedSubjects.add(customSubjectController.text.trim());
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  // --- FUNCTION: Get Current Location Name ---
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location permission denied")));
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = "${place.subLocality}, ${place.locality}";
        if (place.subLocality == null || place.subLocality!.isEmpty) {
          address = place.locality ?? "Unknown Location";
        }
        setState(() {
          _locationController.text = address;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching location: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select at least one subject")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'phone': _phoneController.text.trim(),
          'grade': _selectedGrade,
          'location': _locationController.text.trim(),
          'subjectsNeeded': _selectedSubjects,
          'availability': _availability,
          'isProfileComplete': true,
        });
        Navigator.pushReplacementNamed(context, '/student_dashboard');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Complete Your Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Tell us a bit about yourself", style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 20),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: "Phone Number", border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                validator: (val) => val!.length < 10 ? "Enter valid phone number" : null,
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Grade (1-10)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school),
                ),
                value: _selectedGrade,
                items: _gradeOptions.map((grade) {
                  return DropdownMenuItem(
                    value: grade,
                    child: Text(grade),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedGrade = val),
                validator: (val) => val == null ? "Please select a grade" : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: "Location (Area)", hintText: "e.g. Dadar, Mumbai", border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on)),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 5),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _isLoading ? null : _getCurrentLocation,
                  icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location, color: Colors.blue),
                  label: const Text("Use Current Location", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),

              const Text("Subjects Needed:", style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: [
                  ..._subjectsList.map((subject) {
                    final isSelected = _selectedSubjects.contains(subject);
                    return FilterChip(
                      label: Text(subject),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) _selectedSubjects.add(subject);
                          else _selectedSubjects.remove(subject);
                        });
                      },
                    );
                  }).toList(),
                  ..._selectedSubjects.where((s) => !_subjectsList.contains(s)).map((subject) {
                    return FilterChip(
                      label: Text(subject),
                      selected: true,
                      onSelected: (selected) {
                        setState(() {
                          _selectedSubjects.remove(subject);
                        });
                      },
                    );
                  }).toList(),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: const Text("Other"),
                    onPressed: _showAddSubjectDialog,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const Text("Weekly Availability:", style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: _availability.keys.map((day) {
                  return FilterChip(
                    label: Text(day),
                    selected: _availability[day]!,
                    onSelected: (selected) => setState(() => _availability[day] = selected),
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(15)),
                  child: const Text("Save Profile"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}