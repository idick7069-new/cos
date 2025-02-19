import 'package:cos_connect/ui/views/edit_profile_page.dart';
import 'package:cos_connect/ui/views/public_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'ui/views/login_page.dart';
import 'ui/views/home_page.dart';
import 'ui/views/splash_page.dart';
import 'ui/views/profile_page.dart';  // 引入 ProfilePage

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(ProviderScope(child: MyApp()));  // 確保 ProviderScope 包裹 MyApp
}


class MyApp extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routerConfig: _router,
    );
  }

  final GoRouter _router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true, // 這會打印路由變動的詳細信息
    routes: [
      // 根據 Firebase 登入狀態決定要前往哪個頁面
      GoRoute(
        path: '/',
        builder: (context, state) {
          return StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.active) {
                if (snapshot.hasData) {
                  return HomePage(); // 有用戶登入，進入首頁
                } else {
                  return LoginPage(); // 沒有用戶登入，進入登入頁面
                }
              }
              return Center(child: CircularProgressIndicator()); // 等待數據載入
            },
          );
        },
      ),

      // 靜態路由
      GoRoute(path: '/login', builder: (context, state) => LoginPage()),
      GoRoute(path: '/home', builder: (context, state) => HomePage()),
      GoRoute(path: '/profile', builder: (context, state) => ProfilePage()),
      GoRoute(path: '/edit_profile', builder: (context, state) => EditProfilePage()),

      // **動態路由**: 顯示特定 userId 的公開個人檔案
      GoRoute(
        path: '/profile/:userId',
        builder: (context, state) {
          final String userId = state.pathParameters['userId']!;
          return PublicProfilePage(userId: userId);
        },
      ),
    ],
  );
}

