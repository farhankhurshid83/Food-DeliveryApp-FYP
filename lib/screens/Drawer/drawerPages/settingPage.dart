import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controller/auth_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AuthController _authController = Get.find<AuthController>();
  @override
  void initState() {
    super.initState();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).cardColor,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.lock, color: Colors.white),
                    title: const Text(
                      'Change Password',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    onTap: () {
                      Get.dialog(
                        AlertDialog(
                          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                          title: const Text(
                            'Change Password',
                            style: TextStyle(fontSize: 18),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'New Password',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onChanged: (value) =>
                                _authController.newPassword = value,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onChanged: (value) =>
                                _authController.confirmPassword = value,
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                final success = await _authController
                                    .changePassword();
                                if (success) {
                                  Get.back();
                                  Get.snackbar('Success',
                                      'Password changed successfully',
                                      backgroundColor: Colors.green,
                                      colorText: Colors.white);
                                }
                              },
                              child: const Text('Change',
                                  style: TextStyle(color: Colors.orange)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading:
                    const Icon(Icons.delete_forever, color: Colors.white),
                    title: const Text(
                      'Delete Account',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    onTap: () {
                      Get.dialog(
                        AlertDialog(
                          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                          title: const Text(
                            'Delete Account',
                            style: TextStyle(fontSize: 18),
                          ),
                          content: const Text(
                              'Are you sure you want to delete your account? This action cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                final success =
                                await _authController.deleteAccount();
                                if (success) {
                                  Get.back();
                                  Get.snackbar('Success',
                                      'Account deleted successfully',
                                      backgroundColor: Colors.green,
                                      colorText: Colors.white);
                                }
                              },
                              child: const Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
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
