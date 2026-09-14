import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../../auth/presentation/auth_providers.dart';
import 'case_edit.dart';
import 'http_missing_repository.dart';
import 'missing_case.dart';

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

  /// 정보 수정. API 명세서 8) `PATCH /missing/{id}`. **보호자만.**
  ///
  /// 바뀐 상세를 돌려준다. 보호자가 아니면 `403`으로 던진다.
  Future<MissingCaseDetail> updateCase(String id, CaseEdit edit);

  /// 사진 추가. API 명세서 9) `POST /missing/{id}/photos`. **보호자만.**
  ///
  /// 서버가 기존 제보의 유사도를 전부 다시 계산하고 경로 번호를 다시 붙인다.
  /// 올린 사진 전부에서 얼굴을 못 찾으면 `ApiErrorCode.faceNotFound`로 던진다.
  Future<PhotoAddResult> addPhotos(String id, List<String> photoPaths);

  /// 발견 완료. API 명세서 10) `POST /missing/{id}/resolve`. **보호자만.**
  ///
  /// 사건을 지우지 않는다(설계 결정 7번). 결과 알림이 갈 제보자 수를 준다.
  Future<int> resolveCase(String id);
}

/// 백엔드를 부른다. 테스트는 `MockMissingRepository`로 override한다.
final missingRepositoryProvider = Provider<MissingRepository>((ref) {
  return HttpMissingRepository(ref.watch(dioProvider));
});

/// 사건 하나.
///
/// S3 상세와 S5 지도가 같은 사건을 보므로 조회를 여기 한 곳에 둔다. 화면마다
/// provider를 따로 만들면 같은 사건을 두 번 받아온다.
final missingDetailProvider = FutureProvider.family<MissingCaseDetail, String>((
  ref,
  caseId,
) async {
  // 보호자인지는 요청에 실린 토큰으로 서버가 정한다. 로그인·로그아웃하면 다시
  // 받아야 보호자 메뉴가 붙거나 떨어진다.
  ref.watch(authProvider.select((auth) => auth.value?.id));

  return ref.watch(missingRepositoryProvider).fetchCase(caseId);
});
