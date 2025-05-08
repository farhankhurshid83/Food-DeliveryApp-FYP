import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../login_sign_up/pre_login.dart';
import '../widgets/custom_btn.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final box = GetStorage(); // GetStorage instance

  List<Map<String, String>> onboardingData = [
    {
      "image": "assets/images/onbording_1.png",
      "title": "Order Your Food",
      "description": "Get your favorite food delivered to your doorstep!"
    },
    {
      "image": "assets/images/onbording_2.png",
      "title": "Fast & Fresh",
      "description": "We deliver fresh and hot food on time!"
    },
    {
      "image": "assets/images/onbording_3.png",
      "title": "Enjoy Your Meal",
      "description": "Experience delicious food anytime, anywhere."
    }
  ];

  List<IconData> onboardingIcons = [
    Icons.shopping_cart,
    Icons.delivery_dining,
    Icons.restaurant_menu,
  ];

  // Skip to last page and save flag
  void skipToLast() {
    _pageController.jumpToPage(onboardingData.length - 1);
    completeOnboarding();
  }

  // Go to the next page or complete onboarding
  void nextPage() {
    if (_currentPage < onboardingData.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      completeOnboarding();
    }
  }

  // Save flag and navigate to PreLogin
  void completeOnboarding() {
    box.write('hasSeenOnboarding', true); // Save in GetStorage
    Get.offAll(() => PreLogin()); // Navigate
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: onboardingData.length,
            physics: BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      onboardingData[index]["image"]!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              );
            },
          ),

          // Skip Button
          Positioned(
            top: 50,
            right: 20,
            child: GestureDetector(
              onTap: skipToLast,
              child: Text(
                "Skip >",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: EdgeInsets.all(20),
              height: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Icon(
                        onboardingIcons[_currentPage],
                        color: Colors.orange,
                        size: 40,
                      ),
                      SizedBox(height: 10),

                      Text(
                        onboardingData[_currentPage]["title"]!,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(height: 10),

                      Text(
                        onboardingData[_currentPage]["description"]!,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),

                  // Page Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      onboardingData.length,
                          (i) => Container(
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 12 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i ? Colors.orange : Colors.grey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  // Next Button
                  CustomButton(
                    buttonText: _currentPage == onboardingData.length - 1 ? "Get Started" : "Next",
                    textStyle: TextStyle(fontSize: 16, color: Colors.white),
                    onPressed: nextPage,
                    borderRadius: 22.0,
                    buttonColor: Color(0xfff05424),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
