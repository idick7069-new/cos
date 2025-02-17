import 'package:cos_connect/ui/views/edit_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/views/login_page.dart';
import 'ui/views/home_page.dart';
import 'ui/views/splash_page.dart';
import 'ui/views/profile_page.dart';  // 引入 ProfilePage

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(ProviderScope(child: MyApp()));  // 確保 ProviderScope 包裹 MyApp
}

class MyApp extends StatelessWidget {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => StreamBuilder<User?>(
              stream: _auth.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  if (snapshot.hasData) {
                    return HomePage(); // 有用戶登入，進入首頁
                  } else {
                    return LoginPage(); // 沒有用戶登入，進入登入頁面
                  }
                }
                return CircularProgressIndicator(); // 還在等待數據
              },
            ),
        '/login': (context) => LoginPage(),
        '/home': (context) => HomePage(),
        '/profile': (context) => ProfilePage(),  // 加入 ProfilePage 路由
        '/edit_profile': (context) => EditProfilePage(), 
      },
    );
  }
}
