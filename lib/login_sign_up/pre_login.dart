import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login.dart';
import 'sign_up.dart';
import '../widgets/custom_btn.dart';

class PreLogin extends StatelessWidget {
  const PreLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.orange.shade400,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width > 600 ? 40 : 20,
                ),
                child: Container(
                  height: MediaQuery.of(context).size.height,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.8), // Slight transparency for softness
                        ),
                        padding: EdgeInsets.all(20),
                        child: Image.asset(
                          "assets/images/logo/logo.png",
                          color: Colors.orange,
                          height: MediaQuery.of(context).size.width * 0.4, // Responsive
                          width: MediaQuery.of(context).size.width * 0.4,
                        ),
                      ),
                      SizedBox(height: 16),
                      // Title
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Bite',
                              style: GoogleFonts.poppins(
                                color: Colors.orange,
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
                      SizedBox(height: 8),
                      // Subtitle
                      Text(
                        "Welcome to Bite On Time",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(height: 40),
                      // Login Button
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CustomButton(
                          buttonText: 'Login',
                          textStyle: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                          onPressed: () {
                            Get.to(() => LoginScreen());
                          },
                          buttonColor: Colors.white,
                          borderRadius: 25.0,
                          width: MediaQuery.of(context).size.width * 0.8,
                        ),
                      ),
                      SizedBox(height: 16),
                      // SignUp Button
                      CustomButton(
                        buttonText: 'Sign Up',
                        textStyle: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          Get.to(() => SignUpScreen());
                        },
                        buttonColor: Colors.black,
                        borderRadius: 25.0,
                        width: MediaQuery.of(context).size.width * 0.8,
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
