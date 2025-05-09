import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Delivery_Boy_Panel/delivery_boy_screen.dart';
import '../admin_panel/admin_panel_home.dart';
import '../login_sign_up/login.dart';
import '../screens/navbar/navbar.dart';

class AuthController extends GetxController {
  static AuthController get instance => Get.find<AuthController>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Rxn<User> firebaseUser = Rxn<User>();
  var role = ''.obs;
  String newPassword = '';
  String confirmPassword = '';

  String get userId => firebaseUser.value?.uid ?? '';

  @override
  void onReady() {
    super.onReady();
    firebaseUser.bindStream(_auth.authStateChanges());
    // Log auth state changes for debugging
    _auth.authStateChanges().listen((user) {
      print('Auth state changed: UID=${user?.uid}');
    });
    ever(firebaseUser, _setInitialScreen);
  }

  Future<void> _setInitialScreen(User? user) async {
    // Skip navigation for specific routes
    if (Get.currentRoute == '/PreLogin' ||
        Get.currentRoute == '/OnboardingScreen' ||
        Get.currentRoute == '/AddDeliveryBoyScreen') {
      print('Skipping _setInitialScreen for route: ${Get.currentRoute}');
      return;
    }
    try {
      if (user == null) {
        print('No user signed in, navigating to LoginScreen');
        Get.offAll(() => LoginScreen());
        role.value = '';
      } else {
        print('Fetching user document for UID: ${user.uid}');
        DocumentSnapshot? userDoc;
        // Retry fetching user document up to 3 times
        for (int attempt = 1; attempt <= 3; attempt++) {
          try {
            userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
            if (userDoc.exists) break;
            print('Attempt $attempt: User document not found, retrying...');
            await Future.delayed(Duration(milliseconds: 500));
          } catch (e) {
            if (attempt == 3) rethrow;
          }
        }
        if (!userDoc!.exists) {
          print('User document not found for UID: ${user.uid}');
          Get.snackbar('Error', 'User profile not found. Please contact support.');
          await _auth.signOut();
          Get.offAll(() => LoginScreen());
          role.value = '';
          return;
        }
        String userRole = userDoc.get('role') ?? 'customer';
        role.value = userRole;
        print('User role: $userRole, navigating to appropriate screen');
        switch (userRole) {
          case 'admin':
            Get.offAll(() => AdminPanelScreen());
            break;
          case 'delivery':
            Get.offAll(() => DeliveryBoyScreen());
            break;
          case 'customer':
          default:
            Get.offAll(() => CustomBottomNavBar());
            break;
        }
      }
    } catch (e, stackTrace) {
      print('Error in _setInitialScreen: $e');
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Failed to set initial screen');
      Get.snackbar('Error', 'Unable to load user profile: $e');
      await _auth.signOut();
      Get.offAll(() => LoginScreen());
      role.value = '';
    }
  }

  Future<bool> signUp(String email, String password, String fullName) async {
    try {
      print('Signing up user: $email');
      UserCredential cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      print('User created with UID: ${cred.user!.uid}');
      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'displayName': fullName,
        'email': email,
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('User document created for UID: ${cred.user!.uid}');
      return true;
    } catch (e, stackTrace) {
      print('Sign up error: $e');
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Sign up failed');
      String errorMessage = _getFriendlyErrorMessage(e);
      Get.snackbar('Error', errorMessage);
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      print('Logging in user: $email');
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      print('User logged in: ${_auth.currentUser?.uid}');
      return true;
    } catch (e, stackTrace) {
      print('Login error: $e');
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Login failed');
      String errorMessage = _getFriendlyErrorMessage(e);
      Get.snackbar('Error', errorMessage);
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      print('Sending password reset email to: $email');
      await _auth.sendPasswordResetEmail(email: email);
      Get.snackbar('Success', 'Password reset email sent. Check your inbox.');
      return true;
    } catch (e, stackTrace) {
      print('Reset password error: $e');
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Password reset failed');
      String errorMessage = _getFriendlyErrorMessage(e);
      Get.snackbar('Error', errorMessage);
      return false;
    }
  }

