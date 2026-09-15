import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import '../storage/device_id.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';
import 'device_interceptor.dart';

/// 토큰 저장소. 테스트에서는 override로 갈아끼운다.
final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => PrefsTokenStorage(),
);

/// 기기 식별자 저장소. 게스트 제보를 구분하는 값이다.
final deviceIdStorageProvider = Provider<DeviceIdStorage>(
  (ref) => PrefsDeviceIdStorage(),
);

/// 요청/응답 로그를 찍을지 여부. 테스트에서는 false로 override한다.
final apiLogEnabledProvider = Provider<bool>((ref) => Env.enableApiLog);

/// 백엔드와 통신하는 dio 인스턴스.
///
/// 각 feature의 API 클래스는 이 provider를 읽어서 쓴다.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 30),
      // AI 응답은 오래 걸릴 수 있어 넉넉하게 잡는다.
      receiveTimeout: const Duration(seconds: 60),
      contentType: Headers.jsonContentType,
    ),
  );

  dio.interceptors.add(AuthInterceptor(ref.read(tokenStorageProvider)));
  dio.interceptors.add(DeviceInterceptor(ref.read(deviceIdStorageProvider)));

  if (ref.read(apiLogEnabledProvider)) {
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }

  return dio;
});
