import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/app.dart';
import 'package:gyeotae/core/location/location_source.dart';
import 'package:gyeotae/core/mock/mock_backend.dart';
import 'package:gyeotae/core/router/app_router.dart';
import 'package:gyeotae/core/widgets/app_bottom_nav.dart';
import 'package:gyeotae/features/home/presentation/home_screen.dart';
import 'package:gyeotae/features/map/presentation/map_screen.dart';
import 'package:gyeotae/features/missing/data/missing_repository.dart';
import 'package:gyeotae/features/missing/data/mock_missing_repository.dart';
import 'package:gyeotae/features/missing/presentation/missing_detail_screen.dart';
import 'package:gyeotae/features/missing/presentation/missing_list_screen.dart';
import 'package:gyeotae/features/missing/presentation/widgets/missing_search_field.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_location_source.dart';
import '../../support/onboarding_overrides.dart';

Future<ProviderContainer> _launch(WidgetTester tester) async {
  // 상세의 '찾는 중' 점이 계속 깜빡이면 pumpAndSettle이 끝나지 않는다.
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final container = ProviderContainer.test(
    overrides: [
      ...startAfterOnboarding(),
      locationSourceProvider.overrideWithValue(
        FakeLocationSource(known: (lat: 37.47, lng: 126.75)),
      ),
      missingRepositoryProvider.overrideWithValue(
        MockMissingRepository(MockBackend.seeded(), latency: Duration.zero),
      ),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const GyeotaeApp()),
  );
  await tester.pumpAndSettle();

  return container;
}

/// 하단 네비게이션의 탭. 상단바 제목과 글자가 겹쳐서 네비바 안만 본다.
Finder _tab(String label) => find.descendant(
  of: find.byType(AppBottomNav),
  matching: find.text(label),
);

Future<void> _goTab(WidgetTester tester, String label) async {
  await tester.tap(_tab(label));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('탭을 옮겼다 돌아와도 보던 화면이 그대로다', (tester) async {
    await _launch(tester);

    await _goTab(tester, '실종자');
    final before = tester.state(find.byType(MissingListScreen));

    await tester.enterText(find.byType(MissingSearchField), '김');
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await _goTab(tester, '홈');
    await _goTab(tester, '실종자');

    expect(
      tester.state(find.byType(MissingListScreen)),
      same(before),
      reason: '탭마다 화면을 새로 만들면 스크롤도 입력도 다 날아간다',
    );

    // 검색어가 provider에만 남고 입력창은 비면, 목록은 걸러져 있는데
    // 검색창은 비어 있어서 왜 몇 건 없는지 알 길이 없어진다.
    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.controller?.text, '김');
  });

  testWidgets('탭을 떠나도 화면이 버려지지 않는다', (tester) async {
    await _launch(tester);

    // 켜자마자 지도까지 만들면 네이티브 뷰 띄우는 값을 앱 시작에 물린다.
    expect(find.byType(MapScreen, skipOffstage: false), findsNothing);

    await _goTab(tester, '실종자');
    await _goTab(tester, '홈');

    // IndexedStack이라 안 보일 뿐 트리에 남아 있다. 지도 탭이 네이티브 뷰를
    // 다시 띄우지 않는 것도 같은 이유다.
    expect(find.byType(MissingListScreen, skipOffstage: false), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('상세는 네비바를 덮고, 닫으면 보던 탭으로 돌아온다', (tester) async {
    final container = await _launch(tester);
    final router = container.read(routerProvider);

    // 홈에서 사건을 연다. 닫힐 때까지 기다리지 않는다.
    unawaited(router.push(AppRoute.missingDetail(MockBackend.demoCaseId)));
    await tester.pumpAndSettle();

    expect(find.byType(MissingDetailScreen), findsOneWidget);
    expect(
      find.byType(AppBottomNav),
      findsNothing,
      reason: '상세·제보는 네비바 없이 전체를 덮는다(기능정의서 5.5)',
    );

    router.pop();
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(AppBottomNav), findsOneWidget);
  });

  testWidgets('네비바 탭 순서가 브랜치 순서와 같다', (tester) async {
    await _launch(tester);

    // 어긋나면 지도를 눌렀을 때 엉뚱한 탭이 열린다.
    await _goTab(tester, '실종자');
    expect(find.byType(MissingListScreen), findsOneWidget);

    await _goTab(tester, '홈');
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
