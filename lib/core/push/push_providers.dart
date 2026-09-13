import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../location/current_location.dart';
import '../network/api_exception.dart';
import '../network/dio_provider.dart';
import 'device_registrar.dart';
import 'push_messaging.dart';

/// FCM 창구. 테스트는 override로 갈아끼운다.
///
/// Firebase가 초기화되지 않았으면 아무것도 하지 않는 구현을 준다. 테스트와
/// 설정 파일이 없는 빌드가 여기로 온다.
final pushMessagingProvider = Provider<PushMessaging>((ref) {
  return firebaseReady
      ? const FirebasePushMessaging()
      : const SilentPushMessaging();
});

final deviceRegistrarProvider = Provider<DeviceRegistrar>((ref) {
  return HttpDeviceRegistrar(ref.watch(dioProvider));
});

/// 알림 반경. 기능정의서 F-8.6은 1/3/5/10km를 주기로 되어 있다.
///
/// TODO(F-8.6): MY의 알림 설정이 생기면 저장된 값을 읽어 이 자리를 채운다.
final pushRadiusKmProvider = Provider<double>((ref) => 5);

/// 앱이 서면 푸시 토큰을 서버에 올린다.
///
/// **위치가 잡히면 다시 올린다.** 처음에는 좌표를 모르는 채로 올라가고(그래도
/// 내 제보 결과 알림은 받는다), 기기 위치가 들어오면 좌표를 실어 다시 올려
/// 그때부터 반경 알림이 온다.
///
/// 실패해도 조용히 넘어간다. 알림을 못 받는 것보다 알림 등록 실패로 앱이
/// 멈추는 쪽이 나쁘다.
final pushRegistrationProvider = FutureProvider<bool>((ref) async {
  final messaging = ref.watch(pushMessagingProvider);

  final allowed = await messaging.requestPermission();
  if (!allowed) return false;

  final token = await messaging.token();
  if (token == null || token.isEmpty) return false;

  // 토큰이 새로 발급되면 다시 올린다. 안 올리면 그 기기는 조용해진다.
  final refreshes = messaging.tokenRefreshes().listen((_) {
    ref.invalidateSelf();
  });
  ref.onDispose(refreshes.cancel);

  final location = ref.watch(currentLocationProvider);
  final registrar = ref.watch(deviceRegistrarProvider);
  final radiusKm = ref.watch(pushRadiusKmProvider);

  try {
    await registrar.register(
      pushToken: token,
      // 기본 좌표는 보내지 않는다. 진짜로 받은 좌표만 반경의 기준이 된다.
      lat: location.resolved ? location.lat : null,
      lng: location.resolved ? location.lng : null,
      radiusKm: radiusKm,
    );

    return true;
  } on ApiException catch (error) {
    debugPrint('푸시 토큰 등록 실패: ${error.message}');

    return false;
  }
});
