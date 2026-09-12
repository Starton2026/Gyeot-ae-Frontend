import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/app.dart';
import 'package:gyeotae/core/mock/mock_backend.dart';
import 'package:gyeotae/core/router/app_router.dart';
import 'package:gyeotae/features/map/presentation/map_screen.dart';
import 'package:gyeotae/features/map/presentation/widgets/map_case_carousel.dart';
import 'package:gyeotae/features/map/presentation/widgets/map_case_select_bar.dart';
import 'package:gyeotae/features/map/presentation/widgets/map_route_panel.dart';
import 'package:gyeotae/features/map/presentation/widgets/map_search_bar.dart';
import 'package:gyeotae/features/missing/data/missing_repository.dart';
import 'package:gyeotae/features/missing/data/mock_missing_repository.dart';
import 'package:gyeotae/features/report/data/mock_report_repository.dart';
import 'package:gyeotae/features/report/data/report_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 지도 화면을 띄운다.
///
/// 네이티브 지도(PlatformView)는 테스트에서 그려지지 않는다. 지도 위에 얹은
/// 검색·칩·카드만 확인한다. 핀과 카메라는 실기기에서 봐야 한다.
Future<ProviderContainer> _pumpMap(WidgetTester tester) async {
  final backend = MockBackend.seeded();
  final container = ProviderContainer.test(
    overrides: [
      missingRepositoryProvider.overrideWithValue(
        MockMissingRepository(backend, latency: Duration.zero),
      ),
      reportRepositoryProvider.overrideWithValue(
        MockReportRepository(backend, latency: Duration.zero),
      ),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const GyeotaeApp()),
  );
  await tester.pumpAndSettle();

  container.read(routerProvider).go(AppRoute.map);
  await tester.pumpAndSettle();

  return container;
}

Future<void> _search(WidgetTester tester, String keyword) async {
  await tester.enterText(find.byKey(MapSearchBar.fieldKey), keyword);
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('지도 위에 검색창·필터 칩·사건 카드가 얹힌다', (tester) async {
    await _pumpMap(tester);

    expect(find.byType(MapScreen), findsOneWidget);
    expect(find.byKey(MapSearchBar.fieldKey), findsOneWidget);
    // 진행 중인 사건만 센다. 발견 완료 한 건은 빠진다.
    expect(find.text('전체 5'), findsOneWidget);
    expect(find.byType(MapCaseCarousel), findsOneWidget);
    expect(find.text('김하준'), findsOneWidget);
  });

  testWidgets('건수 안내는 기준 지역과 정렬을 함께 알린다', (tester) async {
    await _pumpMap(tester);

    expect(find.text('인천 남동구 기준 진행 중 5건 · 긴급도순'), findsOneWidget);
  });

  testWidgets('구분 칩을 누르면 그 구분만 남는다', (tester) async {
    await _pumpMap(tester);

    await tester.tap(find.text('아동'));
    await tester.pumpAndSettle();

    expect(find.text('전체 2'), findsOneWidget);
    expect(find.text('이순자'), findsNothing);
  });

  testWidgets('검색하면 그 사건만 카드에 남는다', (tester) async {
    await _pumpMap(tester);

    await _search(tester, '구월동');

    expect(find.text('김하준'), findsOneWidget);
    expect(find.text('전체 1'), findsOneWidget);
  });

  testWidgets('결과가 없으면 카드를 감추고 그렇게 말한다', (tester) async {
    await _pumpMap(tester);

    await _search(tester, '없는이름');

    expect(find.byType(MapCaseCarousel), findsNothing);
    expect(find.text('조건에 맞는 사건이 없어요'), findsOneWidget);
  });

  testWidgets('홈에서 지도 탭을 누르면 지도로 간다', (tester) async {
    final container = await _pumpMap(tester);

    container.read(routerProvider).go(AppRoute.home);
    await tester.pumpAndSettle();

    await tester.tap(find.text('지도'));
    await tester.pumpAndSettle();

    expect(find.byType(MapScreen), findsOneWidget);
  });

  group('사건 선택 모드', () {
    Future<void> selectDemoCase(WidgetTester tester) async {
      // 캐러셀 첫 카드가 시연용 사건(김하준)이다.
      await tester.tap(find.text('김하준'));
      await tester.pumpAndSettle();
    }

    testWidgets('카드를 누르면 경로 패널이 열리고 캐러셀이 물러난다', (tester) async {
      await _pumpMap(tester);
      await selectDemoCase(tester);

      expect(find.byType(MapRoutePanel), findsOneWidget);
      expect(find.byType(MapCaseCarousel), findsNothing);
      expect(find.byType(MapCaseSelectBar), findsOneWidget);
      expect(find.byKey(MapSearchBar.fieldKey), findsNothing);
    });

    testWidgets('기본은 60% 이상만 세고, 토글을 끄면 전부 센다', (tester) async {
      await _pumpMap(tester);
      await selectDemoCase(tester);

      // 시드 제보 6건 중 60% 이상은 3건이다.
      expect(find.text('제보 3건으로 복원한 경로'), findsOneWidget);

      await tester.tap(find.byKey(MapRoutePanel.filterSwitchKey));
      await tester.pumpAndSettle();

      expect(find.text('제보 6건으로 복원한 경로'), findsOneWidget);
    });

    testWidgets('슬라이더를 왼쪽으로 끌면 그 시점까지만 남는다', (tester) async {
      await _pumpMap(tester);
      await selectDemoCase(tester);

      final slider = find.byKey(MapRoutePanel.sliderKey);
      final box = tester.getRect(slider);
      // 트랙의 왼쪽 끝(실종 시각)을 누른다.
      await tester.tapAt(Offset(box.left + 1, box.center.dy));
      await tester.pumpAndSettle();

      expect(find.text('아직 이 시점의 제보가 없어요'), findsOneWidget);
      expect(find.textContaining('까지'), findsOneWidget);
    });

    testWidgets('사건 바를 누르면 전체 보기로 돌아온다', (tester) async {
      await _pumpMap(tester);
      await selectDemoCase(tester);

      await tester.tap(find.byKey(MapCaseSelectBar.barKey));
      await tester.pumpAndSettle();

      expect(find.byType(MapRoutePanel), findsNothing);
      expect(find.byType(MapCaseCarousel), findsOneWidget);
    });

    testWidgets('/map?case=로 들어오면 그 사건이 바로 펴진다', (tester) async {
      final container = await _pumpMap(tester);

      container.read(routerProvider).go(AppRoute.mapForCase(MockBackend.demoCaseId));
      await tester.pumpAndSettle();

      expect(find.byType(MapRoutePanel), findsOneWidget);
      expect(find.text('김하준 · 7세'), findsOneWidget);
    });
  });
}
