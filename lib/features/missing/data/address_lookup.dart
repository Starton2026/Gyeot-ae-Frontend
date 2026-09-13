import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/network/json.dart';

/// 좌표를 사람이 읽는 주소로 바꾼다(역지오코딩).
///
/// 실종자 등록(S7)의 마지막 목격 위치에 주소를 채운다(F-7.7). 지도에서 핀을
/// 옮기면 그 자리의 주소가 바로 보여야, 보호자가 핀이 맞는 곳에 꽂혔는지 안다.
abstract interface class AddressLookup {
  /// 그 좌표의 주소. **모르면 null이다.** 던지지 않는다.
  ///
  /// 주소가 없어도 좌표만으로 등록은 된다. 키가 없거나 조회가 실패하면
  /// 화면은 보호자에게 직접 적게 한다.
  Future<String?> addressAt({required double lat, required double lng});
}

/// 카카오 로컬 API `coord2address`를 부른다.
///
/// 지도 SDK의 네이티브 앱 키가 아니라 **REST API 키**를 쓴다.
class KakaoAddressLookup implements AddressLookup {
  KakaoAddressLookup(this._dio, {required String restApiKey})
    : _restApiKey = restApiKey;

  final Dio _dio;
  final String _restApiKey;

  static const String _url =
      'https://dapi.kakao.com/v2/local/geo/coord2address.json';

  @override
  Future<String?> addressAt({required double lat, required double lng}) async {
    if (_restApiKey.isEmpty) return null;

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _url,
        // 카카오는 x가 경도, y가 위도다.
        queryParameters: {'x': '$lng', 'y': '$lat'},
        options: Options(headers: {'Authorization': 'KakaoAK $_restApiKey'}),
      );

      final first = jsonMapList(response.data?['documents']).firstOrNull;
      if (first == null) return null;

      // 도로명이 사람들이 길을 찾는 말이다. 산길·공터처럼 도로명이 없는
      // 자리면 지번으로 대신한다.
      final road = jsonMapOrNull(first['road_address'])?['address_name'];
      final jibun = jsonMapOrNull(first['address'])?['address_name'];

      return jsonStringOrNull(road) ?? jsonStringOrNull(jibun);
    } on DioException catch (error) {
      debugPrint(
        '[주소] 카카오 로컬 조회 실패: ${error.response?.statusCode} ${error.message}',
      );
      return null;
    }
  }
}

/// 카카오 로컬 API 전용 dio.
///
/// **앱의 [dioProvider]를 쓰지 않는다.** 그쪽에는 곁애 로그인 토큰과 기기
/// 해시를 붙이는 인터셉터가 걸려 있어, 같이 쓰면 그 값이 카카오로 나간다.
final kakaoLocalDioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );
});

final addressLookupProvider = Provider<AddressLookup>((ref) {
  return KakaoAddressLookup(
    ref.watch(kakaoLocalDioProvider),
    restApiKey: Env.kakaoRestApiKey,
  );
});
