import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/mock/mock_backend.dart';
import 'missing_case.dart';
import 'mock_missing_repository.dart';

/// 실종자(사건) 데이터 출처.
///
/// 화면은 이 타입만 본다. 지금은 [MockMissingRepository]가 구현하고,
/// 백엔드가 준비되면 dio를 쓰는 구현으로 [missingRepositoryProvider] 한 줄만
/// 바꾼다. 화면 코드는 건드리지 않는다.
abstract interface class MissingRepository {
  /// 목록. API 명세서 6) `GET /missing`.
  ///
  /// [lat]·[lng]를 주면 거리와 긴급도에 반영된다. 안 주면 `distanceKm`이 null이다.
  Future<MissingCaseList> fetchCases({
    String? query,
    MissingCategory? category,
    CaseStatusFilter status,
    MissingSort sort,
    double? lat,
    double? lng,
    double? radiusKm,
    int limit,
    String? cursor,
  });

  /// 상세. API 명세서 7) `GET /missing/{id}`.
  ///
  /// 없는 사건이면 `ApiErrorCode.notFound`로 던진다.
  Future<MissingCaseDetail> fetchCase(String id);

  /// 등록. API 명세서 5) `POST /missing`. 로그인이 필요하다.
  ///
  /// 모든 사진에서 얼굴을 못 찾으면 `ApiErrorCode.faceNotFound`로 거부된다.
  /// 제보와 달리 **등록은 얼굴 미검출을 거부한다**(설계 결정 4번).
  Future<MissingCaseRegistration> register(MissingCaseDraft draft);
}

/// 지금은 mock을 돌려준다. 백엔드가 붙으면 이 줄만 바꾼다.
final missingRepositoryProvider = Provider<MissingRepository>((ref) {
  return MockMissingRepository(ref.watch(mockBackendProvider));
});
