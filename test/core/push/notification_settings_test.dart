import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/core/push/notification_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/in_memory_notification_settings_storage.dart';

ProviderContainer _container(InMemoryNotificationSettingsStorage storage) {
  return ProviderContainer.test(
    overrides: [notificationSettingsStorageProvider.overrideWithValue(storage)],
  );
}

void main() {
  group('서버로 보내는 값', () {
    test('기본값은 반경 5km, 아동·어르신 모두, 야간에도 받는다', () {
      const settings = NotificationSettings();

      expect(settings.radiusKm, 5);
      // 둘 다 받으면 구분을 보내지 않는다. 서버는 구분이 없는 기기에 '그 외'
      // 사건까지 전부 보낸다 — 둘 다 켰는데 '그 외'만 빠지면 이상하다.
      expect(settings.categories, isNull);
      expect(settings.quietHours, isNull);
    });

    test('하나만 켜면 그 구분만 보낸다', () {
      const settings = NotificationSettings(elderly: false);

      expect(settings.categories, ['child']);
    });

    test('야간 알림을 끄면 밤 11시부터 아침 7시까지를 방해 금지로 보낸다', () {
      const settings = NotificationSettings(nightAlerts: false);

      expect(settings.quietHours, (from: '23:00', to: '07:00'));
    });
  });

  group('바꾸기', () {
    test('처음에는 기본값이다', () async {
      final container = _container(InMemoryNotificationSettingsStorage());

      final settings = await container.read(
        notificationSettingsProvider.future,
      );

      expect(settings, const NotificationSettings());
    });

    test('저장해 둔 값으로 시작한다', () async {
      final container = _container(
        InMemoryNotificationSettingsStorage(
          const NotificationSettings(radiusKm: 10, nightAlerts: false),
        ),
      );

      final settings = await container.read(
        notificationSettingsProvider.future,
      );

      expect(settings.radiusKm, 10);
      expect(settings.nightAlerts, isFalse);
    });

    test('반경을 바꾸면 기기에 저장한다', () async {
      final storage = InMemoryNotificationSettingsStorage();
      final container = _container(storage);
      await container.read(notificationSettingsProvider.future);

      await container.read(notificationSettingsProvider.notifier).setRadius(1);

      expect(container.read(notificationSettingsProvider).value?.radiusKm, 1);
      expect(storage.saved?.radiusKm, 1);
    });

    test('대상과 야간 알림도 저장한다', () async {
      final storage = InMemoryNotificationSettingsStorage();
      final container = _container(storage);
      await container.read(notificationSettingsProvider.future);
      final notifier = container.read(notificationSettingsProvider.notifier);

      await notifier.setTarget(AlertTarget.child, on: false);
      await notifier.setNightAlerts(on: false);

      expect(
        storage.saved,
        const NotificationSettings(child: false, nightAlerts: false),
      );
    });

    test('마지막 하나 남은 대상은 끌 수 없다', () async {
      final storage = InMemoryNotificationSettingsStorage();
      final container = _container(storage);
      await container.read(notificationSettingsProvider.future);
      final notifier = container.read(notificationSettingsProvider.notifier);

      await notifier.setTarget(AlertTarget.child, on: false);
      await notifier.setTarget(AlertTarget.elderly, on: false);

      // 둘 다 끄면 서버에 보낼 구분이 빈 목록이 되는데, 서버는 빈 목록을
      // "전부 받음"으로 읽는다. 끄려던 사람에게 오히려 전부 가게 된다.
      final settings = container.read(notificationSettingsProvider).value!;
      expect(settings.child, isFalse);
      expect(settings.elderly, isTrue);
    });

    test('선택지에 없는 반경은 받지 않는다', () async {
      final container = _container(InMemoryNotificationSettingsStorage());
      await container.read(notificationSettingsProvider.future);

      await container.read(notificationSettingsProvider.notifier).setRadius(7);

      expect(container.read(notificationSettingsProvider).value?.radiusKm, 5);
    });
  });

  group('기기 저장소', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('저장한 값을 그대로 읽는다', () async {
      const storage = PrefsNotificationSettingsStorage();
      const settings = NotificationSettings(
        radiusKm: 3,
        elderly: false,
        nightAlerts: false,
      );

      await storage.save(settings);

      expect(await storage.load(), settings);
    });

    test('저장한 적이 없으면 기본값이다', () async {
      expect(
        await const PrefsNotificationSettingsStorage().load(),
        const NotificationSettings(),
      );
    });

    test('망가진 반경이 들어 있으면 기본 반경으로 읽는다', () async {
      SharedPreferences.setMockInitialValues({'notify_radius_km': 7});

      final settings = await const PrefsNotificationSettingsStorage().load();

      expect(settings.radiusKm, 5);
    });
  });
}
