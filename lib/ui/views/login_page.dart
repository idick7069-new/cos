import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/user_profile.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController(text:'idick7069@gmail.com');
  final TextEditingController _passwordController = TextEditingController(text:'123456');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 登入方法
  Future<void> _signInWithEmailPassword() async {
    try {
      final email = _emailController.text;
      final password = _passwordController.text;

      // 登錄 Firebase 用戶
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 登錄成功後，檢查 Firestore 中的用戶資料
      final user = userCredential.user;
      if (user != null) {
        final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final userSnapshot = await userDoc.get();

        // 如果 Firestore 中不存在該用戶資料，則創建
        if (!userSnapshot.exists) {
          final userProfile = UserProfile();

          // 創建用戶資料
          await userDoc.set(userProfile.toMap());
        }

        if (mounted) {
          context.go('/home'); // 登入成功後跳轉到 HomePage
        }
      }
    } catch (e) {
      // 錯誤處理
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _signInWithEmailPassword,
              child: Text('Sign in with Email'),
            ),
          ],
        ),
      ),
    );
  }
}
