import 'dart:developer';

import 'package:cos_connect/data/provider/user_profile_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cos_connect/services/firebase_service.dart';
import 'package:cos_connect/data/models/user_profile.dart';

// FirebaseService provider
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});
