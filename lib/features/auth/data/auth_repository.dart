import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import 'auth_session.dart';

/// 인증 데이터 출처.
abstract interface class AuthRepository {
  /// 카카오 `access_token`으로 로그인. API 명세서 2) `POST /auth/kakao`.
  ///
  /// 가입과 로그인을 구분하지 않는다(F-6.2). 처음 보는 계정이면 서버가 그
  /// 자리에서 만든다.
  Future<AuthSession> loginWithKakao(String accessToken);

  /// 저장된 토큰으로 내 정보를 확인한다. API 명세서 3) `GET /auth/me`.
  ///
  /// 토큰이 없거나 만료됐으면 **null**이다. 오류로 던지지 않는다 — 로그인은
  /// 선택이라 로그아웃 상태가 정상이다.
  Future<AuthProfile?> me();
}

class HttpAuthRepository implements AuthRepository {
  const HttpAuthRepository(this._dio);

  final Dio _dio;

  @override
  Future<AuthSession> loginWithKakao(String accessToken) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/kakao',
        data: {'access_token': accessToken},
      );

      return AuthSession.fromJson(response.data ?? const <String, dynamic>{});
    } on DioException catch (error) {
      throw ApiException.from(error);
    }
  }

  @override
  Future<AuthProfile?> me() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/auth/me');
      final data = response.data;

      return data == null ? null : AuthProfile.fromJson(data);
    } on DioException catch (error) {
      // 401이면 토큰이 죽은 것이다. AuthInterceptor가 저장소에서 지운다.
      if (error.response?.statusCode == 401) return null;

      throw ApiException.from(error);
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return HttpAuthRepository(ref.watch(dioProvider));
});
