import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/app.dart';
import 'package:gyeotae/core/location/location_source.dart';
import 'package:gyeotae/core/storage/onboarding_storage.dart';
import 'package:gyeotae/features/home/presentation/home_screen.dart';
import 'package:gyeotae/features/onboarding/presentation/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_location_source.dart';
import '../../../support/offline_repositories.dart';
import '../../../support/onboarding_overrides.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('배경이 준비되기 전에는 스플래시가 넘어가지 않는다', (tester) async {
    // 스플래시가 그림보다 먼저 끝나면 배경은 영영 안 보인다. 켤 때마다
    // 브랜드만 뜨고 그림은 안 뜨던 문제가 이것이었다.
    final warmup = Completer<void>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingStorageProvider.overrideWithValue(
            FakeOnboardingStorage(hasSeen: true),
          ),
          splashHoldProvider.overrideWithValue(Duration.zero),
          splashWarmupProvider.overrideWithValue((_) => warmup.future),
          locationSourceProvider.overrideWithValue(FakeLocationSource()),
          ...offlineRepositories(),
        ],
        child: const GyeotaeApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing, reason: '그림을 두고 먼저 넘어갔다');

    warmup.complete();
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('배경 그림이 실제로 번들에 들어 있다', (tester) async {
    // 이름을 바꾸거나 지우면 화면이 조용히 배경 없이 뜬다. 아무 오류도 나지
    // 않아서 눈으로 보기 전까지 모른다.
    final data = await rootBundle.load('assets/images/background.webp');

    expect(data.lengthInBytes, greaterThan(0));
  });
}
