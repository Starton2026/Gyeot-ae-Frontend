import '../../../core/network/json.dart';
import 'report.dart';

/// 사진 분석 결과. API 명세서 13) `POST /reports/analyze`.
///
/// 분석과 제보는 2단계다(설계 결정 2번). 이 결과를 사용자에게 먼저 보여주고,
/// 확인을 받은 뒤에야 [analysisId]로 제보를 확정한다. 그래야 "취소"가 의미를 갖는다.
///
/// 임시 사진은 서버에서 TTL 10분으로 관리된다. 만료 후 확정하면
/// `ApiErrorCode.analysisExpired`가 온다.
class AnalysisResult {
  const AnalysisResult({
    required this.analysisId,
    required this.grade,
    required this.faceFound,
    required this.photoUrl,
    required this.expiresAt,
    this.similarity,
    this.matchedPhotoUrl,
  });

  final String analysisId;

  /// 얼굴을 못 찾았으면 null. 오류가 아니다(설계 결정 4번).
  final double? similarity;

  final SimilarityGrade grade;
  final bool faceFound;

  /// 방금 올린 사진. `uploads/tmp/` 아래에 임시로 있다.
  final String photoUrl;

  /// 여러 등록 사진 중 최고 유사도를 낸 쪽. S4-1의 대조 이미지에 쓴다.
  final String? matchedPhotoUrl;

  /// 이 시각이 지나면 확정할 수 없다.
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      analysisId: jsonString(json['analysis_id']),
      similarity: jsonDoubleOrNull(json['similarity']),
      grade: SimilarityGrade.fromJson(json['grade']),
      faceFound: jsonBool(json['face_found']),
      photoUrl: jsonString(json['photo_url']),
      matchedPhotoUrl: jsonStringOrNull(json['matched_photo_url']),
      expiresAt: jsonDate(json['expires_at']),
    );
  }
}
