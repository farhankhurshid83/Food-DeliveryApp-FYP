import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin_panel/admin_panel_home.dart';
import '../login_sign_up/login.dart';
import '../navbar/navbar.dart';
import '../deleviry_boy/delivery_boy_screen.dart';

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
    ever(firebaseUser, _setInitialScreen);
  }

  Future<void> _setInitialScreen(User? user) async {
    if (Get.currentRoute == '/PreLogin' || Get.currentRoute == '/OnboardingScreen') {
      return;
    }
    try {
      if (user == null) {
        Get.offAll(() => LoginScreen());
        role.value = '';
      } else {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          Get.snackbar('Error', 'User profile not found. Please contact support.');
          await _auth.signOut();
          Get.offAll(() => LoginScreen());
          role.value = '';
          return;
        }
        String userRole = userDoc.get('role') ?? 'customer';
        role.value = userRole;
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
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current, reason: 'Failed to set initial screen');
      Get.snackbar('Error', 'Failed to load user profile: ${e.toString()}');
      Get.offAll(() => LoginScreen());
      role.value = '';
    }
  }

  Future<bool> signUp(String email, String password, String fullName) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'displayName': fullName,
        'email': email,
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
      });
      firebaseUser.value = _auth.currentUser;
      return true;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current, reason: 'Sign up failed');
      Get.snackbar('Error', 'Sign up failed: ${e.toString()}');
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      firebaseUser.value = _auth.currentUser;
      return true;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current, reason: 'Login failed');
      Get.snackbar('Error', 'Login failed: ${e.toString()}');
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      Get.snackbar('Success', 'Password reset email sent.');
      return true;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current, reason: 'Password reset failed');
      Get.snackbar('Error', 'Password reset failed: ${e.toString()}');
      return false;
    }
  }

  Future<bool> resetPasswordWithLink(String email, String newPassword) async {
    try {
      if (email.isEmpty) {
        throw Exception('Email cannot be empty');
      }
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(email)) {
        throw Exception('Invalid email format');
      }
      if (newPassword.isEmpty) {
        throw Exception('Password cannot be empty');
      }
      if (newPassword.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }
      List<String> methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isEmpty) {
        throw FirebaseAuthException(code: 'user-not-found', message: 'User not found');
      }
      Get.snackbar('Info', 'Password reset link required. Please use reset link sent to email.');
      return false;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current, reason: 'Reset password with link failed');
      Get.snackbar('Error', 'Reset password failed: ${e.toString()}');
      return false;
    }
  }

  Future<bool> addDeliveryBoy({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'displayName': fullName,
        'email': email,
        'role': 'delivery',
        'createdAt': FieldValue.serverTimestamp(),
      });
      Get.snackbar('Success', 'Delivery boy $fullName added.');
      return true;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current, reason: 'Add delivery boy failed');
      Get.snackbar('Error', 'Failed to add delivery boy: ${e.toString()}');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      firebaseUser.value = null;
      role.value = '';
      Get.offAll(() => LoginScreen());
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current, reason: 'Logout failed');
      Get.snackbar('Error', 'Logout failed: ${e.toString()}');
    }
  }

  Future<bool> makeAdmin(String uid) async {
    try {
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
      Get.snackbar('Success', 'User promoted to admin.');
      return true;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current, reason: 'Make admin failed');
      Get.snackbar('Error', 'Failed to promote user: ${e.toString()}');
      return false;
    }
  }

  Future<bool> changePassword() async {
    try {
      if (newPassword.isEmpty || confirmPassword.isEmpty) {
        Get.snackbar('Error', 'Please enter both password fields');
        return false;
      }
      if (newPassword != confirmPassword) {
        Get.snackbar('Error', 'Passwords do not match');
        return false;
      }
      if (newPassword.length < 6) {
        Get.snackbar('Error', 'Password must be at least 6 characters');
        return false;
      }
      if (firebaseUser.value == null) {
        Get.snackbar('Error', 'No user signed in');
        return false;
      }
      await firebaseUser.value!.updatePassword(newPassword);
      newPassword = '';
      confirmPassword = '';
      return true;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current, reason: 'Change password failed');
      Get.snackbar('Error', 'Failed to change password: ${e.toString()}');
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      if (firebaseUser.value == null) {
        Get.snackbar('Error', 'No user signed in');
        return false;
      }
      final uid = firebaseUser.value!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      await firebaseUser.value!.delete();
      firebaseUser.value = null;
      role.value = '';
      Get.offAll(() => LoginScreen());
      return true;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current, reason: 'Delete account failed');
      Get.snackbar('Error', 'Failed to delete account: ${e.toString()}');
      return false;
    }
  }
}
