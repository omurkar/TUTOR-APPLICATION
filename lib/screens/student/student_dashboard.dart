import 'package:flutter/material.dart';
import 'package:tutor_app/screens/student/home.dart';
import 'package:tutor_app/screens/student/bookings.dart';
import 'package:tutor_app/screens/common/messenger.dart';
import 'package:tutor_app/screens/student/profile.dart'; // <--- THIS MATCHES THE FILE ABOVE
import 'package:tutor_app/services/notification_service.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const StudentHomeScreen(),
    const SharedBookingScreen(isTutor: false),
    const StudentMessengerScreen(),
    const StudentProfilePage(), // <--- Added 'const' back because the class above now has a const constructor
  ];

  @override
  void initState() {
    super.initState();
    NotificationService.saveTokenToDatabase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "Bookings"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: "Messages"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}