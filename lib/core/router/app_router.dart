import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/map/presentation/map_screen.dart';
import '../../features/missing/presentation/missing_detail_screen.dart';
import '../../features/missing/presentation/missing_list_screen.dart';
import '../../features/report/presentation/report_screen.dart';

/// 경로 문자열은 여기서만 정의하고 화면에서는 상수로 참조한다.
class AppRoute {
  const AppRoute._();

  static const String home = '/';
  static const String missingList = '/missing';

  /// 실종자 상세(S3). 경로를 만들 때는 [missingDetail]을 쓴다.
  static const String missingDetailPath = '/missing/:id';

  /// `/missing/m_ab12cd34`.
  static String missingDetail(String caseId) => '/missing/$caseId';

  /// 제보창(S4). 경로를 만들 때는 [report]를 쓴다.
  static const String reportPath = '/missing/:id/report';

  /// `/missing/m_ab12cd34/report`.
  static String report(String caseId) => '/missing/$caseId/report';

  static const String map = '/map';

  /// 지도를 열면서 사건 하나를 바로 편다(S3 미니 지도 → S5 사건 선택 모드).
  static String mapForCase(String caseId) => '/map?case=$caseId';
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
        path: AppRoute.missingList,
        builder: (context, state) => const MissingListScreen(),
      ),
      GoRoute(
        path: AppRoute.missingDetailPath,
        builder: (context, state) =>
            MissingDetailScreen(caseId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoute.reportPath,
        builder: (context, state) =>
            ReportScreen(caseId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoute.map,
        builder: (context, state) =>
            MapScreen(initialCaseId: state.uri.queryParameters['case']),
      ),
      GoRoute(
        path: AppRoute.login,
        builder: (context, state) => const LoginScreen(),
      ),
    ],
  );
});
