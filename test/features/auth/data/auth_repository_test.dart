import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/core/network/api_exception.dart';
import 'package:gyeotae/features/auth/data/auth_repository.dart';

import '../../../support/fake_http_adapter.dart';

({Dio dio, FakeHttpAdapter adapter}) _dio({
  int statusCode = 200,
  Object body = const <String, dynamic>{},
}) {
  final adapter = FakeHttpAdapter(
    statusCode: statusCode,
    body: jsonEncode(body),
  );
  final dio = Dio(BaseOptions(baseUrl: 'http://test'))
    ..httpClientAdapter = adapter;

  return (dio: dio, adapter: adapter);
}

void main() {
  group('카카오 로그인', () {
    test('access_token을 넘기고 세션을 받는다', () async {
      final env = _dio(
        body: {
          'token': 'server-token',
          'user': {
            'id': 'u_1',
            'kakao_id': '12345',
            'name': '김보호',
            'profile_image_url': 'https://k.kakaocdn.net/p.jpg',
          },
          'claimed_reports': 2,
        },
      );

      final session = await HttpAuthRepository(
        env.dio,
      ).loginWithKakao('kakao-access-token');

      final request = env.adapter.lastRequest!;
      expect(request.path, '/auth/kakao');
      expect(request.method, 'POST');
      expect((request.data as Map)['access_token'], 'kakao-access-token');

      expect(session.token, 'server-token');
      expect(session.user.id, 'u_1');
      expect(session.user.name, '김보호');
      expect(session.user.profileImageUrl, 'https://k.kakaocdn.net/p.jpg');
      // 로그인 전에 게스트로 보낸 제보가 계정으로 옮겨간 수(F-4.2.7).
      expect(session.claimedReports, 2);
    });

    test('프로필 사진이 없어도 읽는다', () async {
      final env = _dio(
        body: {
          'token': 'server-token',
          'user': {'id': 'u_1', 'name': '김보호', 'profile_image_url': null},
        },
      );

      final session = await HttpAuthRepository(env.dio).loginWithKakao('t');

      // 카카오에서 받는 것은 닉네임과 프로필 이미지뿐이고, 이미지는 없을 수
      // 있다(F-6.3).
      expect(session.user.profileImageUrl, isNull);
      expect(session.claimedReports, 0);
    });

    test('토큰 검증에 실패하면 UNAUTHORIZED로 던진다', () async {
      final env = _dio(
        statusCode: 401,
        body: {
          'error': {
            'code': 'UNAUTHORIZED',
            'message': '카카오 토큰 검증에 실패했습니다.',
          },
        },
      );

      await expectLater(
        HttpAuthRepository(env.dio).loginWithKakao('bad-token'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', ApiErrorCode.unauthorized)
              .having((e) => e.isUnauthorized, '401 여부', isTrue),
        ),
      );
    });
  });

  group('내 정보', () {
    test('토큰이 살아 있으면 사용자를 돌려준다', () async {
      final env = _dio(
        body: {
          'user': {'id': 'u_1', 'name': '김보호'},
          'cases': 1,
          'reports': 3,
        },
      );

      final profile = await HttpAuthRepository(env.dio).me();

      expect(env.adapter.lastRequest!.path, '/auth/me');
      expect(profile?.user.name, '김보호');
      // MY 화면의 프로필 줄이 이 두 숫자를 쓴다(S8).
      expect(profile?.caseCount, 1);
      expect(profile?.reportCount, 3);
    });

    test('토큰이 죽었으면 오류가 아니라 null이다', () async {
      final env = _dio(
        statusCode: 401,
        body: {
          'error': {'code': 'UNAUTHORIZED', 'message': '토큰이 없거나 만료되었습니다.'},
        },
      );

      // 로그인은 선택이라 로그아웃 상태가 정상이다. 여기서 던지면 앱을 켤
      // 때마다 오류 화면이 뜬다.
      expect(await HttpAuthRepository(env.dio).me(), isNull);
    });
  });
}
