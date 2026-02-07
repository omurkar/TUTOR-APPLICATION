import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class TutorProfileSetupScreen extends StatefulWidget {
  const TutorProfileSetupScreen({super.key}); // Added const constructor

  @override
  State<TutorProfileSetupScreen> createState() => _TutorProfileSetupScreenState();
}

class _TutorProfileSetupScreenState extends State<TutorProfileSetupScreen> {
  final _location = TextEditingController();
  final _rate = TextEditingController();
  final _bio = TextEditingController();
  final _qual = TextEditingController();
  final _subjects = TextEditingController();

  bool isOnline = false;
  bool isOffline = false;
  bool _isLoading = false;

  final Map<String, bool> _availability = {
    "Mon": false, "Tue": false, "Wed": false, "Thu": false, "Fri": false, "Sat": false, "Sun": false
  };

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
          _location.text = address;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching location: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _saveTutorProfile() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'location': _location.text.trim(),
          'hourlyRate': _rate.text.trim(),
          'bio': _bio.text.trim(),
          'qualification': _qual.text.trim(),
          'subjects': _subjects.text.trim(),
          'isOnline': isOnline,
          'isOffline': isOffline,
          'availability': _availability,
          'isProfileComplete': true,
        });
        _showSuccessMotion();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showSuccessMotion() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
          const SizedBox(height: 20),
          const Text("Account Created!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text("Your Tutor profile is now live."),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () => Navigator.pushReplacementNamed(context, '/tutor_dashboard'), child: const Text("Enter Dashboard")),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tutor Profile Setup")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Basic Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(controller: _location, decoration: const InputDecoration(labelText: "Location (City/Area)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on))),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _isLoading ? null : _getCurrentLocation,
                icon: _isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location, color: Colors.blue),
                label: const Text("Use Current Location", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 15),
            TextField(controller: _rate, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Hourly Rate (₹)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.currency_rupee))),
            const SizedBox(height: 20),
            const Text("Professional Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(controller: _bio, maxLines: 3, decoration: const InputDecoration(labelText: "Bio (About You)", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: _qual, decoration: const InputDecoration(labelText: "Qualification", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: _subjects, decoration: const InputDecoration(labelText: "Subjects (comma separated)", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            const Text("Teaching Mode", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            CheckboxListTile(title: const Text("Online Mode"), value: isOnline, onChanged: (v) => setState(() => isOnline = v!)),
            CheckboxListTile(title: const Text("Offline Mode"), value: isOffline, onChanged: (v) => setState(() => isOffline = v!)),
            const SizedBox(height: 15),
            const Text("Weekly Availability", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8.0,
              children: _availability.keys.map((day) => FilterChip(
                label: Text(day),
                selected: _availability[day]!,
                onSelected: (v) => setState(() => _availability[day] = v),
              )).toList(),
            ),
            const SizedBox(height: 30),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _saveTutorProfile, child: const Text("Save & Finish"))),
          ],
        ),
      ),
    );
  }
}
