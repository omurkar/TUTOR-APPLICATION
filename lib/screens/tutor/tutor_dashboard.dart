import 'package:flutter/material.dart';
import 'package:tutor_app/screens/tutor/home.dart';
import 'package:tutor_app/screens/tutor/profile.dart';
import 'package:tutor_app/screens/student/bookings.dart';
import 'package:tutor_app/screens/common/messenger.dart';
import 'package:tutor_app/services/notification_service.dart'; // Import Notification Service

class TutorDashboard extends StatefulWidget {
  const TutorDashboard({super.key});

  @override
  State<TutorDashboard> createState() => _TutorDashboardState();
}

class _TutorDashboardState extends State<TutorDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const TutorHomeScreen(),
    const SharedBookingScreen(isTutor: true),
    const StudentMessengerScreen(),
    const TutorProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    // Save Token so Student can send me messages
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
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "Schedule"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: "Messages"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}