import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cos_connect/data/provider/user_profile_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cos_connect/services/firebase_service.dart';
import 'package:cos_connect/data/models/user_profile.dart';
import 'package:cos_connect/data/models/user_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_provider.dart';

class UserProfileNotifier extends StateNotifier<UserProfileState> {
  final FirebaseService _firebaseService;

  UserProfileNotifier(this._firebaseService) : super(UserProfileState.loading()) {
    // 在初始化時呼叫 loadUserProfile
    loadUserProfile();
  }

  // 讀取 Firebase 上的使用者資料
  Future<void> loadUserProfile() async {
    try {
      print('開始載');
      final userProfile = await _firebaseService.getUserProfile();
      state = UserProfileState.success(userProfile);
    } catch (e) {
      print('載失敗');
      state = UserProfileState.error("資料載入失敗");
    }
  }

  // 更新暫存資料並儲存至 Firebase
  Future<void> updateUserProfile(UserProfile updatedProfile) async {
    try {
      // 儲存資料到 Firebase
      await _firebaseService.updateUserProfile(updatedProfile);
      // 更新暫存資料
      state = UserProfileState.success(updatedProfile);
    } catch (e) {
      state = UserProfileState.error("資料儲存失敗");
    }
  }

  // 取得當前的使用者資料
  UserProfile? getCurrentUserProfile() {
    return state.userProfile;
  }

}

final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfileState>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return UserProfileNotifier(firebaseService);
});
