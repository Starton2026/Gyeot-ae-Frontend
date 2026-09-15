import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/app.dart';
import 'package:gyeotae/core/mock/mock_backend.dart';
import 'package:gyeotae/core/push/push_alert_bar.dart';
import 'package:gyeotae/core/push/push_messaging.dart';
import 'package:gyeotae/core/push/push_providers.dart';
import 'package:gyeotae/features/missing/presentation/missing_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_push_messaging.dart';
import '../../support/offline_repositories.dart';
import '../../support/onboarding_overrides.dart';

late FakePushMessaging messaging;

Future<void> _pumpApp(WidgetTester tester) async {
  // 상세 화면의 '찾는 중' 점이 계속 깜빡이면 pumpAndSettle이 끝나지 않는다.
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

  // 기본 800x600은 알림 막대의 [보기] 버튼이 화면 밖으로 밀린다.
  tester.view.physicalSize = const Size(1125, 2436);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  messaging = FakePushMessaging();
  addTearDown(messaging.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...startAfterOnboarding(),
        ...offlineRepositories(),
        pushMessagingProvider.overrideWithValue(messaging),
        // 안 갈아끼우면 토큰 등록이 진짜 소켓을 연다.
        deviceRegistrarProvider.overrideWithValue(FakeDeviceRegistrar()),
      ],
      child: const GyeotaeApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('알림을 누르면 그 사건 상세로 간다', (tester) async {
    await _pumpApp(tester);

    messaging.open(
      const PushOpen(type: 'missing', caseId: MockBackend.demoCaseId),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MissingDetailScreen), findsOneWidget);
  });

  testWidgets('앱이 켜져 있으면 알림을 직접 띄운다', (tester) async {
    await _pumpApp(tester);

    // 안드로이드는 앱이 앞에 있으면 알림을 안 그려준다. 앱이 대신 띄운다.
    messaging.alert(
      const PushAlert(
        title: '내 주변에서 실종 신고가 있었어요',
        body: '김하준 · 7세 · 인천 남동구 구월동',
        open: PushOpen(type: 'missing', caseId: MockBackend.demoCaseId),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(pushAlertBarKey), findsOneWidget);
    expect(find.text('내 주변에서 실종 신고가 있었어요'), findsOneWidget);

    await tester.tap(find.widgetWithText(SnackBarAction, '보기'));
    await tester.pumpAndSettle();

    expect(find.byType(MissingDetailScreen), findsOneWidget);
  });

  testWidgets('어디로 갈지 모르는 알림은 보기 버튼을 달지 않는다', (tester) async {
    await _pumpApp(tester);

    messaging.alert(const PushAlert(title: '공지', body: '점검이 있습니다'));
    await tester.pumpAndSettle();

    expect(find.byKey(pushAlertBarKey), findsOneWidget);
    expect(find.byType(SnackBarAction), findsNothing);
  });
}
