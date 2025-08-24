import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trello/app/app_view.dart';
import 'package:trello/screens/intro_screen.dart';
import 'package:trello/screens/login_screen.dart';
import 'package:trello/screens/my_boards.dart';
import 'package:trello/screens/register_screen.dart';
import 'package:trello/screens/board_detail_screen.dart';
import 'package:trello/screens/boards_screen.dart';
import 'package:trello/screens/create_board_screen.dart';
import 'package:trello/screens/profile_screen.dart';
import 'package:trello/models/board.dart';
import 'package:trello/models/task.dart';
import 'package:trello/screens/task_detail_screen.dart';

final _routerKey = GlobalKey<NavigatorState>();
final _auth = FirebaseAuth.instance;

class AppRouter {
  AppRouter._();
  static const String intro = '/intro';
  static const String login = '/login';
  static const String register = '/register';

  static const String home = '/';
  static const String boards = '/boards';
  static const String myboards = '/myBoards';
  static const String createBoard = '/createBoard';
  static const String profile = '/profile';
  static const String boardDetail = '/boardDetail';
  static const String taskDetail = '/taskDetail';
}

final router = GoRouter(
  navigatorKey: _routerKey,
  initialLocation: AppRouter.intro,
  redirect: (context, state) async {
    final user = _auth.currentUser;
    final loggedIn = user != null;
    final currentLoc = state.matchedLocation;

    final loggingInPages = [
      AppRouter.intro,
      AppRouter.login,
      AppRouter.register,
    ];

    if (!loggedIn && !loggingInPages.contains(currentLoc)) {
      return AppRouter.intro;
    }

    if (loggedIn && loggingInPages.contains(currentLoc)) {
      return AppRouter.home;
    }

    return null;
  },
  refreshListenable: GoRouterRefreshStream(_auth.authStateChanges()),
  routes: [
    // Giriş yapılmamış kullanıcıya gösterilen sayfalar
    GoRoute(
      path: AppRouter.intro,
      builder: (context, state) => const IntroScreen(),
    ),
    GoRoute(
      path: AppRouter.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRouter.register,
      builder: (context, state) => const RegisterScreen(),
    ),

    // Giriş yapılmış kullanıcının erişebileceği ana uygulama alanı
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => AppView(navigationShell: navigationShell),
      branches: [
        // Ana boards sayfası
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRouter.home,
              builder: (context, state) => const BoardsScreen(),
            ),
          ],
        ),
        // Board oluşturma sayfası
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRouter.createBoard,
              builder: (context, state) => const CreateBoardScreen(),
            ),
          ],
        ),
        // Benim panolarım
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRouter.myboards,
              builder: (context, state) => const MyBoards(),
            ),
          ],
        ),
        // Profil
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRouter.profile,
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
    
    // Board detay sayfası (Shell route dışında)
    GoRoute(
      path: '${AppRouter.boardDetail}/:boardId',
      builder: (context, state) {
        final board = state.extra as Board?;
        return BoardDetailScreen(board: board!);
      },
      routes: [
        GoRoute(
          path: AppRouter.taskDetail,
          builder: (context, state) => TaskDetailScreen(task: state.extra as Task),
        ),
      ],
    ),
  ],
);

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}