import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/core/network/auth_interceptor.dart';
import 'package:gyeotae/core/network/device_interceptor.dart';
import 'package:gyeotae/features/missing/data/address_lookup.dart';

import '../../../support/fake_http_adapter.dart';

({Dio dio, FakeHttpAdapter adapter}) _dio({
  int statusCode = 200,
  Object body = const <String, dynamic>{},
}) {
  final adapter = FakeHttpAdapter(
    statusCode: statusCode,
    body: jsonEncode(body),
  );
  final dio = Dio()..httpClientAdapter = adapter;

  return (dio: dio, adapter: adapter);
}

/// 카카오 로컬 `coord2address` 응답 한 건.
Map<String, dynamic> _document({String? road, String? jibun}) => {
  'road_address': road == null ? null : {'address_name': road},
  'address': jibun == null ? null : {'address_name': jibun},
};

void main() {
  test('좌표를 카카오 로컬 API에 물어 도로명 주소를 받는다', () async {
    final env = _dio(
      body: {
        'documents': [
          _document(road: '인천 남동구 인하로 501', jibun: '인천 남동구 구월동 1138'),
        ],
      },
    );

    final address = await KakaoAddressLookup(
      env.dio,
      restApiKey: 'rest-key',
    ).addressAt(lat: 37.4491, lng: 126.7312);

    expect(address, '인천 남동구 인하로 501');

    final request = env.adapter.lastRequest!;
    expect(request.uri.host, 'dapi.kakao.com');
    expect(request.uri.path, '/v2/local/geo/coord2address.json');
    // 카카오는 x가 경도, y가 위도다. 뒤집으면 바다 한가운데가 나온다.
    expect(request.uri.queryParameters['x'], '126.7312');
    expect(request.uri.queryParameters['y'], '37.4491');
    expect(request.headers['Authorization'], 'KakaoAK rest-key');
  });

  test('도로명이 없는 자리면 지번 주소를 쓴다', () async {
    final env = _dio(
      body: {
        'documents': [_document(jibun: '인천 남동구 구월동 1138')],
      },
    );

    final address = await KakaoAddressLookup(
      env.dio,
      restApiKey: 'rest-key',
    ).addressAt(lat: 37.4491, lng: 126.7312);

    expect(address, '인천 남동구 구월동 1138');
  });

  test('주소가 없는 좌표면 null이다', () async {
    final env = _dio(body: {'documents': <Object>[]});

    final address = await KakaoAddressLookup(
      env.dio,
      restApiKey: 'rest-key',
    ).addressAt(lat: 0, lng: 0);

    expect(address, isNull);
  });

  test('실패해도 던지지 않고 null이다', () async {
    // 주소는 없어도 등록은 된다. 조회가 실패하면 보호자가 직접 적는다.
    final env = _dio(statusCode: 401, body: {'msg': 'wrong appKey'});

    final address = await KakaoAddressLookup(
      env.dio,
      restApiKey: 'rest-key',
    ).addressAt(lat: 37.4491, lng: 126.7312);

    expect(address, isNull);
  });

  test('키가 비어 있으면 부르지도 않는다', () async {
    final env = _dio();

    final address = await KakaoAddressLookup(
      env.dio,
      restApiKey: '',
    ).addressAt(lat: 37.4491, lng: 126.7312);

    expect(address, isNull);
    expect(env.adapter.lastRequest, isNull);
  });

  test('카카오로 가는 요청에는 우리 서버 토큰과 기기 해시를 싣지 않는다', () {
    final container = ProviderContainer.test();

    // 앱 dio를 같이 쓰면 AuthInterceptor가 곁애 로그인 토큰을 카카오에 보낸다.
    final interceptors = container.read(kakaoLocalDioProvider).interceptors;

    expect(interceptors.whereType<AuthInterceptor>(), isEmpty);
    expect(interceptors.whereType<DeviceInterceptor>(), isEmpty);
  });
}
