import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/home_screen.dart';
import '../../features/map/presentation/map_screen.dart';
import '../../features/missing/presentation/missing_detail_screen.dart';
import '../../features/missing/presentation/missing_list_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/report/data/report.dart';
import '../../features/report/presentation/report_done_screen.dart';
import '../../features/report/presentation/report_screen.dart';
import 'app_shell.dart';

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

  // 로그인(S6)은 경로가 없다. 독립 화면이 아니라 등록을 시도할 때 끼어드는
  // 바텀시트라서, `showLoginSheet`로 띄운다(기능정의서 3).
}

/// 로그인은 선택이라 진입 화면은 항상 홈이고, 별도의 리다이렉트 가드가 없다.
///
/// 로그인이 필요한 화면을 나중에 추가할 때는 해당 [GoRoute]에만
/// `redirect`를 걸어서 그 화면에서만 로그인을 요구하도록 한다.
///
/// **네 탭은 [StatefulShellRoute]로 묶는다.** 탭마다 Navigator를 따로 들고
/// 있어서 탭을 옮겨도 보던 화면이 살아 있다([AppShell] 주석 참고).
final routerProvider = Provider<GoRouter>((ref) {
  // 탭 위를 덮는 화면(상세·제보·완료)이 얹히는 Navigator. 여기 얹어야
  // 하단 네비바를 가리고 전체를 덮는다(기능정의서 5.5). 껍데기는 그 아래에
  // 살아 있어서 닫고 나오면 보던 탭과 스크롤이 그대로다.
  //
  // provider 안에서 만든다. 라이브러리 최상위에 두면 테스트처럼 앱을 여러 번
  // 세우는 자리에서 같은 GlobalKey가 두 번 붙는다.
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        // **브랜치 순서가 [AppTab] 순서다.** 네비바가 그 순서로 탭을 고른다.
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.missingList,
                builder: (context, state) => const MissingListScreen(),
                // 상세·제보는 목록 가지에 달되 껍데기 위에 얹는다. 가지에
                // 달아야 상세를 닫았을 때 목록이 보던 자리 그대로 남는다.
                routes: [
                  GoRoute(
                    // AppRoute.missingDetailPath
                    path: ':id',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) =>
                        MissingDetailScreen(caseId: state.pathParameters['id']!),
                    routes: [
                      GoRoute(
                        // AppRoute.reportPath
                        path: 'report',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) =>
                            ReportScreen(caseId: state.pathParameters['id']!),
                        routes: [
                          GoRoute(
                            // AppRoute.reportDonePath
                            path: 'done',
                            parentNavigatorKey: rootNavigatorKey,
                            builder: (context, state) {
                              // 링크로 바로 들어오면 제보가 없다. 요약만
                              // 빠지고 화면은 선다.
                              final extra = state.extra;

                              return ReportDoneScreen(
                                caseId: state.pathParameters['id']!,
                                report: extra is Report ? extra : null,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.map,
                builder: (context, state) =>
                    MapScreen(initialCaseId: state.uri.queryParameters['case']),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
