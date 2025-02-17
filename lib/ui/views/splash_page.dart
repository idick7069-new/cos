import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'home_page.dart';

class SplashPage extends StatefulWidget {
  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    await Future.delayed(Duration(seconds: 2)); // 模擬延遲，顯示 Splash
    if (mounted) {
      if (user != null) {
        // 如果用戶已經登入，跳轉到 HomePage
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // 如果用戶未登入，跳轉到 LoginPage
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(), // 顯示加載中的動畫
      ),
    );
  }
}
