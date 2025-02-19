import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cos_connect/data/models/user_profile.dart';
import 'package:cos_connect/data/provider/firebase_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../data/provider/user_profile_notifier.dart';

class ProfilePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileState = ref.watch(userProfileProvider);
    final userId = ref.read(firebaseServiceProvider).getUserId();
    String profileUrl = 'https://yourapp.com/profile/$userId';
    print('測試 profileUrl => $profileUrl');

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
                  child:  SafeArea(
                  child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 封面照片
                      userProfileState.userProfile?.coverPhotoUrl != null &&
                              userProfileState
                                  .userProfile!.coverPhotoUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                userProfileState.userProfile!.coverPhotoUrl!,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              width: double.infinity,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(child: Text("No cover photo")),
                            ),
                      SizedBox(height: 16),

                      // 名稱
                      Text(
                        userProfileState.userProfile?.cn ?? '未知',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),

                      // 性別
                      if (userProfileState.userProfile?.gender != null)
                        Text(
                          "性別: ${userProfileState.userProfile!.gender}",
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[700]),
                        ),
                      SizedBox(height: 8),

                      // 地區
                      if (userProfileState.userProfile?.regions != null &&
                          userProfileState.userProfile!.regions!.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          children: userProfileState.userProfile!.regions!
                              .map((region) => Chip(label: Text(region)))
                              .toList(),
                        ),

                      SizedBox(height: 16),

                      // 自我介紹
                      if (userProfileState.userProfile?.bio != null &&
                          userProfileState.userProfile!.bio!.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("自我介紹:",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text(
                              userProfileState.userProfile!.bio!,
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      SizedBox(height: 16),

                      // 坑單
                      if (userProfileState.userProfile?.pits != null &&
                          userProfileState.userProfile!.pits!.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("坑單:",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              children: userProfileState.userProfile!.pits!
                                  .map((pit) => Chip(label: Text(pit)))
                                  .toList(),
                            ),
                          ],
                        ),

                      SizedBox(height: 20),
                      QrImageView(
                        data: profileUrl,
                        version: QrVersions.auto,
                        size: 200.0,
                      ),
                    ],
                  ),),),
                ),
    );
  }
}
