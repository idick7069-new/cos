import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cos_connect/data/models/user_profile.dart';
import 'package:cos_connect/data/provider/firebase_provider.dart';

import '../../data/provider/user_profile_notifier.dart';

class ProfilePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 監聽 userProfileNotifierProvider 來獲取 UserProfile
    final userProfileState = ref.watch(userProfileProvider);

    // 輸出來檢查狀態
    if (userProfileState.isLoading) {
      print("Loading user profile...");
    }
    if (userProfileState.error != null) {
      print("Error loading user profile: ${userProfileState.error}");
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(context, '/edit_profile');
            },
          ),
        ],
      ),
      body: userProfileState.isLoading
          ? Center(child: CircularProgressIndicator())
          : userProfileState.error != null
          ? Center(child: Text(userProfileState.error!))
          : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
    userProfileState.userProfile?.coverPhotoUrl != null && userProfileState.userProfile!.coverPhotoUrl!.isNotEmpty
                    ? Image.network(userProfileState.userProfile!.coverPhotoUrl!)
                    : Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.grey[200],
                        child: Center(child: Text("No cover photo")),
                      ),
                SizedBox(height: 16),
                Text("CN: ${userProfileState.userProfile?.cn ?? ''}", style: TextStyle(fontSize: 24)),
                SizedBox(height: 8),
                Text("Bio: ${userProfileState.userProfile?.bio ?? ''}", style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
    );
  }
}

