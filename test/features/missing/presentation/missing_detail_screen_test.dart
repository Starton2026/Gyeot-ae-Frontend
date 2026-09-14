import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/app.dart';
import 'package:gyeotae/core/mock/mock_backend.dart';
import 'package:gyeotae/core/map/map_plan.dart';
import 'package:gyeotae/core/router/app_router.dart';
import 'package:gyeotae/core/share/case_sharer.dart';
import 'package:gyeotae/core/widgets/static_kakao_map.dart';
import 'package:gyeotae/features/missing/data/missing_repository.dart';
import 'package:gyeotae/features/missing/data/mock_missing_repository.dart';
import 'package:gyeotae/features/missing/presentation/missing_detail_screen.dart';
import 'package:gyeotae/features/missing/presentation/widgets/detail_report_cta.dart';
import 'package:gyeotae/features/missing/presentation/widgets/detail_resolved_note.dart';
import 'package:gyeotae/features/missing/presentation/widgets/detail_top_bar.dart';
import 'package:gyeotae/features/missing/presentation/widgets/report_timeline.dart';
import 'package:gyeotae/features/notifications/data/notification_repository.dart';
import 'package:gyeotae/features/report/data/mock_report_repository.dart';
import 'package:gyeotae/features/report/data/report_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_case_sharer.dart';
import '../../../support/fake_notification_repository.dart';
import '../../../support/onboarding_overrides.dart';

/// 상세 화면을 띄운다. 사건과 제보가 같은 mock 저장소를 보게 맞춘다.
Future<ProviderContainer> _pumpDetail(
  WidgetTester tester, {
  String caseId = MockBackend.demoCaseId,
  CaseSharer? sharer,
}) async {
  // '찾는 중' 점이 계속 깜빡이면 pumpAndSettle이 끝나지 않는다. 움직임 줄이기를
  // 켜면 그 점이 멈춘다. 실제 기기의 접근성 설정과 같은 경로다.
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

  final backend = MockBackend.seeded();
  final container = ProviderContainer.test(
    overrides: [
      notificationRepositoryProvider.overrideWithValue(
        FakeNotificationRepository(),
      ),
      ...startAfterOnboarding(),
      missingRepositoryProvider.overrideWithValue(
        MockMissingRepository(backend, latency: Duration.zero),
      ),
      reportRepositoryProvider.overrideWithValue(
        MockReportRepository(backend, latency: Duration.zero),
      ),
      caseSharerProvider.overrideWithValue(sharer ?? FakeCaseSharer()),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const GyeotaeApp()),
  );
  await tester.pumpAndSettle();

  container.read(routerProvider).go(AppRoute.missingDetail(caseId));
  await tester.pumpAndSettle();

  return container;
}

