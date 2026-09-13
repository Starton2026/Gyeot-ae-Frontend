import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/core/location/current_location.dart';
import 'package:gyeotae/core/location/location_source.dart';
import 'package:gyeotae/core/network/api_exception.dart';
import 'package:gyeotae/core/push/push_providers.dart';

import '../../support/fake_location_source.dart';
import '../../support/fake_push_messaging.dart';

ProviderContainer _container({
  required FakePushMessaging messaging,
  required FakeDeviceRegistrar registrar,
  LocationFix? location,
}) {
  final container = ProviderContainer.test(
    overrides: [
      pushMessagingProvider.overrideWithValue(messaging),
      deviceRegistrarProvider.overrideWithValue(registrar),
      locationSourceProvider.overrideWithValue(
        FakeLocationSource(known: location, now: location),
      ),
    ],
  );
  addTearDown(messaging.dispose);

  return container;
}

void main() {
  test('권한을 받으면 토큰을 서버에 올린다', () async {
    final messaging = FakePushMessaging(fcmToken: 'fcm-abc');
    final registrar = FakeDeviceRegistrar();
    final container = _container(
      messaging: messaging,
      registrar: registrar,
      location: (lat: 37.4716, lng: 126.7538),
    );

    // 기기 위치는 비동기로 들어온다. 좌표가 확정된 뒤에 읽어야 등록에 실리는
    // 값이 기본 좌표가 아니라 진짜 좌표다.
    container.read(currentLocationProvider);
    await container.pump();
    expect(container.read(currentLocationProvider).resolved, isTrue);

    final registered = await container.read(pushRegistrationProvider.future);

    expect(registered, isTrue);
    expect(messaging.permissionAsks, 1);
    expect(registrar.calls.single.token, 'fcm-abc');
    expect(registrar.calls.single.lat, 37.4716);
    expect(registrar.calls.single.lng, 126.7538);
    expect(registrar.calls.single.radiusKm, 5);
  });

  test('알림 권한을 거부하면 아무것도 올리지 않는다', () async {
    final messaging = FakePushMessaging(allowed: false);
    final registrar = FakeDeviceRegistrar();
    final container = _container(messaging: messaging, registrar: registrar);

    expect(await container.read(pushRegistrationProvider.future), isFalse);
    expect(registrar.calls, isEmpty);
  });

  test('토큰을 못 받으면 올리지 않는다', () async {
    final messaging = FakePushMessaging(fcmToken: null);
    final registrar = FakeDeviceRegistrar();
    final container = _container(messaging: messaging, registrar: registrar);

    expect(await container.read(pushRegistrationProvider.future), isFalse);
    expect(registrar.calls, isEmpty);
  });

  test('위치를 모르면 좌표 없이 올린다', () async {
    final messaging = FakePushMessaging();
    final registrar = FakeDeviceRegistrar();
    final container = _container(messaging: messaging, registrar: registrar);

    expect(await container.read(pushRegistrationProvider.future), isTrue);
    // 반경 알림은 못 받아도 내 제보 결과 알림은 받아야 한다.
    expect(registrar.calls.single.lat, isNull);
    expect(registrar.calls.single.lng, isNull);
  });

  test('토큰이 갱신되면 다시 올린다', () async {
    final messaging = FakePushMessaging(fcmToken: 'old');
    final registrar = FakeDeviceRegistrar();
    final container = _container(messaging: messaging, registrar: registrar);

    await container.read(pushRegistrationProvider.future);
    expect(registrar.calls.single.token, 'old');

    messaging.refresh('new');
    await container.pump();

    // 안 올리면 그 기기는 조용해진다.
    expect(await container.read(pushRegistrationProvider.future), isTrue);
    expect(registrar.calls.last.token, 'new');
  });

  test('등록에 실패해도 던지지 않는다', () async {
    final messaging = FakePushMessaging();
    final registrar = FakeDeviceRegistrar(
      error: const ApiException('서버 오류', statusCode: 500),
    );
    final container = _container(messaging: messaging, registrar: registrar);

    // 알림 등록이 실패했다고 앱이 멈추면 안 된다.
    expect(await container.read(pushRegistrationProvider.future), isFalse);
  });
}
