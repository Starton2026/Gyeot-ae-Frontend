import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/json.dart';
import 'case_edit.dart';
import 'missing_case.dart';
import 'missing_repository.dart';

/// 백엔드를 실제로 부르는 [MissingRepository].
///
/// 응답을 그대로 모델의 `fromJson`에 넘긴다. 여기서 필드를 만지지 않는다 —
/// 서버가 주는 이름과 모델이 읽는 이름이 명세서 기준으로 이미 같다.
class HttpMissingRepository implements MissingRepository {
  const HttpMissingRepository(this._dio);

  final Dio _dio;

  @override
  Future<MissingCaseList> fetchCases({
    String? query,
    MissingCategory? category,
    CaseStatusFilter status = CaseStatusFilter.active,
    MissingSort sort = MissingSort.urgency,
    double? lat,
    double? lng,
    double? radiusKm,
    int limit = 20,
    String? cursor,
  }) async {
    final keyword = query?.trim();

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/missing',
        queryParameters: {
          if (keyword != null && keyword.isNotEmpty) 'q': keyword,
          if (category != null) 'category': category.wire,
          'status': status.wire,
          'sort': sort.wire,
          // 좌표를 안 주면 서버가 거리와 거리 가중치를 빼고 계산한다.
          // 둘은 같이 간다. 하나만 보내면 반쪽짜리 위치가 된다.
          if (lat != null && lng != null) ...{'lat': lat, 'lng': lng},
          'radius_km': ?radiusKm,
          'limit': limit,
          'cursor': ?cursor,
        },
      );

      return MissingCaseList.fromJson(response.data ?? const <String, dynamic>{});
    } on DioException catch (error) {
      throw ApiException.from(error);
    }
  }

  @override
  Future<MissingCaseDetail> fetchCase(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/missing/$id');

      return MissingCaseDetail.fromJson(
        response.data ?? const <String, dynamic>{},
      );
    } on DioException catch (error) {
      throw ApiException.from(error);
    }
  }

  @override
  Future<MissingCaseRegistration> register(MissingCaseDraft draft) async {
    try {
      final form = FormData.fromMap({
        'name': draft.name,
        'age': '${draft.age}',
        'gender': draft.gender.wire,
        'category': draft.category.wire,
        'description': draft.description,
        'last_lat': '${draft.lastLat}',
        'last_lng': '${draft.lastLng}',
        if (draft.lastAddress != null) 'last_address': draft.lastAddress,
        if (draft.missingAt != null) 'missing_at': isoWithOffset(draft.missingAt!),
        if (draft.heightCm != null) 'height_cm': '${draft.heightCm}',
        if (draft.weightKg != null) 'weight_kg': '${draft.weightKg}',
        // 여러 장일수록 대조 정확도가 오른다. 서버가 장마다 얼굴 벡터를 뽑는다.
        'photos': [
          for (final path in draft.photoPaths)
            await MultipartFile.fromFile(path),
        ],
      });

      final response = await _dio.post<Map<String, dynamic>>(
        '/missing',
        data: form,
      );

      return MissingCaseRegistration.fromJson(
        response.data ?? const <String, dynamic>{},
      );
    } on DioException catch (error) {
      // 모든 사진에서 얼굴을 못 찾으면 FACE_NOT_FOUND로 거부된다. 등록은
      // 제보와 달리 얼굴이 있어야 한다(설계 결정 4번).
      throw ApiException.from(error);
    }
  }

  @override
  Future<MissingCaseDetail> updateCase(String id, CaseEdit edit) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/missing/$id',
        data: edit.toJson(),
      );

      return MissingCaseDetail.fromJson(
        response.data ?? const <String, dynamic>{},
      );
    } on DioException catch (error) {
      throw ApiException.from(error);
    }
  }

  @override
  Future<PhotoAddResult> addPhotos(String id, List<String> photoPaths) async {
    try {
      final form = FormData.fromMap({
        'photos': [
          for (final path in photoPaths) await MultipartFile.fromFile(path),
        ],
      });

      final response = await _dio.post<Map<String, dynamic>>(
        '/missing/$id/photos',
        data: form,
      );
      final data = response.data ?? const <String, dynamic>{};

      return (
        photoCount: (data['photos'] as List?)?.length ?? 0,
        reanalyzedReports: jsonInt(data['reanalyzed_reports']),
      );
    } on DioException catch (error) {
      throw ApiException.from(error);
    }
  }

  @override
  Future<int> resolveCase(String id) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/missing/$id/resolve',
      );

      return jsonInt(response.data?['notified_reporters']);
    } on DioException catch (error) {
      throw ApiException.from(error);
    }
  }
}
