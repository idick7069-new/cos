import 'dart:developer';

import 'package:cos_connect/ui/views/event_page.dart';
import 'package:cos_connect/ui/views/public_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'friend_request_page.dart';
import 'login_page.dart';
import 'profile_page.dart'; // 引入 ProfilePage

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 登出方法
  Future<void> _signOut() async {
    await _auth.signOut();

    // 確保在進行導航之前，該頁面仍然存在
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login'); // 登出後跳轉回 LoginPage
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Home")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text("Welcome, ${_auth.currentUser?.email}"),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _signOut,
              child: Text("登出"),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                log("跳轉");
                // 跳轉至 ProfilePage
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
              child: Text("Go to Profile Page"),
            ),
            ElevatedButton(
              onPressed: () {
                log("跳轉2");
                // 跳轉至 ProfilePage
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PublicProfilePage(userId: 'BUNugzvzp0XNEryLDIBam20UHF63')),
                );
              },
              child: Text("Go to Public Profile Page"),
            ),
            IconButton(
              icon: Icon(Icons.group_add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FriendRequestsPage()),
                );
              },
            ),
            ElevatedButton(
              onPressed: () {
                // 跳轉至 ProfilePage
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EventPage()),
                );
              },
              child: Text("Go to Event Page"),
            ),
          ],
        ),
      ),
    );
  }
}