  Future<bool> resetPasswordWithLink(String email, String newPassword) async {
    try {
      if (email.isEmpty) {
        Get.snackbar('Error', 'Please enter an email address.');
        return false;
      }
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(email)) {
        Get.snackbar('Error', 'Please enter a valid email address.');
        return false;
      }
      if (newPassword.isEmpty) {
        Get.snackbar('Error', 'Please enter a new password.');
        return false;
      }
      if (newPassword.length < 6) {
        Get.snackbar('Error', 'Password must be at least 6 characters.');
        return false;
      }
      print('Sending password reset link to: $email');
      await _auth.sendPasswordResetEmail(email: email);
      Get.snackbar('Info', 'A password reset link has been sent to your email. Please use it to reset your password.');
      return false;
    } catch (e, stackTrace) {
      print('Reset password with link error: $e');
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Reset password with link failed');
      String errorMessage = _getFriendlyErrorMessage(e);
      Get.snackbar('Error', errorMessage);
      return false;
    }
  }

  Future<bool> storeDeliveryBoyCredentials({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // Validate inputs
      if (email.isEmpty || password.isEmpty || fullName.isEmpty) {
        Get.snackbar('Error', 'All fields are required.');
        return false;
      }
      if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
        Get.snackbar('Error', 'Please enter a valid email address.');
        return false;
      }
      if (password.length < 6) {
        Get.snackbar('Error', 'Password must be at least 6 characters.');
        return false;
      }

      print('Creating delivery boy: $email, role: delivery');
      // Create a secondary FirebaseAuth instance
      FirebaseAuth secondaryAuth = FirebaseAuth.instanceFor(app: Firebase.app());
      UserCredential cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Delivery boy created with UID: ${cred.user!.uid}');

      // Store user data in Firestore
      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'displayName': fullName,
        'email': email,
        'role': 'delivery',
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('Firestore document created for UID: ${cred.user!.uid}');

      // Sign out from the secondary instance to avoid affecting the primary session
      await secondaryAuth.signOut();
      print('Signed out from secondary auth instance');

      Get.snackbar('Success', 'Delivery boy $fullName added successfully.');
      return true;
    } catch (e, stackTrace) {
      print('Store delivery boy error: $e');
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Store delivery boy credentials failed');
      String errorMessage = _getFriendlyErrorMessage(e);
      Get.snackbar('Error', errorMessage);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      print('Logging out user: ${_auth.currentUser?.uid}');
      await _auth.signOut();
      firebaseUser.value = null;
      role.value = '';
      Get.offAll(() => LoginScreen());
      print('User logged out successfully');
    } catch (e, stackTrace) {
      print('Logout error: $e');
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Logout failed');
      Get.snackbar('Error', 'Unable to log out. Please try again.');
    }
  }

  Future<bool> makeAdmin(String uid) async {
    try {
      print('Promoting user to admin: $uid');
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        Get.snackbar('Error', 'User not found.');
        return false;
      }
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'role': 'admin',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (firebaseUser.value?.uid == uid) {
        role.value = 'admin';
        await _setInitialScreen(firebaseUser.value);
      }
      Get.snackbar('Success', 'User promoted to admin successfully.');
      print('User $uid promoted to admin');
      return true;
    } catch (e, stackTrace) {
      print('Make admin error: $e');
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Make admin failed');
      String errorMessage = _getFriendlyErrorMessage(e);
      Get.snackbar('Error', errorMessage);
      return false;
    }
  }

  Future<bool> changePassword() async {
    try {
      if (newPassword.isEmpty || confirmPassword.isEmpty) {
        Get.snackbar('Error', 'Please enter both password fields.');
        return false;
      }
      if (newPassword != confirmPassword) {
        Get.snackbar('Error', 'Passwords do not match.');
        return false;
      }
      if (newPassword.length < 6) {
        Get.snackbar('Error', 'Password must be at least 6 characters.');
        return false;
      }
      if (firebaseUser.value == null) {
        Get.snackbar('Error', 'No user is signed in.');
        return false;
      }
      print('Changing password for user: ${firebaseUser.value!.uid}');
      await firebaseUser.value!.updatePassword(newPassword);
      newPassword = '';
      confirmPassword = '';
      Get.snackbar('Success', 'Password changed successfully.');
      print('Password changed successfully');
      return true;
    } catch (e, stackTrace) {
      print('Change password error: $e');
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Change password failed');
      String errorMessage = _getFriendlyErrorMessage(e);
      Get.snackbar('Error', errorMessage);
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      if (firebaseUser.value == null) {
        Get.snackbar('Error', 'No user is signed in.');
        return false;
      }
      final uid = firebaseUser.value!.uid;
      print('Deleting account for user: $uid');
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      await firebaseUser.value!.delete();
      firebaseUser.value = null;
      role.value = '';
      Get.offAll(() => LoginScreen());
      Get.snackbar('Success', 'Account deleted successfully.');
      print('Account deleted for UID: $uid');
      return true;
    } catch (e, stackTrace) {
      print('Delete account Dolan error: $e');
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Delete account failed');
      String errorMessage = _getFriendlyErrorMessage(e);
      Get.snackbar('Error', errorMessage);
      return false;
    }
  }

  String _getFriendlyErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'This email is already registered.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'The password is too weak. Please use a stronger password.';
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'requires-recent-login':
          return 'Please log in again to perform this action.';
        default:
          return 'An unexpected error occurred: ${error.message}';
      }
    } else if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
