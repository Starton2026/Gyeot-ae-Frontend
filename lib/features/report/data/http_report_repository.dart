import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/json.dart';
import 'analysis.dart';
import 'report.dart';
import 'report_repository.dart';

/// 백엔드를 실제로 부르는 [ReportRepository].
class HttpReportRepository implements ReportRepository {
  const HttpReportRepository(this._dio);

  final Dio _dio;

  @override
  Future<AnalysisResult> analyze({
    required String missingId,
    required String photoPath,
  }) async {
    try {
      final form = FormData.fromMap({
        'missing_id': missingId,
        'photo': await MultipartFile.fromFile(photoPath),
      });

      final response = await _dio.post<Map<String, dynamic>>(
        '/reports/analyze',
        data: form,
      );

      // 얼굴을 못 찾아도 200이다. `face_found: false`로 내려온다(설계 결정 4번).
      return AnalysisResult.fromJson(
        response.data ?? const <String, dynamic>{},
      );
    } on DioException catch (error) {
      throw ApiException.from(error);
    }
  }

  @override
  Future<Report> submit({
    required String analysisId,
    required DateTime observedAt,
    double? lat,
    double? lng,
    String? placeName,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/reports',
        data: {
          'analysis_id': analysisId,
          // 좌표는 없을 수 있다. 지어내지 않고 비워서 보낸다. 서버도 좌표 없는
          // 제보를 받고, 대신 경로에서만 빼둔다.
          if (lat != null && lng != null) ...{'lat': lat, 'lng': lng},
          if (placeName != null && placeName.isNotEmpty)
            'place_name': placeName,
          'observed_at': isoWithOffset(observedAt),
        },
      );

      return _reportFrom(
        response.data ?? const <String, dynamic>{},
        lat: lat,
        lng: lng,
        placeName: placeName,
        observedAt: observedAt,
      );
    } on DioException catch (error) {
      // 분석 TTL(10분)이 지났으면 ANALYSIS_EXPIRED가 온다. 화면은 다시
      // 분석하라고 안내한다.
      throw ApiException.from(error);
    }
  }

  /// 확정 응답 + 방금 보낸 값으로 제보 하나를 만든다.
  ///
  /// **서버 응답이 보낸 값을 되돌려주지 않는다.** 확정 결과(id·유사도·등급·
  /// 경로 번호·사진)만 담겨 있어서, 그대로 읽으면 좌표가 비고 위치를 안 보낸
  /// 제보처럼 보인다. 완료 화면(S4-2)이 "위치 없이 보냈어요"라고 잘못 적는
  /// 자리라 여기서 채워 넣는다.
  ///
  /// `face_found`는 등급에서 나온다. 서버가 얼굴을 못 찾았을 때만 `no_face`를
  /// 주므로 둘은 같은 말이다.
  Report _reportFrom(
    Map<String, dynamic> data, {
    required DateTime observedAt,
    double? lat,
    double? lng,
    String? placeName,
  }) {
    return Report.fromJson({
      ...data,
      'lat': data['lat'] ?? lat,
      'lng': data['lng'] ?? lng,
      'place_name': data['place_name'] ?? placeName,
      'observed_at': data['observed_at'] ?? isoWithOffset(observedAt),
      'face_found': data['face_found'] ?? (data['grade'] != 'no_face'),
      // 서버는 제보를 항상 보이는 상태로 만든다. 숨김은 운영에서만 바뀐다.
      'status': data['status'] ?? 'visible',
      'confirmed': data['confirmed'] ?? false,
    });
  }

  @override
  Future<ReportBundle> fetchReports(
    String missingId, {
    double minSimilarity = 0,
    bool includeLow = true,
    DateTime? until,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/missing/$missingId/reports',
        queryParameters: {
          if (minSimilarity > 0) 'min_similarity': minSimilarity,
          'include_low': includeLow,
          if (until != null) 'until': isoWithOffset(until),
        },
      );

      return ReportBundle.fromJson(response.data ?? const <String, dynamic>{});
    } on DioException catch (error) {
      throw ApiException.from(error);
    }
  }
}
