import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cos_connect/data/models/user_profile.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 獲取當前用戶
  User? get currentUser => _auth.currentUser;

  // 獲取用戶資料
  Future<UserProfile?> getUserProfile() async {
    final user = _auth.currentUser;
    log('測試get $user');
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      log('測試get2 $userDoc');
      if (userDoc.exists) {
        // log('測試get3 ${userDoc.data()}');
        return UserProfile.fromFirestore(userDoc.data()!);
      }
    }
    return null;
  }

  // 監聽 Firestore 即時變更
  Stream<UserProfile?> userProfileStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return UserProfile.fromFirestore(snapshot.data()!);
    });
  }

  // 更新 Firestore 中的使用者資料
  Future<void> updateUserProfile(UserProfile userProfile) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set(userProfile.toMap(), SetOptions(merge: true));
  }

  // // 更新用戶資料
  // Future<void> updateUserProfile(UserProfile userProfile) async {
  //   final user = _auth.currentUser;
  //   if (user != null) {
  //     await _firestore
  //         .collection('users')
  //         .doc(user.uid)
  //         .update(userProfile.toMap());
  //   }
  // }

  Future<void> createUserProfile(UserProfile userProfile) async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final userExists = await userDoc.get();

      if (!userExists.exists) {
        await userDoc.set(userProfile.toMap()); // 創建用戶資料
      }
    }
  }
}
