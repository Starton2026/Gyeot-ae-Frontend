import 'package:dio/dio.dart';

import '../storage/device_id.dart';

/// 모든 요청에 `X-Device-Hash`를 붙인다.
///
/// 로그인한 사람은 토큰으로 구분되지만, 제보는 로그인 없이 하는 것이 기본이다
/// (설계 결정 1번). 게스트를 구분할 것이 이 헤더뿐이라 한 곳에서 빠짐없이
/// 붙인다. 무엇에 쓰이는지는 [DeviceIdStorage] 주석 참고.
class DeviceInterceptor extends Interceptor {
  DeviceInterceptor(this._storage);

  final DeviceIdStorage _storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers['X-Device-Hash'] = await _storage.read();
    handler.next(options);
  }
}
