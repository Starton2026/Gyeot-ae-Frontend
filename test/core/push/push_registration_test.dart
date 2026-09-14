import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/core/location/current_location.dart';
import 'package:gyeotae/core/location/location_source.dart';
import 'package:gyeotae/core/network/api_exception.dart';
import 'package:gyeotae/core/network/dio_provider.dart';
import 'package:gyeotae/core/push/push_providers.dart';
import 'package:gyeotae/features/auth/data/auth_repository.dart';
import 'package:gyeotae/features/auth/data/auth_session.dart';
import 'package:gyeotae/features/auth/data/kakao_auth_source.dart';
import 'package:gyeotae/features/auth/presentation/auth_providers.dart';

import '../../support/fake_auth.dart';
import '../../support/fake_location_source.dart';
import '../../support/fake_push_messaging.dart';
import '../../support/in_memory_token_storage.dart';

const _profile = AuthProfile(
  user: AuthUser(id: 'u_1', name: '김보호'),
);

/// 올릴 때마다 그 순간 저장돼 있던 로그인 토큰을 적어 둔다.
///
/// 서버는 요청 헤더의 토큰으로 이 기기가 누구 것인지 정한다. 토큰은
/// AuthInterceptor가 저장소에서 읽어 싣으므로, 올리는 순간의 저장소 값이
/// 곧 서버가 보는 값이다.
class _TokenAwareRegistrar extends FakeDeviceRegistrar {
  _TokenAwareRegistrar(this._tokens);

  final InMemoryTokenStorage _tokens;

  final List<String?> signedInAs = [];

  @override
  Future<void> register({
    required String pushToken,
    double? lat,
    double? lng,
    double radiusKm = 5,
  }) async {
    signedInAs.add(await _tokens.read());

    return super.register(
      pushToken: pushToken,
      lat: lat,
      lng: lng,
      radiusKm: radiusKm,
    );
  }
}

/// `GET /auth/me`가 실패한다. 서버가 죽었거나 네트워크가 끊겼다.
class _FailingAuthRepository extends FakeAuthRepository {
  @override
  Future<AuthProfile?> me() async =>
      throw const ApiException('서버 오류', statusCode: 500);
}

ProviderContainer _container({
  required FakePushMessaging messaging,
  required FakeDeviceRegistrar registrar,
  LocationFix? location,
  InMemoryTokenStorage? tokens,
  AuthRepository? auth,
}) {
  final container = ProviderContainer.test(
    overrides: [
      pushMessagingProvider.overrideWithValue(messaging),
      deviceRegistrarProvider.overrideWithValue(registrar),
      locationSourceProvider.overrideWithValue(
        FakeLocationSource(known: location, now: location),
      ),
      tokenStorageProvider.overrideWithValue(tokens ?? InMemoryTokenStorage()),
      authRepositoryProvider.overrideWithValue(auth ?? FakeAuthRepository()),
      kakaoAuthSourceProvider.overrideWithValue(FakeKakaoAuthSource()),
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

  group('로그인 상태가 바뀌면', () {
    test('로그인하면 계정이 실리도록 다시 올린다', () async {
      final messaging = FakePushMessaging();
      final tokens = InMemoryTokenStorage();
      final registrar = _TokenAwareRegistrar(tokens);
      final container = _container(
        messaging: messaging,
        registrar: registrar,
        tokens: tokens,
      );

      await container.read(pushRegistrationProvider.future);
      expect(registrar.signedInAs, [null]);

      await container.read(authProvider.notifier).signInWithKakao();
      await container.pump();
      await container.read(pushRegistrationProvider.future);

      // 서버는 보호자의 기기를 이 등록에 실린 계정으로 찾는다. 다시 안 올리면
      // 앱을 켠 뒤 로그인해서 등록한 보호자가 제보 알림을 못 받는다.
      expect(registrar.signedInAs, [null, 'server-token']);
    });

    test('로그아웃하면 계정을 떼도록 다시 올린다', () async {
      final messaging = FakePushMessaging();
      final tokens = InMemoryTokenStorage('token');
      final registrar = _TokenAwareRegistrar(tokens);
      final container = _container(
        messaging: messaging,
        registrar: registrar,
        tokens: tokens,
        auth: FakeAuthRepository(user: _profile),
      );

      await container.read(pushRegistrationProvider.future);
      expect(registrar.signedInAs, ['token']);

      await container.read(authProvider.notifier).signOut();
      await container.pump();
      await container.read(pushRegistrationProvider.future);

      // 떼지 않으면 로그아웃한 폰으로 계속 그 계정의 보호자 알림이 간다.
      expect(registrar.signedInAs, ['token', null]);
    });

    test('로그인한 채로 켜면 누구인지 확인한 뒤 한 번만 올린다', () async {
      final messaging = FakePushMessaging();
      final tokens = InMemoryTokenStorage('token');
      final registrar = _TokenAwareRegistrar(tokens);
      final container = _container(
        messaging: messaging,
        registrar: registrar,
        tokens: tokens,
        auth: FakeAuthRepository(user: _profile),
      );

      await container.read(pushRegistrationProvider.future);
      await container.pump();
      await container.read(pushRegistrationProvider.future);

      // 확인 전에 한 번, 확인 뒤에 또 한 번 올리면 켤 때마다 요청이 두 번 나간다.
      expect(registrar.signedInAs, ['token']);
    });

    test('누구인지 확인하지 못해도 등록은 한다', () async {
      final messaging = FakePushMessaging();
      final registrar = FakeDeviceRegistrar();
      final container = _container(
        messaging: messaging,
        registrar: registrar,
        tokens: InMemoryTokenStorage('token'),
        auth: _FailingAuthRepository(),
      );

      // 서버가 잠깐 안 받는다고 알림 등록까지 포기하면 안 된다.
      expect(await container.read(pushRegistrationProvider.future), isTrue);
      expect(registrar.calls, hasLength(1));
    });
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
