import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/core/location/current_location.dart';
import 'package:gyeotae/core/location/location_source.dart';
import 'package:gyeotae/core/mock/mock_backend.dart';

import '../../support/fake_location_source.dart';

ProviderContainer _container(FakeLocationSource source) {
  return ProviderContainer.test(
    overrides: [locationSourceProvider.overrideWithValue(source)],
  );
}

void main() {
  group('위치를 못 받았을 때', () {
    test('기본값으로 시작해서 화면이 곧바로 그려진다', () {
      final container = _container(FakeLocationSource());

      // 동기로 읽힌다. 로딩 상태가 없다.
      expect(container.read(currentLocationProvider).label, '인천 남동구');
    });

    test('권한을 거부해도 기본값으로 남는다', () async {
      final source = FakeLocationSource();
      final container = _container(source);

      await container.read(currentLocationProvider.notifier).locate();

      final location = container.read(currentLocationProvider);
      expect(location.lat, CurrentLocationNotifier.fallback.lat);
      expect(location.lng, CurrentLocationNotifier.fallback.lng);
      expect(source.calls, contains('current'), reason: '물어는 본다');
    });
  });

  group('위치를 받았을 때', () {
    test('마지막 위치를 먼저 쓰고, 정확한 위치가 오면 갈아낀다', () async {
      final source = FakeLocationSource(
        known: (lat: 37.5, lng: 126.9),
        now: (lat: 37.51, lng: 126.91),
      );
      final container = _container(source);
      final seen = <double>[];

      container.listen(
        currentLocationProvider,
        (previous, next) => seen.add(next.lat),
        fireImmediately: true,
      );

      await container.read(currentLocationProvider.notifier).locate();

      expect(
        seen,
        [CurrentLocationNotifier.fallback.lat, 37.5, 37.51],
        reason: '정확한 좌표를 기다리는 동안 시연용 좌표로 거리를 찍으면 안 된다',
      );
    });

    test('좌표는 알아도 지명은 모른다', () async {
      final container = _container(
        FakeLocationSource(now: (lat: 37.51, lng: 126.91)),
      );

      await container.read(currentLocationProvider.notifier).locate();

      final location = container.read(currentLocationProvider);
      expect(location.areaName, isNull, reason: '역지오코딩을 아직 안 붙였다');
      expect(location.label, '현재 위치');
    });

    test('마지막 위치가 없으면 정확한 위치만 쓴다', () async {
      final container = _container(
        FakeLocationSource(now: (lat: 37.51, lng: 126.91)),
      );

      await container.read(currentLocationProvider.notifier).locate();

      expect(container.read(currentLocationProvider).lat, 37.51);
    });
  });

  test('시연용 기본값은 시연 사건의 실종 지점과 겹치지 않는다', () {
    const me = CurrentLocationNotifier.fallback;
    final demoCase = MockBackend.seeded().findCase(MockBackend.demoCaseId)!;

    final distanceKm = MockBackend.haversineKm(
      me.lat,
      me.lng,
      demoCase['last_lat'] as double,
      demoCase['last_lng'] as double,
    );

    expect(
      distanceKm,
      greaterThan(0.2),
      reason:
          '제보는 내 위치로 저장된다. 좌표가 실종 지점과 같으면 새 제보가 그 위에 얹혀서 '
          '이동 경로가 출발점으로 되돌아오는 닫힌 고리로 그려진다.',
    );
  });
}
