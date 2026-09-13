import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/core/config/env.dart';
import 'package:gyeotae/core/network/auth_interceptor.dart';
import 'package:gyeotae/core/network/device_interceptor.dart';
import 'package:gyeotae/core/network/dio_provider.dart';
import 'package:gyeotae/core/storage/device_id.dart';
import 'package:gyeotae/core/storage/token_storage.dart';

import '../../support/fake_http_adapter.dart';
import '../../support/in_memory_device_id.dart';
import '../../support/in_memory_token_storage.dart';

/// 테스트 출력이 지저분해지지 않게 API 로그는 끈다.
ProviderContainer _container({TokenStorage? tokenStorage, String? deviceId}) {
  return ProviderContainer.test(
    overrides: [
      apiLogEnabledProvider.overrideWithValue(false),
      // 진짜 구현은 SharedPreferences를 읽어서 바인딩 없는 테스트에서 터진다.
      deviceIdStorageProvider.overrideWithValue(
        InMemoryDeviceIdStorage(deviceId ?? 'test-device'),
      ),
      // 토큰 저장소도 같은 이유로 갈아끼운다.
      tokenStorageProvider.overrideWithValue(
        tokenStorage ?? InMemoryTokenStorage(),
      ),
    ],
  );
}

void main() {
  test('dio의 baseUrl은 환경설정의 API 주소를 쓴다', () {
    final container = _container();

    expect(container.read(dioProvider).options.baseUrl, Env.apiBaseUrl);
  });

  test('AI 응답을 기다릴 수 있도록 receiveTimeout이 60초 이상이다', () {
    final container = _container();

    final timeout = container.read(dioProvider).options.receiveTimeout;

    expect(timeout, isNotNull);
    expect(timeout!.inSeconds, greaterThanOrEqualTo(60));
  });

  test('dio에 AuthInterceptor가 붙어 있다', () {
    final container = _container();

    expect(
      container.read(dioProvider).interceptors.whereType<AuthInterceptor>(),
      isNotEmpty,
    );
  });

  test('저장소에 토큰이 있으면 dio 요청에 실려 나간다', () async {
    final container = _container(
      tokenStorage: InMemoryTokenStorage('token-from-storage'),
    );
    final adapter = FakeHttpAdapter();
    final dio = container.read(dioProvider)..httpClientAdapter = adapter;

    await dio.get('/me');

    expect(
      adapter.lastRequest!.headers['Authorization'],
      'Bearer token-from-storage',
    );
  });

  test('앱 런타임에서는 SharedPreferences 저장소를 쓴다', () {
    final container = ProviderContainer.test(
      overrides: [apiLogEnabledProvider.overrideWithValue(false)],
    );

    expect(container.read(tokenStorageProvider), isA<PrefsTokenStorage>());
    expect(container.read(deviceIdStorageProvider), isA<PrefsDeviceIdStorage>());
  });

  group('기기 식별자', () {
    test('dio에 DeviceInterceptor가 붙어 있다', () {
      final container = _container();

      expect(
        container.read(dioProvider).interceptors.whereType<DeviceInterceptor>(),
        isNotEmpty,
      );
    });

    test('모든 요청에 X-Device-Hash가 실려 나간다', () async {
      // 이게 빠지면 서버가 모든 게스트를 한 덩어리로 묶는다. 제보 횟수
      // 제한이 사람별이 아니라 전체 공용이 되어 네 번째부터 429다.
      final container = _container(deviceId: 'abc123');
      final adapter = FakeHttpAdapter();
      final dio = container.read(dioProvider)..httpClientAdapter = adapter;

      await dio.get('/missing');

      expect(adapter.lastRequest!.headers['X-Device-Hash'], 'abc123');
    });
  });
}