Future<void> _scrollBy(WidgetTester tester, double dy) async {
  await tester.drag(find.byType(SingleChildScrollView), Offset(0, -dy));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('사건 정보가 사진 아래에 차례로 뜬다', (tester) async {
    await _pumpDetail(tester);

    expect(find.byType(MissingDetailScreen), findsOneWidget);
    expect(find.text('김하준'), findsOneWidget);
    expect(find.text('7세 · 남아'), findsOneWidget);
    expect(find.text('찾는 중'), findsOneWidget);
    expect(find.text('실종 일시'), findsOneWidget);
    expect(find.textContaining('노란 후드티'), findsOneWidget);
  });

  testWidgets('타임라인은 기본으로 60% 이상만 보여주고 몇 건을 숨겼는지 알린다', (tester) async {
    await _pumpDetail(tester);

    expect(find.text('제보 6건'), findsOneWidget);
    // 시드의 58.2% · 34.2% · 얼굴 미검출 세 건이 걸린다.
    expect(find.text('유사도가 낮은 3건 숨김'), findsOneWidget);
    expect(find.text('확인 필요'), findsNothing);
  });

  testWidgets('토글을 끄면 저신뢰 제보와 미검출까지 나온다', (tester) async {
    await _pumpDetail(tester);

    // 토글은 화면 아래쪽이라 먼저 굴려서 올린다. 딱 보이는 곳까지만 굴리면
    // 떠 있는 상단바 밑에 깔려서 눌리지 않는다.
    await tester.ensureVisible(find.byKey(ReportTimeline.filterSwitchKey));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 150));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ReportTimeline.filterSwitchKey));
    await tester.pumpAndSettle();

    expect(find.text('유사도가 낮은 3건 숨김'), findsNothing);
    expect(find.text('확인 필요'), findsOneWidget);
    expect(find.text('얼굴 미검출'), findsOneWidget);
  });

  testWidgets('이동 경로 미니 지도가 회색 판이 아니라 지도를 받는다', (tester) async {
    await _pumpDetail(tester);

    final map = tester.widget<StaticKakaoMap>(find.byType(StaticKakaoMap));

    // 실종 지점 하나 + 타임라인과 같은 60% 이상 제보 3건.
    expect(map.plan.marks.whereType<MissingMark>(), hasLength(1));
    expect(map.plan.marks.whereType<ReportMark>(), hasLength(3));
    expect(map.plan.fitMarks, isTrue);
  });

  testWidgets('타임라인 토글을 끄면 미니 지도에도 저신뢰 제보가 찍힌다', (tester) async {
    await _pumpDetail(tester);

    await tester.ensureVisible(find.byKey(ReportTimeline.filterSwitchKey));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 150));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ReportTimeline.filterSwitchKey));
    await tester.pumpAndSettle();

    final map = tester.widget<StaticKakaoMap>(find.byType(StaticKakaoMap));

    // 지도와 타임라인이 다른 제보를 보여주면 번호가 어긋나 보인다.
    expect(map.plan.marks.whereType<ReportMark>(), hasLength(6));
  });

  testWidgets('최초 실종이 타임라인 맨 아래에 남는다', (tester) async {
    await _pumpDetail(tester);
    await _scrollBy(tester, 1200);

    final origin = find.textContaining('최초 실종');
    expect(origin, findsOneWidget);

    // 실종 지점이 어떤 제보 카드보다도 아래에 있다.
    final originY = tester.getTopLeft(origin).dy;
    final firstCardY = tester.getTopLeft(find.text('제보 6건')).dy;
    expect(originY, greaterThan(firstCardY));
  });

  testWidgets('스크롤하면 상단바가 이름을 이어받는다', (tester) async {
    await _pumpDetail(tester);

    DetailTopBar bar() =>
        tester.widget<DetailTopBar>(find.byType(DetailTopBar));

    expect(bar().backgroundProgress, 0, reason: '사진 위에서는 투명하다');
    expect(bar().titleProgress, 0, reason: '본문에 이름이 보이는 동안은 제목이 없다');

    await _scrollBy(tester, 400);

    expect(bar().backgroundProgress, 1);
    expect(bar().titleProgress, 1);
    expect(find.text('김하준 · 7세'), findsOneWidget);
  });

  testWidgets('찾은 사건에는 제보 버튼 대신 찾았다고 적는다', (tester) async {
    await _pumpDetail(tester, caseId: 'm_kl12mn34');

    // 버튼을 남기면 찾은 사람의 "목격" 알림이 보호자에게 간다. 서버도 거절한다.
    expect(find.byKey(DetailReportCta.buttonKey), findsNothing);
    expect(find.byKey(DetailResolvedNote.noteKey), findsOneWidget);
    expect(find.text('찾았어요'), findsOneWidget);
  });

  testWidgets('경로에 든 제보는 앞 지점에서 어느 쪽으로 얼마나 갔는지 적는다', (tester) async {
    await _pumpDetail(tester);
    await _scrollBy(tester, 700);

    // F-3.5.7. 경로 복원이 이 서비스의 핵심이라, 점만 찍지 않고 방향을 말한다.
    expect(
      find.textContaining(RegExp(r'^[↑↗→↘↓↙←↖] \S+쪽 \d+\.\dkm$')),
      findsWidgets,
    );
    // 며칠에 걸친 제보도 순서가 읽히게 날짜를 붙인다.
    // 시드 제보는 몇 시간 전이라 자정 직후에 돌리면 "어제"가 된다.
    expect(find.textContaining(RegExp(r'^(오늘|어제) 오[전후] ')), findsWidgets);
  });

  testWidgets('제보 버튼은 아동이 아니면 문구가 바뀐다', (tester) async {
    await _pumpDetail(tester, caseId: 'm_cd34ef56');

    expect(find.text('이분을 봤어요'), findsOneWidget);
    expect(find.text('사진 한 장이면 됩니다 · 로그인 없이 제보'), findsOneWidget);
  });

  testWidgets('제보가 없는 사건은 공유를 권한다', (tester) async {
    await _pumpDetail(tester, caseId: 'm_cd34ef56');
    await _scrollBy(tester, 900);

    expect(find.text('제보 0건'), findsOneWidget);
    expect(find.text('아직 들어온 제보가 없어요'), findsOneWidget);
  });

  testWidgets('공유를 누르면 그 사건을 카카오톡 카드로 싣는다', (tester) async {
    final sharer = FakeCaseSharer();
    await _pumpDetail(tester, sharer: sharer);

    await tester.tap(find.byKey(DetailTopBar.shareButtonKey));
    await tester.pumpAndSettle();

    final card = sharer.cards.single;
    expect(card.caseId, MockBackend.demoCaseId);
    expect(card.title, '김하준 님을 찾고 있어요');
    expect(card.description, startsWith('7세 남아 · 인천 남동구 구월동'));
    expect(card.description, endsWith('경과'));
    // 본문 자리라 한자 워드마크가 아니라 곁애로 쓴다(설계 결정 10번).
    expect(card.buttonTitle, '곁애에서 보기');
    // 테스트의 서버 주소는 에뮬레이터 전용이라 카카오 서버가 사진을 못 가져간다.
    expect(card.imageUrl, isNull);
  });

  testWidgets('제보가 없는 사건은 타임라인의 공유 버튼으로도 보낸다', (tester) async {
    final sharer = FakeCaseSharer();
    await _pumpDetail(tester, caseId: 'm_cd34ef56', sharer: sharer);
    await _scrollBy(tester, 900);

    await tester.tap(find.byKey(ReportTimeline.emptyShareButtonKey));
    await tester.pumpAndSettle();

    // F-3.5.15. 제보 0건이면 더 많은 사람이 보게 하는 것이 할 수 있는 전부다.
    expect(sharer.cards.single.caseId, 'm_cd34ef56');
  });

  testWidgets('카카오톡이 없으면 왜 공유가 안 되는지 알린다', (tester) async {
    await _pumpDetail(
      tester,
      sharer: FakeCaseSharer(result: ShareResult.kakaoTalkMissing),
    );

    await tester.tap(find.byKey(DetailTopBar.shareButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('카카오톡이 설치되어 있어야 공유할 수 있어요'), findsOneWidget);
  });

  testWidgets('목록에서 사건을 누르면 상세로 간다', (tester) async {
    final container = await _pumpDetail(tester);

    container.read(routerProvider).go(AppRoute.missingList);
    await tester.pumpAndSettle();

    await tester.tap(find.text('김하준'));
    await tester.pumpAndSettle();

    expect(find.byType(MissingDetailScreen), findsOneWidget);
    expect(find.text('7세 · 남아'), findsOneWidget);
  });
}
