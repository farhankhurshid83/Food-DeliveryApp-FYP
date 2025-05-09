import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  // Function to launch WhatsApp with fallback to phone dialer
  Future<void> _launchWhatsApp() async {
    const String phoneNumber = '923411409535'; // Number without '+'
    final Uri whatsappUrl = Uri.parse('https://wa.me/$phoneNumber');
    final Uri phoneUrl = Uri.parse('tel:+$phoneNumber');
    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(phoneUrl)) {
        await launchUrl(phoneUrl);
      } else {
        Get.snackbar(
          'Error',
          'Could not open WhatsApp or phone dialer. Please ensure WhatsApp is installed.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to open WhatsApp: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Function to launch social media URL
  Future<void> _launchSocialMedia() async {
    const String url = 'https://x.com/FoodDeliveryApp';
    final Uri socialUrl = Uri.parse(url);
    try {
      if (await canLaunchUrl(socialUrl)) {
        await launchUrl(socialUrl, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar(
          'Error',
          'Could not open social media link. Please ensure a browser is installed.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to open social media: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'About Us',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        backgroundColor: Colors.orange,
        elevation: 4,
        shadowColor: Colors.green.withOpacity(0.3),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [Colors.black87, Colors.grey[900]!]
                : [Colors.white, Colors.grey[100]!],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              // About Us Section
              _buildSectionTitle('About Bite On Time', Icons.info),
              const SizedBox(height: 12),
              _buildCard(
                context,
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Welcome to our Food Delivery App! We bring your favorite meals from local restaurants right to your doorstep. Here’s what we offer:\n'
                        '• Browse a wide variety of cuisines and restaurants.\n'
                        '• Place orders seamlessly with real-time tracking.\n'
                        '• Enjoy fast and reliable delivery services.\n'
                        '• Customize your orders and apply promo codes easily.',
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Contact Us Section
              _buildSectionTitle('Contact Us', Icons.contact_support),
              const SizedBox(height: 12),
              _buildCard(
                context,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Need assistance? Reach out to us directly:',
                        style: TextStyle(fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _launchWhatsApp,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange, width: 1),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.phone, color: Colors.orange, size: 20),
                              SizedBox(width: 8),
                              Text(
                                '+92-341-1409535',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => Get.snackbar(
                          'Info',
                          'Email support coming soon!',
                          backgroundColor: Colors.orange,
                          colorText: Colors.white,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange, width: 1),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.email, color: Colors.orange, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'support@fooddeliveryapp.com',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _launchSocialMedia,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange, width: 1),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.link, color: Colors.orange, size: 20),
                              SizedBox(width: 8),
                              Text(
                                '@FoodDeliveryApp',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for section titles
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 28,
          color: Colors.orange,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // Helper method for card-like containers
  Widget _buildCard(BuildContext context, {required Widget child}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDarkMode ? Colors.grey[850] : Colors.white,
      shadowColor: isDarkMode ? Colors.black26 : Colors.grey.withOpacity(0.2),
      child: child,
    );
  }
}
