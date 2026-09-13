import 'package:dio/dio.dart';

import '../network/api_exception.dart';

/// 푸시 토큰과 알림 설정을 서버에 올린다. API 명세서 4) `POST /devices`.
///
/// **로그인하지 않아도 부른다.** 알림을 받아야 할 사람 대부분이 지나가던
/// 시민이라(설계 결정 1번) 계정이 없다. 기기 식별은 `X-Device-Hash` 헤더가
/// 하고, 그 헤더는 `DeviceInterceptor`가 모든 요청에 이미 붙인다.
abstract interface class DeviceRegistrar {
  /// [lat]·[lng]를 주면 그 좌표를 중심으로 [radiusKm] 안의 사건만 알림이 온다.
  ///
  /// **위치를 모르면 안 준다.** 서버는 좌표 없는 기기를 반경 알림에서 빼는데,
  /// 그게 맞다 — 기본 좌표를 올리면 가 본 적도 없는 동네 알림을 받는다.
  /// 그래도 등록은 해 둔다. 내가 제보한 사건의 결과 알림은 위치와 상관없이
  /// 받아야 한다.
  Future<void> register({
    required String pushToken,
    double? lat,
    double? lng,
    double radiusKm,
  });
}

class HttpDeviceRegistrar implements DeviceRegistrar {
  const HttpDeviceRegistrar(this._dio);

  final Dio _dio;

  @override
  Future<void> register({
    required String pushToken,
    double? lat,
    double? lng,
    double radiusKm = 5,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/devices',
        data: {
          'push_token': pushToken,
          'radius_km': radiusKm,
          'lat': ?lat,
          'lng': ?lng,
        },
      );
    } on DioException catch (error) {
      throw ApiException.from(error);
    }
  }
}
