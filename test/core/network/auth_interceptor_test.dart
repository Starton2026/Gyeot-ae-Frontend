import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/core/network/auth_interceptor.dart';

import '../../support/fake_http_adapter.dart';
import '../../support/in_memory_token_storage.dart';

void main() {
  test('토큰이 저장돼 있으면 Authorization 헤더를 붙인다', () async {
    final adapter = FakeHttpAdapter();
    final dio = Dio()
      ..httpClientAdapter = adapter
      ..interceptors.add(AuthInterceptor(InMemoryTokenStorage('token-abc')));

    await dio.get('http://localhost/me');

    expect(adapter.lastRequest!.headers['Authorization'], 'Bearer token-abc');
  });

  test('토큰이 없으면 Authorization 헤더를 붙이지 않는다', () async {
    final adapter = FakeHttpAdapter();
    final dio = Dio()
      ..httpClientAdapter = adapter
      ..interceptors.add(AuthInterceptor(InMemoryTokenStorage()));

    await dio.get('http://localhost/me');

    expect(adapter.lastRequest!.headers.containsKey('Authorization'), isFalse);
  });

  test('401 응답을 받으면 저장된 토큰을 지운다', () async {
    final storage = InMemoryTokenStorage('stale-token');
    final dio = Dio()
      ..httpClientAdapter = FakeHttpAdapter(statusCode: 401)
      ..interceptors.add(AuthInterceptor(storage));

    await expectLater(
      dio.get('http://localhost/me'),
      throwsA(isA<DioException>()),
    );

    expect(await storage.read(), isNull);
  });

  test('401이 아닌 오류에서는 토큰을 유지한다', () async {
    final storage = InMemoryTokenStorage('good-token');
    final dio = Dio()
      ..httpClientAdapter = FakeHttpAdapter(statusCode: 500)
      ..interceptors.add(AuthInterceptor(storage));

    await expectLater(
      dio.get('http://localhost/me'),
      throwsA(isA<DioException>()),
    );

    expect(await storage.read(), 'good-token');
  });
}
