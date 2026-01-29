import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart'; // For GPS
import 'package:geocoding/geocoding.dart';   // For Address Name

class TutorProfilePage extends StatefulWidget {
  const TutorProfilePage({super.key});

  @override
  State<TutorProfilePage> createState() => _TutorProfilePageState();
}

class _TutorProfilePageState extends State<TutorProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  // Brand Colors
  final Color _brandBlue = const Color(0xFF2E3192);
  final Color _brandOrange = const Color(0xFFF15A24);

  // State Variables
  bool _isLoading = true;
  bool _isEditing = false;
  bool _notificationsEnabled = true;
  String? _profileImageUrl;

  // Lists & Maps
  List<String> _subjects = [];
  Map<String, bool> _availability = {
    'Mon': false, 'Tue': false, 'Wed': false, 'Thu': false, 'Fri': false, 'Sat': false, 'Sun': false
  };

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // --- 1. FETCH DATA ---
  Future<void> _fetchUserData() async {
    if (user == null) return;
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists && mounted) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['name'] ?? "";
          _bioController.text = data['bio'] ?? "";
          _phoneController.text = data['phone'] ?? "";
          _rateController.text = (data['hourlyRate'] ?? "").toString();
          _locationController.text = data['location'] ?? "";
          _notificationsEnabled = data['notificationsEnabled'] ?? true;
          _profileImageUrl = data['profileUrl'];

          if (data['subjects'] != null) {
            _subjects = List<String>.from(data['subjects']);
          }

          if (data['availability'] != null) {
            _availability = Map<String, bool>.from(data['availability']);
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 2. GET CURRENT LOCATION (GPS) ---
  Future<void> _getCurrentLocation() async {
    if (!_isEditing) return;

    setState(() => _isLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoading = false);
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
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching location: $e")));
      }
    }
  }

  // --- 3. UPLOAD IMAGE ---
  Future<void> _uploadProfileImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() => _isLoading = true);

    try {
      Reference ref = FirebaseStorage.instance.ref().child('profile_pics/${user!.uid}.jpg');
      await ref.putFile(File(image.path));
      String downloadUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'profileUrl': downloadUrl,
      });

      if (mounted) {
        setState(() {
          _profileImageUrl = downloadUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload Failed: $e")));
      }
    }
  }

  // --- 4. MANAGE SUBJECTS ---
  void _showAddSubjectDialog() {
    TextEditingController customSubjectController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Subject"),
        content: TextField(
          controller: customSubjectController,
          decoration: const InputDecoration(hintText: "Enter subject name (e.g. Java)"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (customSubjectController.text.isNotEmpty) {
                setState(() {
                  _subjects.add(customSubjectController.text.trim());
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

  // --- 5. SAVE ---
  void _attemptSave() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Changes"),
        content: const Text("Are you sure you want to update your public profile?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _saveProfile();
            },
            child: const Text("Yes, Update"),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'phone': _phoneController.text.trim(),
        'hourlyRate': _rateController.text.trim(),
        'location': _locationController.text.trim(),
        'subjects': _subjects,
        'availability': _availability,
        'notificationsEnabled': _notificationsEnabled,
      });
      if (mounted) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Updated Successfully!")));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  // --- 6. DELETE ACCOUNT ---
  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("This action cannot be undone. Are you sure?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('users').doc(user!.uid).delete();
                await user!.delete();
                if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              } catch (e) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please re-login and try again.")));
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.grey[50], // Modern Background
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER WITH LOGO & AVATAR ---
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // 1. Blue Background
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: _brandBlue,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
                  ),
                ),

                // 2. LOGO
                Positioned(
                  top: 50,
                  child: Image.asset(
                    'assets/images/tnmlogo.png',
                    height: 50,
                    // Remove color properties if your logo has its own colors you want to keep
                    // color: Colors.white.withOpacity(0.9),
                    // colorBlendMode: BlendMode.srcIn,
                  ),
                ),

                // 3. Edit Button
                Positioned(
                  top: 50, right: 20,
                  child: IconButton(
                    icon: Icon(_isEditing ? Icons.close : Icons.edit, color: Colors.white),
                    onPressed: () => setState(() {
                      if (_isEditing) _fetchUserData(); // Undo if cancelling
                      _isEditing = !_isEditing;
                    }),
                  ),
                ),

                // 4. Avatar
                Positioned(
                  top: 140,
                  child: InkWell(
                    onTap: _uploadProfileImage,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null,
                        child: _profileImageUrl == null
                            ? Text(_nameController.text.isNotEmpty ? _nameController.text[0] : "T", style: TextStyle(fontSize: 40, color: _brandBlue, fontWeight: FontWeight.bold))
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 80),

            // --- FORM CONTENT ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildTextField("Full Name", _nameController, Icons.person),
                  const SizedBox(height: 15),
                  _buildTextField("Bio / About Me", _bioController, Icons.info_outline, maxLines: 3),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(child: _buildTextField("Hourly Rate (₹)", _rateController, Icons.currency_rupee, isNumber: true)),
                      const SizedBox(width: 15),
                      Expanded(child: _buildTextField("Phone", _phoneController, Icons.phone, isNumber: true)),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Location Row
                  Row(
                    children: [
                      Expanded(child: _buildTextField("Location", _locationController, Icons.location_on)),
                      if (_isEditing)
                        Container(
                          margin: const EdgeInsets.only(left: 10),
                          decoration: BoxDecoration(color: _brandOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: IconButton(icon: Icon(Icons.my_location, color: _brandOrange), onPressed: _getCurrentLocation),
                        )
                    ],
                  ),
                  const SizedBox(height: 25),

                  // --- SUBJECTS ---
                  Align(alignment: Alignment.centerLeft, child: Text("Subjects I Teach", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _brandBlue))),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      ..._subjects.map((s) => Chip(
                        label: Text(s),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade300)),
                        deleteIcon: _isEditing ? const Icon(Icons.close, size: 18) : null,
                        onDeleted: _isEditing ? () => setState(() => _subjects.remove(s)) : null,
                      )),
                      if (_isEditing)
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 18),
                          label: const Text("Add"),
                          onPressed: _showAddSubjectDialog,
                        )
                    ],
                  ),
                  const SizedBox(height: 25),

                  // --- AVAILABILITY ---
                  Align(alignment: Alignment.centerLeft, child: Text("Weekly Availability", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _brandBlue))),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: _availability.keys.map((day) {
                      return FilterChip(
                        label: Text(day),
                        selected: _availability[day]!,
                        onSelected: _isEditing ? (val) => setState(() => _availability[day] = val) : null,
                        selectedColor: _brandBlue.withOpacity(0.2),
                        checkmarkColor: _brandBlue,
                        labelStyle: TextStyle(color: _availability[day]! ? _brandBlue : Colors.black87),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),

                  // --- SAVE BUTTON ---
                  if (_isEditing)
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _attemptSave,
                        style: ElevatedButton.styleFrom(backgroundColor: _brandBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                        child: const Text("Save Changes", style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    ),

                  if (!_isEditing) ...[
                    const Divider(height: 40),
                    _buildSettingItem("Notifications", Icons.notifications, trailing: Switch(value: _notificationsEnabled, activeColor: _brandOrange, onChanged: (val) { setState(() => _notificationsEnabled = val); FirebaseFirestore.instance.collection('users').doc(user!.uid).update({'notificationsEnabled': val}); })),
                    _buildSettingItem("Language", Icons.language, trailing: const Text("English", style: TextStyle(color: Colors.grey))),
                    _buildSettingItem("Help & Support", Icons.help_outline, onTap: () => showAboutDialog(context: context, applicationName: "Tutor App")),
                    _buildSettingItem("Logout", Icons.logout, color: Colors.orange, onTap: () async { await FirebaseAuth.instance.signOut(); Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false); }),
                    _buildSettingItem("Delete Account", Icons.delete_forever, color: Colors.red, onTap: _deleteAccount),
                  ],
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return TextField(
      controller: controller,
      enabled: _isEditing,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: _isEditing ? Colors.white : Colors.transparent,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: _isEditing ? const BorderSide(color: Colors.grey) : BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      ),
    );
  }

  Widget _buildSettingItem(String title, IconData icon, {Color color = Colors.black87, Widget? trailing, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}