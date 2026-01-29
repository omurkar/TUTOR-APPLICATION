import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> with SingleTickerProviderStateMixin {
  // --- ANIMATION CONTROLLERS ---
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // --- BRAND COLORS (Derived from your Logo) ---
  final Color _brandBlue = const Color(0xFF2E3192); // Royal Blue from 'Tutor' cap
  final Color _brandOrange = const Color(0xFFF15A24); // Orange from 'Tutor' text

  @override
  void initState() {
    super.initState();
    // Initialize Animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic)),
    );

    // Start Animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // --- BACKGROUND DECORATION ---
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _brandBlue.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _brandOrange.withOpacity(0.08),
              ),
            ),
          ),

          // --- MAIN CONTENT ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),

                      // 1. LOGO & BRANDING
                      Hero(
                        tag: 'app_logo',
                        child: Image.asset(
                          'assets/images/tnmlogo.png',
                          height: 100, // Adjust based on your logo's actual size
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Welcome!",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: _brandBlue,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Find the perfect tutor nearby or start teaching today.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),

                      const Spacer(),

                      // 2. SELECTION CARDS
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Continue as...",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      _buildRoleCard(
                        context,
                        title: "Student",
                        subtitle: "I want to find a tutor",
                        icon: Icons.school_outlined,
                        color: _brandBlue,
                        route: '/student_login',
                      ),

                      const SizedBox(height: 16),

                      _buildRoleCard(
                        context,
                        title: "Tutor",
                        subtitle: "I want to teach students",
                        icon: Icons.person_search_outlined,
                        color: _brandOrange,
                        route: '/tutor_login',
                      ),

                      const Spacer(),

                      // 3. FOOTER
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Powered by ", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                            Text("NextSolves", style: TextStyle(color: _brandBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- CUSTOM CARD WIDGET ---
  Widget _buildRoleCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Color color,
        required String route,
      }) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withOpacity(0.05),
        highlightColor: color.withOpacity(0.02),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.1), width: 1),
          ),
          child: Row(
            children: [
              // Icon Box
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[300], size: 18),
            ],
          ),
        ),
      ),
    );
  }
}