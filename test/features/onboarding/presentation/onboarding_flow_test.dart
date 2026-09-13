import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/app.dart';
import 'package:gyeotae/core/location/location_source.dart';
import 'package:gyeotae/core/storage/onboarding_storage.dart';
import 'package:gyeotae/features/home/presentation/home_screen.dart';
import 'package:gyeotae/features/onboarding/presentation/onboarding_screen.dart';
import 'package:gyeotae/features/onboarding/presentation/splash_screen.dart';
import 'package:gyeotae/features/onboarding/presentation/widgets/onboarding_footer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_location_source.dart';
import '../../../support/offline_repositories.dart';
import '../../../support/onboarding_overrides.dart';

/// 앱을 처음부터 띄운다. 스플래시가 어디로 보내는지까지 본다.
Future<({FakeOnboardingStorage storage, FakeLocationSource location})> _launch(
  WidgetTester tester, {
  bool seen = false,
}) async {
  final storage = FakeOnboardingStorage(hasSeen: seen);
  final location = FakeLocationSource(now: (lat: 37.47, lng: 126.75));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        onboardingStorageProvider.overrideWithValue(storage),
        splashHoldProvider.overrideWithValue(Duration.zero),
        splashWarmupProvider.overrideWithValue((_) async {}),
        locationSourceProvider.overrideWithValue(location),
        ...offlineRepositories(),
      ],
      child: const GyeotaeApp(),
    ),
  );
  await tester.pumpAndSettle();

  return (storage: storage, location: location);
}

Future<void> _next(WidgetTester tester) async {
  await tester.tap(find.byKey(OnboardingFooter.nextButtonKey));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('첫 실행 1회', () {
    testWidgets('처음이면 스플래시 다음에 온보딩이 뜬다', (tester) async {
      await _launch(tester);

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.textContaining('하나의 길이 됩니다'), findsOneWidget);
    });

    testWidgets('이미 봤으면 곧장 홈이다', (tester) async {
      await _launch(tester, seen: true);

      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('건너뛰어도 본 것으로 친다', (tester) async {
      final env = await _launch(tester);

      await tester.tap(find.byKey(OnboardingScreen.skipButtonKey));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(env.storage.hasSeen, isTrue, reason: '다시 열었을 때 또 뜨면 안 된다');
    });
  });

  group('세 장의 순서', () {
    testWidgets('무엇을 하는 앱인지 → 안심 → 위치 부탁', (tester) async {
      await _launch(tester);

      expect(find.textContaining('하나의 길이 됩니다'), findsOneWidget);

      await _next(tester);
      expect(find.textContaining('괜찮습니다'), findsOneWidget);
      // 애매한 유사도라야 "확신이 없어도"라는 말이 성립한다.
      expect(find.text('63'), findsOneWidget);
      expect(find.textContaining('확인은 보호자가 합니다'), findsOneWidget);

      await _next(tester);
      expect(find.textContaining('내 주변 사건을'), findsOneWidget);
      expect(find.textContaining('평소 위치를 저장하거나 추적하지 않습니다'), findsOneWidget);
    });

    testWidgets('마지막 장에서는 건너뛸 수 없다', (tester) async {
      await _launch(tester);
      await _next(tester);
      await _next(tester);

      // "나중에 할게요"와 같은 일을 하는 버튼이 둘이면 헷갈린다.
      expect(
        tester
            .widget<TextButton>(find.byKey(OnboardingScreen.skipButtonKey))
            .onPressed,
        isNull,
      );
      expect(find.byKey(OnboardingFooter.nextButtonKey), findsNothing);
    });
  });

  group('위치 권한(온보딩 3장)', () {
    testWidgets('허용하기를 누르면 위치를 물어보고 홈으로 간다', (tester) async {
      final env = await _launch(tester);
      await _next(tester);
      await _next(tester);

      await tester.tap(find.byKey(OnboardingFooter.allowLocationKey));
      await tester.pumpAndSettle();

      expect(env.location.calls, contains('current(ask)'));
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('나중에 할게요를 누르면 묻지 않고 홈으로 간다', (tester) async {
      final env = await _launch(tester);
      await _next(tester);
      await _next(tester);

      await tester.tap(find.byKey(OnboardingFooter.laterKey));
      await tester.pumpAndSettle();

      // 거부한 것이 아니라 아직 안 물어본 것이다. 위치 없이도 앱은 돈다.
      expect(
        env.location.calls,
        isNot(contains('current(ask)')),
        reason: '미뤘는데 홈에서 팝업이 뜨면 온보딩에서 설명한 의미가 없다',
      );
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(env.storage.hasSeen, isTrue);
    });
  });
}
