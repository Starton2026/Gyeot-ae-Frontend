import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/app.dart';
import 'package:gyeotae/core/mock/mock_backend.dart';
import 'package:gyeotae/core/theme/app_theme.dart';
import 'package:gyeotae/features/missing/data/missing_repository.dart';
import 'package:gyeotae/features/missing/data/mock_missing_repository.dart';
import 'package:gyeotae/features/missing/presentation/missing_list_screen.dart';
import 'package:gyeotae/features/missing/presentation/widgets/missing_empty_view.dart';
import 'package:gyeotae/features/missing/presentation/widgets/missing_resolved_divider.dart';
import 'package:gyeotae/features/missing/presentation/widgets/missing_search_field.dart';
import 'package:gyeotae/features/notifications/data/notification_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_notification_repository.dart';
import '../../../support/onboarding_overrides.dart';

Future<void> _pumpList(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        notificationRepositoryProvider.overrideWithValue(
          FakeNotificationRepository(),
        ),
        ...startAfterOnboarding(),
        missingRepositoryProvider.overrideWithValue(
          MockMissingRepository(MockBackend.seeded(), latency: Duration.zero),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const MissingListScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 세로 목록만 스크롤한다. 칩 줄도 스크롤 영역이라 찾아서 골라야 한다.
Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    240,
    scrollable: find
        .descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

/// 디바운스가 끝날 때까지 기다린다.
Future<void> _search(WidgetTester tester, String keyword) async {
  await tester.enterText(find.byKey(MissingSearchField.fieldKey), keyword);
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('목록에 마지막 목격 줄과 제보 수가 함께 뜬다', (tester) async {
    await _pumpList(tester);

    expect(find.widgetWithText(AppBar, '실종자'), findsOneWidget);
    expect(find.text('김하준'), findsOneWidget);
    expect(find.textContaining('인천 남동구 구월동 ·'), findsOneWidget);
    expect(find.textContaining('제보 '), findsWidgets);
  });

  testWidgets('전체 필터는 건수를 상태별로 쪼개 적는다', (tester) async {
    await _pumpList(tester);

    // 합계만 적으면 6명이 실종된 것으로 읽힌다. 그중 1명은 이미 찾았다.
    expect(find.text('진행 중 5건 · 발견 1건'), findsOneWidget);
    expect(find.text('전체 6건'), findsNothing);
  });

  testWidgets('전체 필터는 발견 완료 사건을 맨 아래에 경계를 두고 보여준다', (tester) async {
    await _pumpList(tester);

    await _scrollTo(tester, find.text('한복순'));

    expect(find.text('한복순'), findsOneWidget);
    expect(find.text('발견완료'), findsOneWidget);
    // 카드가 갑자기 흐려지는 이유를 알려주는 줄.
    expect(find.byKey(MissingResolvedDivider.dividerKey), findsOneWidget);
    expect(find.text('여기부터 발견된 사건 1건'), findsOneWidget);
  });

  testWidgets('발견 칩은 끝난 사건만 남긴다', (tester) async {
    await _pumpList(tester);

    await tester.tap(find.text('발견'));
    await tester.pumpAndSettle();

    expect(find.text('발견 1건'), findsOneWidget);
    // 전부 발견 완료라 경계라고 할 것이 없다.
    expect(find.byKey(MissingResolvedDivider.dividerKey), findsNothing);
    expect(find.text('한복순'), findsOneWidget);
    expect(find.text('발견완료'), findsOneWidget);
    expect(find.text('김하준'), findsNothing);
  });

  testWidgets('진행중 칩을 누르면 발견 완료가 빠지고 건수가 바뀐다', (tester) async {
    await _pumpList(tester);

    await tester.tap(find.text('진행중'));
    await tester.pumpAndSettle();

    expect(find.text('진행 중 5건'), findsOneWidget);
    expect(find.text('한복순'), findsNothing);
    expect(find.byKey(MissingResolvedDivider.dividerKey), findsNothing);
  });

  testWidgets('구분 칩은 상태를 가리지 않고 그 구분만 추린다', (tester) async {
    await _pumpList(tester);

    await tester.tap(find.text('아동'));
    await tester.pumpAndSettle();

    expect(find.text('아동 2건'), findsOneWidget);
    expect(find.text('이순자'), findsNothing);
  });

  testWidgets('지역으로 검색하면 그 사건만 남는다', (tester) async {
    await _pumpList(tester);

    await _search(tester, '구월동');

    expect(find.text('김하준'), findsOneWidget);
    expect(find.text('이순자'), findsNothing);
  });

  testWidgets('검색 결과가 없으면 빈 상태를 보여준다', (tester) async {
    await _pumpList(tester);

    await _search(tester, '없는이름');

    expect(find.byType(MissingEmptyView), findsOneWidget);
    expect(find.text('"없는이름" 결과가 없어요'), findsOneWidget);
  });

  testWidgets('홈에서 실종자 탭을 누르면 목록으로 간다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...startAfterOnboarding(),
          notificationRepositoryProvider.overrideWithValue(
            FakeNotificationRepository(),
          ),
        ],
        child: const GyeotaeApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('실종자'));
    await tester.pumpAndSettle();

    expect(find.byType(MissingListScreen), findsOneWidget);
  });
}
