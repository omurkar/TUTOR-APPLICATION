import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import Screens
import 'firebase_options.dart';
import 'screens/common/role_selection.dart';
import 'screens/auth/student_login.dart';
import 'screens/auth/student_signup.dart';
import 'screens/tutor/tutor_login.dart';
import 'screens/tutor/tutor_signup.dart';
import 'screens/student/student_dashboard.dart';
import 'screens/tutor/tutor_dashboard.dart';
import 'screens/student/profile_setup.dart';
import 'screens/tutor/tutor_profile_setup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tutor App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),

      routes: {
        '/role_selection': (context) => const RoleSelectionScreen(),
        '/student_login': (context) => const StudentLoginScreen(),
        '/student_signup': (context) => const StudentSignupScreen(),
        '/tutor_login': (context) => const TutorLoginScreen(),
        '/tutor_signup': (context) => const TutorSignupScreen(),
        '/student_dashboard': (context) => const StudentDashboard(),
        '/tutor_dashboard': (context) => const TutorDashboard(),
        '/student_profile_setup': (context) => const StudentProfileSetupScreen(),
        '/tutor_profile_setup': (context) => const TutorProfileSetupScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                String role = userData['role'] ?? 'student';
                bool isComplete = userData['isProfileComplete'] ?? false;

                if (role == 'tutor') {
                  if (isComplete) {
                    return const TutorDashboard();
                  } else {
                    return const TutorProfileSetupScreen();
                  }
                } else {
                  if (isComplete) {
                    return const StudentDashboard();
                  } else {
                    return const StudentProfileSetupScreen();
                  }
                }
              }
              return const RoleSelectionScreen();
            },
          );
        }
        return const RoleSelectionScreen();
      },
    );
  }
}
