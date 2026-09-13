import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../push/push_providers.dart';
import '../widgets/app_bottom_nav.dart';

/// 네 탭을 담는 껍데기. 하단 네비게이션이 여기 한 곳에만 있다.
///
/// **탭마다 화면을 살려둔다.** 예전에는 탭이 각각 최상위 경로여서 탭을 누를
/// 때마다 이전 화면이 통째로 버려졌다. 목록의 스크롤과 검색창이 날아가고,
/// 지도는 네이티브 뷰를 처음부터 다시 띄우며 핀과 경로를 다시 그렸다.
/// [StatefulShellRoute.indexedStack]은 탭별 Navigator를 따로 들고 있어서
/// 돌아오면 보던 자리가 그대로다.
///
/// 상세(S3)·제보(S4)는 이 껍데기 **위**에 얹힌다. 네비바를 가리고 전체를
/// 덮으면서(기능정의서 5.5), 아래에서는 탭이 그대로 살아 있다. 닫고 나오면
/// 왔던 탭으로 돌아간다.
///
/// 푸시 토큰 등록도 여기서 시작한다. **스플래시나 온보딩에서 하지 않는다** —
/// 알림 권한 팝업이 앱을 켜자마자 뜨면, 아직 이게 무슨 앱인지도 모르는
/// 사람이 거부부터 누른다. 온보딩을 지나 본 화면에 닿은 다음에 묻는다.
class AppShell extends ConsumerWidget {
  const AppShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 결과를 화면에 쓰지 않는다. 등록이 실패해도 앱은 그대로 돈다.
    ref.watch(pushRegistrationProvider);

    return Scaffold(
      // 키보드는 안쪽 화면이 각자 처리한다. 여기서 줄이면 지도 탭의 플랫폼
      // 뷰까지 다시 레이아웃되면서 GL 표면이 검게 날아간다.
      resizeToAvoidBottomInset: false,
      body: shell,
      bottomNavigationBar: AppBottomNav(
        // 탭 순서와 브랜치 순서가 같다([AppTab] 주석 참고).
        current: AppTab.values[shell.currentIndex],
        onSelect: (tab) => shell.goBranch(tab.index),
      ),
    );
  }
}
