import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cos_connect/services/firebase_service.dart';
import 'package:cos_connect/data/models/user_profile.dart';
class UserProfileNotifier extends StateNotifier<UserProfile?> {
  final FirebaseService _firebaseService;

  UserProfileNotifier(this._firebaseService) : super(null) {
    _listenToUserProfile();
  }

  // 監聽 Firestore 中的用戶資料變動
  void _listenToUserProfile() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          final userProfile = UserProfile.fromFirestore(snapshot.data()!);
          state = userProfile;  // 更新 state
        }
      });
    }
  }

  // 載入用戶資料
  Future<void> loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userProfile = await _firebaseService.getUserProfile();
        state = userProfile;
      }
    } catch (e) {
      state = null;
    }
  }

  // 更新用戶資料
  Future<void> updateUserProfile(UserProfile userProfile) async {
    try {
      await _firebaseService.updateUserProfile(userProfile);
      state = userProfile;
    } catch (e) {
      // 處理錯誤
    }
  }
}