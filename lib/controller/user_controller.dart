import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserController extends GetxController {
  Future<String> getDisplayName(String userId) async {
    try {
      var doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      return doc.exists ? doc['displayName'] ?? userId : userId;
    } catch (e) {
      return userId;
    }
  }
}