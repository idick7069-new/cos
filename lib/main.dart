import 'package:cos_connect/ui/views/edit_profile_page.dart';
import 'package:cos_connect/ui/views/event_page.dart';
import 'package:cos_connect/ui/views/public_profile_page.dart';
import 'package:cos_connect/ui/views/reservation_manage_page.dart';
import 'package:cos_connect/ui/views/reservation_share_page.dart';
import 'package:cos_connect/ui/views/model/event_view_model.dart';
import 'package:cos_connect/data/models/reservation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'ui/views/login_page.dart';
import 'ui/views/home_page.dart';
import 'ui/views/splash_page.dart';
import 'ui/views/profile_page.dart'; // 引入 ProfilePage

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(ProviderScope(child: MyApp())); // 確保 ProviderScope 包裹 MyApp
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
    redirect: (BuildContext context, GoRouterState state) {
      final user = FirebaseAuth.instance.currentUser;
      final isLoginPage = state.matchedLocation == '/login';
      final isLoggedIn = user != null;
      final isPublicSharePage = state.matchedLocation == '/share';

      print('當前路徑: ${state.matchedLocation}');
      print('是否為公開分享頁: $isPublicSharePage');

      // 如果是公開分享頁面，不需要重定向
      if (isPublicSharePage) {
        return null;
      }

      // 如果未登入且不是登入頁，重定向到登入頁
      if (!isLoggedIn && !isLoginPage) {
        return '/login';
      }

      // 如果已經登入且在登入頁面，則重定向到首頁
      if (isLoggedIn && isLoginPage) {
        return '/';
      }

      return null;
    },
    routes: [
      // 公開分享頁面（不需要登入）
      GoRoute(
        path: '/share',
        builder: (context, state) => ReservationSharePage(
          isPublic: true,
        ),
      ),
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
        routes: [
          GoRoute(path: 'login', builder: (context, state) => LoginPage()),
          GoRoute(path: 'home', builder: (context, state) => HomePage()),
          GoRoute(path: 'profile', builder: (context, state) => ProfilePage()),
          GoRoute(
              path: 'edit_profile',
              builder: (context, state) => EditProfilePage()),
          GoRoute(
            path: 'profile/:userId',
            builder: (context, state) {
              final String userId = state.pathParameters['userId']!;
              return PublicProfilePage(userId: userId);
            },
          ),
          GoRoute(path: 'event', builder: (context, state) => EventPage()),
          GoRoute(
              path: 'reservation_manage',
              builder: (context, state) => ReservationManagePage()),
          GoRoute(
              path: 'reservation_share',
              builder: (context, state) {
                final Map<String, dynamic>? extra =
                    state.extra as Map<String, dynamic>?;
                return ReservationSharePage(
                  eventViewModels:
                      extra?['eventViewModels'] as List<EventViewModel>?,
                  reservations: extra?['reservations'] as List<Reservation>?,
                );
              }),
        ],
      ),
    ],
  );
}
