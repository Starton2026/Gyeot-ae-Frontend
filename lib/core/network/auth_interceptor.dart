import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// 요청에 액세스 토큰을 붙이고, 토큰이 만료되면(401) 정리한다.
///
/// 로그인은 선택 사항이라 토큰이 없어도 요청은 그대로 나간다.
/// 401을 받아도 로그인 화면으로 강제 이동시키지 않고 토큰만 지운다.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);

  final TokenStorage _storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      await _storage.clear();
    }
    handler.next(err);
  }
}
