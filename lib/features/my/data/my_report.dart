import '../../../core/network/json.dart';
import '../../missing/data/missing_case.dart';
import '../../report/data/report.dart';

/// 내가 보낸 제보 한 건. API 명세서 18) `GET /me/reports`.
///
/// 제보 상세가 아니라 **어느 사건에 무엇을 보탰는지**를 보여주는 요약이다.
/// 그래서 사건 쪽 정보(이름·썸네일·상태)가 함께 온다.
class MyReport {
  const MyReport({
    required this.id,
    required this.missingName,
    required this.missingStatus,
    this.missingId,
    this.missingAge,
    this.missingGender,
    required this.grade,
    required this.observedAt,
    required this.contributedToPath,
    this.missingThumbnail,
    this.similarity,
  });

  final String id;

  /// 제보한 사건. 누르면 그 사건 상세로 간다.
  ///
  /// 명세서 18) 예시에는 없는 값이라, 옛 서버가 안 주면 null이고 눌리지 않는다.
  final String? missingId;

  final String missingName;

  /// 이름만으로는 누구인지 잘 안 떠오른다. `김하준 · 7세`로 적는다.
  final int? missingAge;
  final Gender? missingGender;

  /// 서버가 준 상대 경로. 보여줄 때 `Env.photoUrl`로 절대 URL을 만든다.
  final String? missingThumbnail;

  /// 그 사건이 아직 진행 중인지, 발견됐는지.
  final CaseStatus missingStatus;

  /// 얼굴을 못 찾았으면 null이다. 오류가 아니다(설계 결정 4번).
  final double? similarity;

  final SimilarityGrade grade;

  /// **목격 시각.** 보낸 시각이 아니다(설계 결정 5번).
  final DateTime observedAt;

  /// 내 제보가 실제 이동 경로에 들어갔는가.
  ///
  /// 명세서가 "재참여 동기의 핵심 지표"라고 적은 값이다. 보낸 제보가 어딘가에
  /// 쓰였다는 것을 본 사람이 다음에도 보낸다.
  final bool contributedToPath;

  /// `김하준 · 7세 남아`. 나이를 모르면 이름만.
  String get nameLine {
    final age = missingAge;
    if (age == null) return missingName;

    return '$missingName · ${formatAgeGender(age, missingGender ?? Gender.other)}';
  }

  factory MyReport.fromJson(Map<String, dynamic> json) {
    return MyReport(
      id: jsonString(json['id']),
      missingId: jsonStringOrNull(json['missing_id']),
      missingName: jsonString(json['missing_name']),
      missingAge: jsonIntOrNull(json['missing_age']),
      missingGender: json['missing_gender'] == null
          ? null
          : Gender.fromJson(json['missing_gender']),
      missingThumbnail: jsonStringOrNull(json['missing_thumbnail']),
      missingStatus: CaseStatus.fromJson(json['missing_status']),
      similarity: jsonDoubleOrNull(json['similarity']),
      grade: SimilarityGrade.fromJson(json['grade']),
      observedAt: jsonDate(json['observed_at']),
      contributedToPath: jsonBool(json['contributed_to_path']),
    );
  }
}

/// 내 제보 이력 한 묶음.
class MyReportList {
  const MyReportList({required this.count, required this.items});

  const MyReportList.empty() : count = 0, items = const [];

  /// 전체 건수. 화면에 몇 개가 그려지든 이 숫자를 적는다.
  final int count;

  final List<MyReport> items;

  bool get isEmpty => items.isEmpty;

  factory MyReportList.fromJson(Map<String, dynamic> json) {
    final items = json['items'];

    return MyReportList(
      count: jsonInt(json['count']),
      items: (items is List ? items : const [])
          .whereType<Map<String, dynamic>>()
          .map(MyReport.fromJson)
          .toList(growable: false),
    );
  }
}
