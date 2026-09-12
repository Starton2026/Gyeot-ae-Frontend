import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/app.dart';
import 'package:gyeotae/features/home/presentation/home_providers.dart';
import 'package:gyeotae/features/home/presentation/widgets/quiet_state_card.dart';
import 'package:gyeotae/features/home/presentation/widgets/urgent_case_banner.dart';
import 'package:gyeotae/features/missing/data/missing_case.dart';
import 'package:shared_preferences/shared_preferences.dart';

MissingCaseSummary _summary({
  String id = 'm_1',
  String name = '김하준',
  int age = 7,
  Gender gender = Gender.male,
  MissingCategory category = MissingCategory.child,
  int elapsedMinutes = 192,
  double? distanceKm = 1.2,
}) {
  return MissingCaseSummary(
    id: id,
    name: name,
    age: age,
    gender: gender,
    category: category,
    description: '노란 후드티, 검정 백팩, 파란 운동화',
    lastLat: 37.4491,
    lastLng: 126.7312,
    lastAddress: '인천 남동구 구월동 로데오거리',
    missingAt: DateTime(2026, 9, 12, 14, 40),
    elapsedMinutes: elapsedMinutes,
    status: CaseStatus.active,
    reportCount: 3,
    distanceKm: distanceKm,
    urgencyLevel: UrgencyLevel.critical,
  );
}

Future<void> _pumpHome(WidgetTester tester, HomeFeed feed) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [homeFeedProvider.overrideWith((ref) => feed)],
      child: const GyeotaeApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('골든타임 안의 사건이 있으면 긴급 배너가 뜬다', (tester) async {
    final urgent = _summary(elapsedMinutes: 172);

    await _pumpHome(
      tester,
      HomeFeed(
        urgentCase: urgent,
        nearbyCases: [urgent],
        nearbyCount: 1,
        activeCount: 5,
      ),
    );

    expect(find.byType(UrgentCaseBanner), findsOneWidget);
    expect(find.byType(QuietStateCard), findsNothing);
    expect(find.text('지금 찾고 있어요'), findsOneWidget);
    expect(find.text('김하준 · 7세 남아'), findsOneWidget);
    expect(find.text('이 아이를 봤어요'), findsOneWidget);
  });

  testWidgets('골든타임 안의 사건이 없으면 배너 대신 평상시 블록이 뜬다', (tester) async {
    await _pumpHome(
      tester,
      HomeFeed(
        urgentCase: null,
        nearbyCases: [_summary(elapsedMinutes: 560)],
        nearbyCount: 2,
        activeCount: 4,
      ),
    );

    expect(find.byType(UrgentCaseBanner), findsNothing);
    expect(find.byType(QuietStateCard), findsOneWidget);
    expect(find.text('현재 긴급 제보가 없어요'), findsOneWidget);
    expect(find.text('근처 사건 2건은 이음이가 계속 찾고 있어요'), findsOneWidget);
  });

  testWidgets('아동이 아니면 제보 CTA 문구가 바뀐다', (tester) async {
    final urgent = _summary(
      name: '이순자',
      age: 81,
      gender: Gender.female,
      category: MissingCategory.dementia,
      elapsedMinutes: 100,
    );

    await _pumpHome(
      tester,
      HomeFeed(
        urgentCase: urgent,
        nearbyCases: [urgent],
        nearbyCount: 1,
        activeCount: 1,
      ),
    );

    expect(find.text('이순자 · 81세 여성'), findsOneWidget);
    expect(find.text('이분을 봤어요'), findsOneWidget);
  });

  testWidgets('360x740 화면에서도 배너가 넘치지 않는다', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 740 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final urgent = _summary(elapsedMinutes: 172);

    await _pumpHome(
      tester,
      HomeFeed(
        urgentCase: urgent,
        nearbyCases: [urgent],
        nearbyCount: 3,
        activeCount: 14,
      ),
    );

    // 넘치면 pumpAndSettle 단계에서 이미 예외로 실패한다. 여기서는 실제로
    // 그려졌는지만 확인한다.
    expect(find.byType(UrgentCaseBanner), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('주변 목록과 지도 프리뷰가 건수를 그대로 보여준다', (tester) async {
    await _pumpHome(
      tester,
      HomeFeed(
        urgentCase: null,
        nearbyCases: [
          _summary(id: 'm_1'),
          _summary(id: 'm_2', name: '박서연', age: 9, gender: Gender.female),
        ],
        nearbyCount: 2,
        activeCount: 11,
      ),
    );

    expect(find.text('내 주변 실종 2건'), findsOneWidget);
    expect(find.text('인천 남동구 기준 · 긴급도순'), findsOneWidget);
    expect(find.text('진행 중인 사건 11건 모두 보기'), findsOneWidget);
    expect(find.text('1.2km'), findsNWidgets(2));
    expect(find.text('박서연'), findsOneWidget);
  });
}
