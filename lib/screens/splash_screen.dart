import 'dart:async';
import 'package:flutter/material.dart';
import 'package:food_ui/admin_panel/admin_panel_home.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../deleviry_boy/delivery_boy_screen.dart';
import '../navbar/navbar.dart';
import 'on_bording.dart';
import '../login_sign_up/pre_login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  final box = GetStorage();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize fade animation for logo
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Initialize scale animation for title
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOut,
    );

    // Start animations
    _fadeController.forward();
    _scaleController.forward();

    // Navigate to next screen
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() {
    Future.delayed(const Duration(seconds: 5), () async {
      bool hasSeenOnboarding = box.read('hasSeenOnboarding') ?? false;
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String? role = await _getUserRole(user.uid);
        if (role == "admin") {
          Get.off(() => AdminPanelScreen());
        } else if (role == "delivery") {
          Get.off(() => DeliveryBoyScreen());
        } else {
          Get.off(() => CustomBottomNavBar());
        }
      } else {
        if (hasSeenOnboarding) {
          Get.off(() => PreLogin());
        } else {
          box.write('hasSeenOnboarding', true);
          Get.off(() => OnboardingScreen());
        }
      }
    });
  }

  Future<String?> _getUserRole(String userId) async {
    try {
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc['role'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                padding: EdgeInsets.all(10),
                child: Image.asset(
                  "assets/images/logo/logo.png",
                  color: Color(0xffff380e),
                  height: MediaQuery.of(context).size.width * 0.4, // Responsive
                  width: MediaQuery.of(context).size.width * 0.4,
                ),
              ),
            ),
            ScaleTransition(
              scale: _scaleAnimation,
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Bite',
                      style: GoogleFonts.poppins(
                        color: Color(0xffff380e),
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    TextSpan(
                      text: 'On',
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 32,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    TextSpan(
                      text: 'Time',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
