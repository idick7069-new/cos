import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cos_connect/data/models/user_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 從 Firebase 讀取使用者資料
  Future<UserProfile> getUserProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      final docSnapshot = await _firestore.collection('users')
          .doc(user.uid)
          .get();

      if (docSnapshot.exists) {
        return UserProfile.fromFirestore(docSnapshot.data()!);
      } else {
        throw Exception("User not found");
      }
    } else {
      throw Exception("User not found");
    }
  }

  // 更新使用者資料
  Future<void> updateUserProfile(UserProfile userProfile) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set(
          userProfile.toFirestore());
    }else {
      throw Exception("User not found");
    }
  }
}
