import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';

class StudentSignupScreen extends StatefulWidget {
  const StudentSignupScreen({super.key});

  @override
  State<StudentSignupScreen> createState() => _StudentSignupScreenState();
}

class _StudentSignupScreenState extends State<StudentSignupScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final Color _brandBlue = const Color(0xFF2E3192);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _registerStudent() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
        return;
      }
      try {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim()
        );
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'role': 'student',
          'createdAt': DateTime.now(),
        });
        _showSuccessAnimation();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void _showSuccessAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.network('https://assets10.lottiefiles.com/packages/lf20_xlkxtmul.json', height: 150, repeat: false),
            const SizedBox(height: 20),
            const Text("Account Created!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => Navigator.pushReplacementNamed(context, '/student_profile_setup'), child: const Text("Setup Profile")),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Student Sign Up"), elevation: 0, backgroundColor: Colors.white, foregroundColor: Colors.black),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Create Account", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: _brandBlue)),
            const SizedBox(height: 10),
            const Text("Join us to start learning today!"),
            const SizedBox(height: 30),
            _buildField(_nameController, "Full Name", Icons.person),
            const SizedBox(height: 15),
            _buildField(_phoneController, "Phone Number", Icons.phone, isPhone: true),
            const SizedBox(height: 15),
            _buildField(_emailController, "Email ID", Icons.email),
            const SizedBox(height: 15),
            _buildField(_passwordController, "Password", Icons.lock, isObscure: true),
            const SizedBox(height: 15),
            _buildField(_confirmPasswordController, "Confirm Password", Icons.lock_clock, isObscure: true),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _registerStudent,
                style: ElevatedButton.styleFrom(backgroundColor: _brandBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: const Text("Sign Up", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ])),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool isObscure = false, bool isPhone = false}) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(15)),
      child: TextFormField(
        controller: controller,
        obscureText: isObscure,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _brandBlue.withOpacity(0.7)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        ),
        validator: (val) => val!.isEmpty ? "Required" : null,
      ),
    );
  }
}