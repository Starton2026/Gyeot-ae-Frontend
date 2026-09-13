import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/core/network/api_exception.dart';
import 'package:gyeotae/core/push/device_registrar.dart';

import '../../support/fake_http_adapter.dart';

({Dio dio, FakeHttpAdapter adapter}) _dio({
  int statusCode = 200,
  Object body = const {'ok': true},
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
  test('토큰과 반경을 POST /devices로 올린다', () async {
    final env = _dio();

    await HttpDeviceRegistrar(
      env.dio,
    ).register(pushToken: 'fcm-abc', lat: 37.4716, lng: 126.7538, radiusKm: 3);

    final request = env.adapter.lastRequest!;
    expect(request.path, '/devices');
    expect(request.method, 'POST');
    expect(request.data, {
      'push_token': 'fcm-abc',
      'radius_km': 3,
      'lat': 37.4716,
      'lng': 126.7538,
    });
  });

  test('위치를 모르면 좌표를 아예 빼고 올린다', () async {
    final env = _dio();

    await HttpDeviceRegistrar(env.dio).register(pushToken: 'fcm-abc');

    // null을 실어 보내면 서버가 "위치를 모르는 기기"와 "좌표가 null인 기기"를
    // 구분할 필요가 생긴다. 키 자체를 빼는 편이 단순하다.
    expect(env.adapter.lastRequest!.data, {
      'push_token': 'fcm-abc',
      'radius_km': 5,
    });
  });

  test('서버가 거부하면 ApiException으로 바꿔 던진다', () async {
    final env = _dio(
      statusCode: 400,
      body: {
        'error': {'code': 'VALIDATION_ERROR', 'message': 'push_token이 필요합니다.'},
      },
    );

    await expectLater(
      HttpDeviceRegistrar(env.dio).register(pushToken: ''),
      throwsA(isA<ApiException>()),
    );
  });
}
