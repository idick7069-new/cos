import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cos_connect/data/models/user_profile.dart';
import 'package:cos_connect/data/provider/firebase_provider.dart';

class ProfilePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 監聽 userProfileNotifierProvider 來獲取 UserProfile
    final userProfileAsync = ref.watch(userProfileStreamProvider);

    // 監聽 userProfileNotifierProvider，如果是 null 就觸發資料載入
    ref.listen<UserProfile?>(userProfileNotifierProvider, (_, state) {
      if (state == null) {
        ref.read(userProfileNotifierProvider.notifier).loadUserProfile();
      }
    });

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
      body: userProfileAsync.when(
        data: (userProfile) {
        if (userProfile == null) {
          return Center(child: Text("User not found"));
        }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                userProfile?.coverPhotoUrl != null && userProfile!.coverPhotoUrl!.isNotEmpty
                    ? Image.network(userProfile.coverPhotoUrl!)
                    : Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.grey[200],
                        child: Center(child: Text("No cover photo")),
                      ),
                SizedBox(height: 16),
                Text("CN: ${userProfile?.cn ?? ''}", style: TextStyle(fontSize: 24)),
                SizedBox(height: 8),
                Text("Bio: ${userProfile?.bio ?? ''}", style: TextStyle(fontSize: 16)),
              ],
            ),
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

