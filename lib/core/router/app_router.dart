import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';

/// 경로 문자열은 여기서만 정의하고 화면에서는 상수로 참조한다.
class AppRoute {
  const AppRoute._();

  static const String home = '/';
  static const String login = '/login';
}

/// 로그인은 선택이라 진입 화면은 항상 홈이고, 별도의 리다이렉트 가드가 없다.
///
/// 로그인이 필요한 화면을 나중에 추가할 때는 해당 [GoRoute]에만
/// `redirect`를 걸어서 그 화면에서만 로그인을 요구하도록 한다.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoute.home,
    routes: [
      GoRoute(
        path: AppRoute.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoute.login,
        builder: (context, state) => const LoginScreen(),
      ),
    ],
  );
});
