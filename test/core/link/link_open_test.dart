import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/app.dart';
import 'package:gyeotae/core/link/link_source.dart';
import 'package:gyeotae/core/mock/mock_backend.dart';
import 'package:gyeotae/core/push/push_messaging.dart';
import 'package:gyeotae/core/push/push_providers.dart';
import 'package:gyeotae/features/home/presentation/home_screen.dart';
import 'package:gyeotae/features/missing/presentation/missing_detail_screen.dart';
import 'package:gyeotae/features/missing/presentation/widgets/detail_top_bar.dart';
import 'package:gyeotae/features/onboarding/presentation/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_link_source.dart';
import '../../support/fake_push_messaging.dart';
import '../../support/offline_repositories.dart';
import '../../support/onboarding_overrides.dart';

late FakeLinkSource links;
late FakePushMessaging messaging;

Future<void> _pumpApp(
  WidgetTester tester, {
  Duration splashHold = Duration.zero,
  PushOpen? initialPush,
  bool settle = true,
}) async {
  // 상세 화면의 '찾는 중' 점이 계속 깜빡이면 pumpAndSettle이 끝나지 않는다.
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

  links = FakeLinkSource();
  addTearDown(links.dispose);
  messaging = FakePushMessaging()..initial = initialPush;
  addTearDown(messaging.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...startAfterOnboarding(hold: splashHold),
        ...offlineRepositories(),
        linkSourceProvider.overrideWithValue(links),
        pushMessagingProvider.overrideWithValue(messaging),
        deviceRegistrarProvider.overrideWithValue(FakeDeviceRegistrar()),
      ],
      child: const GyeotaeApp(),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

String _leadingLabel(WidgetTester tester) {
  return tester.getSemantics(find.byKey(DetailTopBar.leadingButtonKey)).label;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('앱 링크를 누르면 그 사건 상세가 열린다', (tester) async {
    await _pumpApp(tester);

    links.open('gyeotae://missing/${MockBackend.demoCaseId}');
    await tester.pumpAndSettle();

    expect(find.byType(MissingDetailScreen), findsOneWidget);
    expect(find.text('김하준'), findsOneWidget);
  });

  testWidgets('카카오톡 공유 링크도 같은 상세를 연다', (tester) async {
    await _pumpApp(tester);

    links.open(
      'kakao1234abcd://kakaolink?missing_id=${MockBackend.demoCaseId}',
    );
    await tester.pumpAndSettle();

    expect(find.byType(MissingDetailScreen), findsOneWidget);
  });

  testWidgets('링크로 열면 뒤로 대신 심볼을 두고, 누르면 홈으로 간다', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpApp(tester);

    links.open('gyeotae://missing/${MockBackend.demoCaseId}');
    await tester.pumpAndSettle();

    // 기능정의서 5.5 외부 유입 상세. 링크로 온 사람에게는 브랜드를 보여준다.
    expect(_leadingLabel(tester), '홈으로');

    await tester.tap(find.byKey(DetailTopBar.leadingButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(MissingDetailScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('사건 링크가 아니면 아무것도 열지 않는다', (tester) async {
    await _pumpApp(tester);

    links.open('gyeotae://map/somewhere');
    await tester.pumpAndSettle();

    expect(find.byType(MissingDetailScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('스플래시 중에 들어온 링크는 스플래시가 끝난 뒤 연다', (tester) async {
    await _pumpApp(
      tester,
      splashHold: const Duration(milliseconds: 800),
      settle: false,
    );
    await tester.pump();
    expect(find.byType(SplashScreen), findsOneWidget);

    links.open('gyeotae://missing/${MockBackend.demoCaseId}');
    await tester.pump();

    // 스플래시는 끝나면서 홈으로 go해 쌓인 화면을 걷어낸다. 그 위에 얹으면
    // 링크를 눌러 앱을 켰는데 홈만 보인다.
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(find.byType(MissingDetailScreen), findsOneWidget);
  });

  testWidgets('알림을 눌러 앱을 켜도 스플래시 뒤에 그 사건이 남는다', (tester) async {
    await _pumpApp(
      tester,
      splashHold: const Duration(milliseconds: 800),
      initialPush: const PushOpen(
        type: 'missing',
        caseId: MockBackend.demoCaseId,
      ),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(find.byType(MissingDetailScreen), findsOneWidget);

    // 알림으로 연 것은 앱 안의 이동이다. 뒤로 가면 홈이다.
    await tester.tap(find.byKey(DetailTopBar.leadingButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
