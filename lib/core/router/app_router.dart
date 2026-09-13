import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/map/presentation/map_screen.dart';
import '../../features/missing/presentation/missing_detail_screen.dart';
import '../../features/missing/presentation/missing_list_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/report/data/report.dart';
import '../../features/report/presentation/report_done_screen.dart';
import '../../features/report/presentation/report_screen.dart';

/// 경로 문자열은 여기서만 정의하고 화면에서는 상수로 참조한다.
class AppRoute {
  const AppRoute._();

  /// 스플래시(S0). 앱이 처음 서는 자리.
  static const String splash = '/splash';

  /// 온보딩(S0). 첫 실행에 한 번만 본다.
  static const String onboarding = '/onboarding';

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

  /// 제보 완료(S4-2). 확정된 제보를 `extra`로 넘긴다.
  static const String reportDonePath = '/missing/:id/report/done';

  /// `/missing/m_ab12cd34/report/done`.
  static String reportDone(String caseId) =>
      '/missing/$caseId/report/done';

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
    // 첫 실행인지 아닌지는 스플래시가 판단한다. 여기서 리다이렉트로 가르면
    // 저장소를 읽는 동안 홈이 한 번 깜빡였다가 온보딩으로 넘어간다.
    initialLocation: AppRoute.splash,
    routes: [
      GoRoute(
        path: AppRoute.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoute.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
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
        path: AppRoute.reportDonePath,
        builder: (context, state) {
          // 링크로 바로 들어오면 제보가 없다. 요약만 빠지고 화면은 선다.
          final extra = state.extra;

          return ReportDoneScreen(
            caseId: state.pathParameters['id']!,
            report: extra is Report ? extra : null,
          );
        },
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
