import 'package:cos_connect/ui/views/edit_profile_page.dart';
import 'package:cos_connect/ui/views/event_page.dart';
import 'package:cos_connect/ui/views/public_profile_page.dart';
import 'package:cos_connect/ui/views/reservation_manage_page.dart';
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

    redirect:  (BuildContext context, GoRouterState state){
      final user = FirebaseAuth.instance.currentUser;
      final isLoginPage = state.path == '/login';
      final isLoggedIn = user != null;

      // 如果未登入且不是登入頁，重定向到登入頁
      print('檢查 isLoginPage: $isLoginPage, isLoggedIn: $isLoggedIn');
      if (!isLoggedIn && !isLoginPage) {
        return '/login';
      }

      // 如果已經登入且在登入頁面，則重定向到首頁
      if (isLoggedIn && isLoginPage) {
        return '/'; // 已登入，跳轉到首頁
      }

      return null; // 沒有需要重定向，正常訪問當前頁面
    },
    routes: [
      // 根路由
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
        // 在此路由下加入所有需要登入後才能訪問的子路由
        routes: [
          // 登入頁面
          GoRoute(path: '/login', builder: (context, state) => LoginPage()),
          // 登錄後可訪問的頁面
          GoRoute(path: '/home', builder: (context, state) => HomePage()),
          GoRoute(path: '/profile', builder: (context, state) => ProfilePage()),
          GoRoute(path: '/edit_profile', builder: (context, state) => EditProfilePage()),
          GoRoute(
            path: '/profile/:userId',
            builder: (context, state) {
              final String userId = state.pathParameters['userId']!;
              return PublicProfilePage(userId: userId);
            },
          ),
          GoRoute(path: '/event', builder: (context, state) => EventPage()),
          GoRoute(path: '/reservation_manage', builder: (context, state) => ReservationManagePage()),
        ],
      ),
    ],
  );
}

