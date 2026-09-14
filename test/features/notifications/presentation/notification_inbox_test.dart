import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/app.dart';
import 'package:gyeotae/core/mock/mock_backend.dart';
import 'package:gyeotae/core/push/push_messaging.dart';
import 'package:gyeotae/core/push/push_providers.dart';
import 'package:gyeotae/core/widgets/app_top_bar.dart';
import 'package:gyeotae/features/missing/presentation/missing_detail_screen.dart';
import 'package:gyeotae/features/notifications/data/app_notification.dart';
import 'package:gyeotae/features/notifications/presentation/notification_inbox_screen.dart';
import 'package:gyeotae/features/notifications/presentation/widgets/notification_empty_view.dart';
import 'package:gyeotae/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_notification_repository.dart';
import '../../../support/fake_push_messaging.dart';
import '../../../support/offline_repositories.dart';
import '../../../support/onboarding_overrides.dart';

late FakeNotificationRepository notifications;
late FakePushMessaging messaging;

Future<void> _pumpApp(WidgetTester tester, {NotificationInbox? inbox}) async {
  // 상세 화면의 '찾는 중' 점이 계속 깜빡이면 pumpAndSettle이 끝나지 않는다.
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

  tester.view.physicalSize = const Size(1125, 2436);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  notifications = FakeNotificationRepository(inbox: inbox);
  messaging = FakePushMessaging();
  addTearDown(messaging.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...startAfterOnboarding(),
        ...offlineRepositories(notifications: notifications),
        pushMessagingProvider.overrideWithValue(messaging),
        deviceRegistrarProvider.overrideWithValue(FakeDeviceRegistrar()),
      ],
      child: const GyeotaeApp(),
    ),
  );
  await tester.pumpAndSettle();
}

NotificationInbox _unread() {
  return NotificationInbox(
    count: 2,
    unreadCount: 1,
    items: [
      fakeNotification(id: 'n_new', caseId: MockBackend.demoCaseId),
      fakeNotification(
        id: 'n_old',
        kind: NotificationKind.resolved,
        title: '찾았습니다',
        body: '제보해 주신 이순자 님을 찾았어요. 고맙습니다.',
        read: true,
      ),
    ],
  );
}

Future<void> _openInbox(WidgetTester tester) async {
  await tester.tap(find.byKey(AppTopBar.notificationButtonKey));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('안 읽은 알림이 있으면 상단바 알림 버튼에 점을 찍는다', (tester) async {
    await _pumpApp(tester, inbox: _unread());

    expect(find.byKey(AppTopBar.unreadDotKey), findsOneWidget);
  });

  testWidgets('다 읽었으면 점이 없다', (tester) async {
    await _pumpApp(tester);

    expect(find.byKey(AppTopBar.notificationButtonKey), findsOneWidget);
    expect(find.byKey(AppTopBar.unreadDotKey), findsNothing);
  });

  testWidgets('알림 버튼을 누르면 알림함이 열리고 전부 읽음이 된다', (tester) async {
    await _pumpApp(tester, inbox: _unread());

    await _openInbox(tester);

    expect(find.byType(NotificationInboxScreen), findsOneWidget);
    expect(find.text('내 주변에서 실종 신고가 있었어요'), findsOneWidget);
    expect(find.text('주변 실종 신고 · 12분 전', findRichText: true), findsOneWidget);
    expect(notifications.markReadCalls, 1);

    // 읽음으로 바뀌어도 이 화면을 보는 동안은 무엇이 새로 왔는지 남긴다.
    expect(
      find.descendant(
        of: find.byKey(NotificationTile.tileKey('n_new')),
        matching: find.byKey(NotificationTile.unreadDotKey),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(NotificationTile.tileKey('n_old')),
        matching: find.byKey(NotificationTile.unreadDotKey),
      ),
      findsNothing,
    );

    await tester.tap(find.byKey(AppTopBar.backButtonKey));
    await tester.pumpAndSettle();

    // 돌아오면 점이 꺼져 있다.
    expect(find.byKey(AppTopBar.unreadDotKey), findsNothing);
  });

  testWidgets('다시 열면 새로 온 것만 강조한다', (tester) async {
    await _pumpApp(tester, inbox: _unread());

    await _openInbox(tester);
    await tester.tap(find.byKey(AppTopBar.backButtonKey));
    await tester.pumpAndSettle();
    await _openInbox(tester);

    expect(find.byKey(NotificationTile.unreadDotKey), findsNothing);
    expect(notifications.markReadCalls, 1, reason: '읽을 것이 없으면 서버를 부르지 않는다');
  });

  testWidgets('알림을 누르면 그 사건 상세로 간다', (tester) async {
    await _pumpApp(tester, inbox: _unread());

    await _openInbox(tester);
    await tester.tap(find.byKey(NotificationTile.tileKey('n_new')));
    await tester.pumpAndSettle();

    expect(find.byType(MissingDetailScreen), findsOneWidget);
  });

  testWidgets('받은 알림이 없으면 무엇이 모이는지 알려준다', (tester) async {
    await _pumpApp(tester);

    await _openInbox(tester);

    expect(find.byType(NotificationEmptyView), findsOneWidget);
    expect(notifications.markReadCalls, 0);
  });

  testWidgets('앱이 켜져 있는 동안 푸시가 오면 알림함을 다시 받는다', (tester) async {
    await _pumpApp(tester);
    expect(find.byKey(AppTopBar.unreadDotKey), findsNothing);

    // 서버는 푸시를 보내면서 알림함에도 적는다.
    notifications.inbox = _unread();
    messaging.alert(
      const PushAlert(
        title: '내 주변에서 실종 신고가 있었어요',
        body: '김하준 · 7세 · 인하공전 도서관 앞',
        open: PushOpen(type: 'missing', caseId: MockBackend.demoCaseId),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AppTopBar.unreadDotKey), findsOneWidget);
  });
}
