import 'dart:developer';

import 'package:cos_connect/data/provider/user_profile_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cos_connect/services/firebase_service.dart';
import 'package:cos_connect/data/models/user_profile.dart';

// FirebaseService provider
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

// UserProfileNotifier provider
final userProfileNotifierProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile?>(
  (ref) {
    final firebaseService = ref.read(firebaseServiceProvider);
    return UserProfileNotifier(firebaseService);
  },
);

// UserProfile provider
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return await firebaseService.getUserProfile();
});


// 透過 Firestore snapshots() 即時監聽 UserProfile
final userProfileStreamProvider = StreamProvider<UserProfile?>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.userProfileStream();
});