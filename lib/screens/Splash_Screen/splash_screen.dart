import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../login_sign_up/pre_login.dart';
import '../On_Bording/on_bording.dart';
import '../../controller/auth_controller.dart'; // Import AuthController

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
    Future.delayed(const Duration(seconds: 5), () {
      // Get the AuthController instance
      final authController = Get.find<AuthController>();

      // Check if a user is logged in
      if (authController.firebaseUser.value != null) {
        print('User is logged in, skipping navigation from SplashScreen');
        return; // Do not navigate; let AuthController handle it
      }

      // If no user is logged in, proceed with onboarding or PreLogin
      bool hasSeenOnboarding = box.read('hasSeenOnboarding') ?? false;
      if (hasSeenOnboarding) {
        print('Navigating to PreLogin from SplashScreen');
        Get.off(() => PreLogin());
      } else {
        box.write('hasSeenOnboarding', true);
        print('Navigating to OnboardingScreen from SplashScreen');
        Get.off(() => OnboardingScreen());
      }
    });
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
                  height: MediaQuery.of(context).size.width * 0.4,
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
