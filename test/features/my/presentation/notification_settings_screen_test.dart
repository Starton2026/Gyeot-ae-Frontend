import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/core/push/notification_settings.dart';
import 'package:gyeotae/core/theme/app_theme.dart';
import 'package:gyeotae/features/my/presentation/notification_settings_screen.dart';
import 'package:gyeotae/features/my/presentation/widgets/notification_night_row.dart';
import 'package:gyeotae/features/my/presentation/widgets/notification_radius_chips.dart';
import 'package:gyeotae/features/my/presentation/widgets/notification_target_chips.dart';

import '../../../support/in_memory_notification_settings_storage.dart';

Future<InMemoryNotificationSettingsStorage> _pump(
  WidgetTester tester, {
  NotificationSettings? saved,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final storage = InMemoryNotificationSettingsStorage(saved);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        notificationSettingsStorageProvider.overrideWithValue(storage),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const NotificationSettingsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return storage;
}

bool _selected(WidgetTester tester, Key key) {
  return tester
      .widget<ChoiceChip>(
        find.descendant(of: find.byKey(key), matching: find.byType(ChoiceChip)),
      )
      .selected;
}

void main() {
  testWidgets('저장해 둔 설정이 켜진 채로 보인다', (tester) async {
    await _pump(
      tester,
      saved: const NotificationSettings(radiusKm: 10, elderly: false),
    );

    expect(_selected(tester, NotificationRadiusChips.chipKey(10)), isTrue);
    expect(_selected(tester, NotificationRadiusChips.chipKey(5)), isFalse);
    expect(
      _selected(tester, NotificationTargetChips.chipKey(AlertTarget.child)),
      isTrue,
    );
    expect(
      _selected(tester, NotificationTargetChips.chipKey(AlertTarget.elderly)),
      isFalse,
    );
  });

  testWidgets('반경 칩을 누르면 저장 버튼 없이 바로 바뀐다', (tester) async {
    final storage = await _pump(tester);

    await tester.tap(find.byKey(NotificationRadiusChips.chipKey(1)));
    await tester.pumpAndSettle();

    expect(_selected(tester, NotificationRadiusChips.chipKey(1)), isTrue);
    expect(storage.saved?.radiusKm, 1);
  });

  testWidgets('대상은 끄고 켤 수 있지만 마지막 하나는 꺼지지 않는다', (tester) async {
    final storage = await _pump(tester);

    await tester.tap(
      find.byKey(NotificationTargetChips.chipKey(AlertTarget.child)),
    );
    await tester.pumpAndSettle();
    expect(storage.saved?.child, isFalse);

    await tester.tap(
      find.byKey(NotificationTargetChips.chipKey(AlertTarget.elderly)),
    );
    await tester.pumpAndSettle();

    // 둘 다 꺼지면 서버가 "전부 받음"으로 읽는다. 눌러도 켜진 채로 남는다.
    expect(
      _selected(tester, NotificationTargetChips.chipKey(AlertTarget.elderly)),
      isTrue,
    );
    expect(storage.saved?.elderly, isTrue);
  });

  testWidgets('야간 알림을 끄면 밤에는 주변 신고를 받지 않는다고 저장한다', (tester) async {
    final storage = await _pump(tester);

    await tester.tap(find.byKey(NotificationNightRow.switchKey));
    await tester.pumpAndSettle();

    expect(storage.saved?.nightAlerts, isFalse);
    expect(
      tester.widget<Switch>(find.byKey(NotificationNightRow.switchKey)).value,
      isFalse,
    );
  });

  testWidgets('내 사건 소식은 이 설정과 상관없이 온다고 알려준다', (tester) async {
    await _pump(tester);

    // 보호자가 반경을 줄이거나 야간 알림을 끄면서 내 아이 제보까지 끊기는
    // 줄 알면 안 된다. 서버는 그 알림에 이 설정을 보지 않는다.
    expect(find.textContaining('제보 알림과'), findsOneWidget);
    expect(find.textContaining('발견 소식은 항상 받아요'), findsOneWidget);
  });
}
