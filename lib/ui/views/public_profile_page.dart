import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/provider/friend_request_notifier.dart';

class PublicProfilePage extends ConsumerWidget {
  final String userId;

  const PublicProfilePage({Key? key, required this.userId}) : super(key: key);



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendRequestState = ref.watch(friendRequestNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: Text("User Profile")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("User not found"));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: userData['coverPhotoUrl'] != null
                      ? NetworkImage(userData['coverPhotoUrl'])
                      : null,
                  child: userData['coverPhotoUrl'] == null ? Icon(Icons.person, size: 50) : null,
                ),
                SizedBox(height: 16),
                Text(userData['cn'] ?? "No Name", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                if (userData['bio'] != null) Text(userData['bio'], textAlign: TextAlign.center),
                SizedBox(height: 8),
                if (userData['regions'] != null) ...userData['regions'].map<Widget>((region) => Chip(label: Text(region))).toList(),
                SizedBox(height: 8),
                if (userData['pits'] != null) ...userData['pits'].map<Widget>((pit) => Chip(label: Text(pit))).toList(),
                ElevatedButton(
                  onPressed: friendRequestState.isLoading
                      ? null
                      : () => ref
                      .read(friendRequestNotifierProvider.notifier)
                      .sendFriendRequest(userId),
                  child: friendRequestState.isLoading
                      ? CircularProgressIndicator()
                      : Text("發送好友邀請"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
