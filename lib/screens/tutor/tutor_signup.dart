import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TutorSignupScreen extends StatefulWidget {
  const TutorSignupScreen({super.key});

  @override
  State<TutorSignupScreen> createState() => _TutorSignupScreenState();
}

class _TutorSignupScreenState extends State<TutorSignupScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final Color _brandOrange = const Color(0xFFF15A24);

  void _registerTutor() async {
    try {
      UserCredential uc = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim());
      await FirebaseFirestore.instance.collection('users').doc(uc.user!.uid).set({
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'role': 'tutor',
        'createdAt': DateTime.now(),
      });
      Navigator.pushNamed(context, '/tutor_profile_setup');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Tutor Registration"), elevation: 0, backgroundColor: Colors.white, foregroundColor: Colors.black),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Become a Tutor", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: _brandOrange)),
            const Text("Share your knowledge with the world."),
            const SizedBox(height: 30),
            _field(_name, "Full Name", Icons.person),
            const SizedBox(height: 15),
            _field(_phone, "Phone Number", Icons.phone),
            const SizedBox(height: 15),
            _field(_email, "Email", Icons.email),
            const SizedBox(height: 15),
            _field(_pass, "Password", Icons.lock, isPass: true),
            const SizedBox(height: 30),
            SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _registerTutor,
                  style: ElevatedButton.styleFrom(backgroundColor: _brandOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  child: const Text("Create Account", style: TextStyle(fontSize: 18, color: Colors.white)),
                )
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String l, IconData i, {bool isPass = false}) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(15)),
      child: TextField(
        controller: c, obscureText: isPass,
        decoration: InputDecoration(
          labelText: l, prefixIcon: Icon(i, color: _brandOrange),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        ),
      ),
    );
  }
}