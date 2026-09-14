import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_providers.dart';
import '../location/current_location.dart';
import '../network/api_exception.dart';
import '../network/dio_provider.dart';
import 'device_registrar.dart';
import 'notification_settings.dart';
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

/// 앱이 서면 푸시 토큰을 서버에 올린다.
///
/// **위치가 잡히면 다시 올린다.** 처음에는 좌표를 모르는 채로 올라가고(그래도
/// 내 제보 결과 알림은 받는다), 기기 위치가 들어오면 좌표를 실어 다시 올려
/// 그때부터 반경 알림이 온다.
///
/// **로그인하거나 로그아웃하면 다시 올린다.** 서버는 등록 요청에 실린 로그인
/// 토큰으로 이 기기가 누구 것인지 적어 두고, 보호자 알림은 그 값으로 기기를
/// 찾는다. 앱을 켠 뒤에 로그인하면 그 사실이 서버에 닿지 않아, 방금 등록한
/// 보호자가 제보 알림을 못 받는다. 로그아웃하고 안 올리면 반대로 그 폰에
/// 남의 계정 알림이 계속 간다.
///
/// **알림 설정(F-8.6)을 바꾸면 다시 올린다.** 안 올리면 서버는 옛 반경으로
/// 계속 보내고, 줄였는데 알림이 그대로 오면 설정이 고장 난 줄 안다.
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

  // 누구인지 확인이 끝난 뒤에 올린다. 확인 전에 한 번 올리고 확인 뒤에 또
  // 올리면 켤 때마다 요청이 두 번 나간다.
  await _authSettled(ref);
  if (!ref.mounted) return false;

  // 그 뒤로 로그인한 사람이 바뀌면 다시 올린다. watch로 걸면 확인이 실패하는
  // 순간에도 다시 돌아, 기다리던 이전 실행이 버려진 채로 남는다.
  ref.listen(
    authProvider.select((auth) => auth.value?.id),
    (previous, next) => ref.invalidateSelf(),
  );

  // 설정은 기기에서 읽어 오류가 나지 않는다(못 읽으면 기본값). 같은 이유로
  // 읽은 뒤에 listen으로 걸어, 바뀔 때만 다시 돈다.
  final settings = await ref.read(notificationSettingsProvider.future);
  if (!ref.mounted) return false;
  ref.listen(
    notificationSettingsProvider.select((async) => async.value),
    (previous, next) => ref.invalidateSelf(),
  );

  final location = ref.watch(currentLocationProvider);
  final registrar = ref.watch(deviceRegistrarProvider);

  try {
    await registrar.register(
      pushToken: token,
      // 기본 좌표는 보내지 않는다. 진짜로 받은 좌표만 반경의 기준이 된다.
      lat: location.resolved ? location.lat : null,
      lng: location.resolved ? location.lng : null,
      radiusKm: settings.radiusKm.toDouble(),
      categories: settings.categories,
      quietHours: settings.quietHours,
    );

    return true;
  } on ApiException catch (error) {
    debugPrint('푸시 토큰 등록 실패: ${error.message}');

    return false;
  }
});

/// 로그인 확인이 한 번 끝날 때까지 기다린다.
///
/// **실패도 끝난 것으로 본다.** Riverpod은 실패한 provider를 40초 넘게 다시
/// 시도하는데, `authProvider.future`는 그동안 끝나지 않는다. 서버가 잠깐 안
/// 받는다고 알림 등록까지 그만큼 미루면 안 된다. 토큰이 남아 있으면
/// 인터셉터가 어차피 싣고, 재시도가 성공하면 사람이 바뀐 것으로 보고 다시
/// 올린다.
Future<void> _authSettled(Ref ref) {
  bool settled(AsyncValue<Object?> auth) => auth.hasValue || auth.hasError;

  if (settled(ref.read(authProvider))) return Future.value();

  final done = Completer<void>();
  void finish() {
    if (!done.isCompleted) done.complete();
  }

  final subscription = ref.listen(authProvider, (previous, next) {
    if (settled(next)) finish();
  });
  // 기다리는 사이 다시 돌면 이 실행은 버려진다. 매달린 채로 두지 않는다.
  ref.onDispose(finish);

  return done.future.whenComplete(subscription.close);
}
