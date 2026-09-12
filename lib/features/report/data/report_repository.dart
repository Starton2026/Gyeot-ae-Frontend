import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/mock/mock_backend.dart';
import 'analysis.dart';
import 'mock_report_repository.dart';
import 'report.dart';

/// 제보 데이터 출처.
///
/// 화면은 이 타입만 본다. 백엔드가 준비되면 [reportRepositoryProvider] 한 줄만
/// dio 구현으로 바꾼다.
abstract interface class ReportRepository {
  /// 사진 분석. API 명세서 13) `POST /reports/analyze`.
  ///
  /// 결과를 사용자에게 **먼저 보여주고** 확인을 받는다. 여기서 끝내지 않는다
  /// (설계 결정 2번). [photoPath]는 `image_picker`가 주는 `XFile.path`다.
  ///
  /// 얼굴을 못 찾아도 오류가 아니다. `faceFound: false`로 정상 응답이 온다.
  Future<AnalysisResult> analyze({
    required String missingId,
    required String photoPath,
  });

  /// 제보 확정. API 명세서 14) `POST /reports`.
  ///
  /// 사진을 다시 올리지 않고 [analysisId]로만 확정한다. 분석이 만료됐으면
  /// `ApiErrorCode.analysisExpired`로 던진다.
  ///
  /// [observedAt]은 **목격 시각**이다. 사진 EXIF를 우선 쓰고 사용자가 고칠 수 있다.
  /// 경로 정렬 기준이 이 값이다(설계 결정 5번).
  Future<Report> submit({
    required String analysisId,
    required double lat,
    required double lng,
    required DateTime observedAt,
    String? placeName,
  });

  /// 제보 목록과 이동 경로. API 명세서 15) `GET /missing/{id}/reports`.
  ///
  /// [minSimilarity]와 [includeLow]는 **표시 필터일 뿐** 저장된 제보를 지우지
  /// 않는다(설계 결정 3번). [until]은 지도의 시간 슬라이더가 쓴다.
  Future<ReportBundle> fetchReports(
    String missingId, {
    double minSimilarity,
    bool includeLow,
    DateTime? until,
  });
}

/// 지금은 mock을 돌려준다. 백엔드가 붙으면 이 줄만 바꾼다.
final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return MockReportRepository(ref.watch(mockBackendProvider));
});
