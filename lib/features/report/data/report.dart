import '../../../core/network/json.dart';

/// 유사도 등급. 기능정의서 5.2가 구간과 표시 규칙을 정한다.
///
/// 색은 `AppColors.gradeHigh`·`gradeMedium`·`gradeLow`·`gradeNoFace`와 1:1로 붙는다.
enum SimilarityGrade {
  /// 70% 이상. 경로 번호 O, 타임라인 기본 표시.
  high('high'),

  /// 40 ~ 70%. 경로 번호 O, 타임라인 기본 표시.
  medium('medium'),

  /// 40% 미만. 번호 없이 점, 점선·흐림, "확인 필요".
  low('low'),

  /// 얼굴 미검출. 오류가 아니다(설계 결정 4번).
  noFace('no_face');

  const SimilarityGrade(this.wire);

  final String wire;

  /// 등급 경계. 기능정의서 5.2.
  static const double highThreshold = 70;
  static const double pathThreshold = 40;

  /// 화면에서 기본으로 거르는 기준(기능정의서 5.2).
  ///
  /// **삭제 기준이 아니라 표시 기준이다.** S3 타임라인과 S5 지도의 토글이
  /// 같은 값을 쓴다.
  static const double displayFilterThreshold = 60;

  /// 경로에 들어가는 등급이다. `route_index`는 40% 이상에만 붙는다.
  ///
  /// 임계값은 **표시와 경로 포함만** 정한다. 저장 여부와는 무관하다(설계 결정 3번).
  bool get countsTowardPath =>
      this == SimilarityGrade.high || this == SimilarityGrade.medium;

  static SimilarityGrade fromJson(Object? value) {
    return switch (value) {
      'high' => SimilarityGrade.high,
      'medium' => SimilarityGrade.medium,
      'low' => SimilarityGrade.low,
      _ => SimilarityGrade.noFace,
    };
  }

  /// 유사도 점수에서 등급을 정한다. 얼굴을 못 찾았으면 [noFace].
  static SimilarityGrade fromSimilarity(double? similarity) {
    if (similarity == null) return SimilarityGrade.noFace;
    if (similarity >= highThreshold) return SimilarityGrade.high;
    if (similarity >= pathThreshold) return SimilarityGrade.medium;
    return SimilarityGrade.low;
  }
}

/// 제보 노출 상태.
///
/// 기능정의서 6절의 Report는 `status(visible|hidden|confirmed)`로 적혀 있지만
/// API 명세서 15)의 응답은 `status`와 `confirmed`를 따로 준다. 통신 형식이
/// 기준이므로 여기서는 응답을 따르고, `confirmed` 값도 함께 받는다.
enum ReportStatus {
  visible('visible'),
  hidden('hidden');

  const ReportStatus(this.wire);

  final String wire;

  static ReportStatus fromJson(Object? value) {
    return value == 'hidden' ? ReportStatus.hidden : ReportStatus.visible;
  }
}

/// 시민이 올린 목격 제보 한 건.
class Report {
  const Report({
    required this.id,
    required this.lat,
    required this.lng,
    required this.observedAt,
    required this.grade,
    required this.faceFound,
    required this.photoUrl,
    required this.status,
    this.routeIndex,
    this.placeName,
    this.similarity,
    this.confirmed = false,
    this.gapMinutes,
    this.bearing,
    this.distanceFromPrevKm,
  });

  final String id;

  /// 경로 위의 순번. 지도 핀 번호와 같다. 40% 미만이면 null.
  final int? routeIndex;

  final double lat;
  final double lng;
  final String? placeName;

  /// **목격 시각.** 경로 정렬 기준이다. 전송 시각이 아니다(설계 결정 5번).
  final DateTime observedAt;

  /// 얼굴을 못 찾았으면 null.
  final double? similarity;

  final SimilarityGrade grade;
  final bool faceFound;
  final String photoUrl;

  final ReportStatus status;

  /// 보호자가 "이 사람 맞다"고 확인했다.
  final bool confirmed;

  /// 이전 제보와의 간격(분). 60분 이상이면 타임라인에 공백으로 표시한다.
  final int? gapMinutes;

  /// 이전 제보 기준 이동 방향. 8방위 문자열(N·NE·E·SE·S·SW·W·NW).
  final String? bearing;

  final double? distanceFromPrevKm;

  /// 경로 선에 포함된다.
  bool get isOnPath => routeIndex != null;

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: jsonString(json['id']),
      routeIndex: jsonIntOrNull(json['route_index']),
      lat: jsonDouble(json['lat']),
      lng: jsonDouble(json['lng']),
      placeName: jsonStringOrNull(json['place_name']),
      observedAt: jsonDate(json['observed_at']),
      similarity: jsonDoubleOrNull(json['similarity']),
      grade: SimilarityGrade.fromJson(json['grade']),
      faceFound: jsonBool(json['face_found']),
      photoUrl: jsonString(json['photo_url']),
      status: ReportStatus.fromJson(json['status']),
      confirmed: jsonBool(json['confirmed']),
      gapMinutes: jsonIntOrNull(json['gap_minutes']),
      bearing: jsonStringOrNull(json['bearing']),
      distanceFromPrevKm: jsonDoubleOrNull(json['distance_from_prev_km']),
    );
  }
}

/// 최초 실종 지점. 경로의 출발점이다.
class ReportOrigin {
  const ReportOrigin({
    required this.lat,
    required this.lng,
    required this.at,
    this.address,
  });

  final double lat;
  final double lng;
  final String? address;
  final DateTime at;

  factory ReportOrigin.fromJson(Map<String, dynamic> json) {
    return ReportOrigin(
      lat: jsonDouble(json['lat']),
      lng: jsonDouble(json['lng']),
      address: jsonStringOrNull(json['address']),
      at: jsonDate(json['at']),
    );
  }
}

/// 경로 폴리라인의 한 점.
class PathPoint {
  const PathPoint({
    required this.lat,
    required this.lng,
    required this.at,
    required this.index,
    this.isOrigin = false,
  });

  final double lat;
  final double lng;
  final DateTime at;

  /// 지도 핀 번호. 실종 지점은 0.
  final int index;

  /// 최초 실종 지점이다. 제보가 아니라 등록 정보에서 온다.
  final bool isOrigin;

  factory PathPoint.fromJson(Map<String, dynamic> json) {
    return PathPoint(
      lat: jsonDouble(json['lat']),
      lng: jsonDouble(json['lng']),
      at: jsonDate(json['at']),
      index: jsonInt(json['index']),
      isOrigin: jsonBool(json['origin']),
    );
  }
}

/// 시간 슬라이더가 쓰는 범위와 눈금.
class ReportTimeRange {
  const ReportTimeRange({
    required this.from,
    required this.to,
    required this.ticks,
  });

  final DateTime from;
  final DateTime to;

  /// 슬라이더 눈금 위치. 제보가 있는 시각들.
  final List<DateTime> ticks;

  factory ReportTimeRange.fromJson(Map<String, dynamic> json) {
    return ReportTimeRange(
      from: jsonDate(json['from']),
      to: jsonDate(json['to']),
      ticks: jsonStringList(
        json['ticks'],
      ).map(DateTime.parse).toList(growable: false),
    );
  }
}

/// 한 사건의 제보 목록과 이동 경로. API 명세서 15).
///
/// [reports]와 [path]의 정렬 방향이 반대인 것은 의도된 것이다. 타임라인은
/// 최신이 위, 경로는 시간순이어야 한다.
class ReportBundle {
  const ReportBundle({
    required this.missingId,
    required this.count,
    required this.reports,
    required this.path,
    this.hiddenCount = 0,
    this.origin,
    this.timeRange,
  });

  final String missingId;

  /// 보이는 제보 수.
  final int count;

  /// 숨김 처리된 제보 수. 보호자에게만 의미가 있다.
  final int hiddenCount;

  final ReportOrigin? origin;

  /// **최신순.** 타임라인 표시 순서 그대로다.
  final List<Report> reports;

  /// **시간순.** `route_index`가 있는 제보 + 맨 앞의 실종 지점.
  final List<PathPoint> path;

  final ReportTimeRange? timeRange;

  factory ReportBundle.fromJson(Map<String, dynamic> json) {
    final origin = jsonMapOrNull(json['origin']);
    final timeRange = jsonMapOrNull(json['time_range']);

    return ReportBundle(
      missingId: jsonString(json['missing_id']),
      count: jsonInt(json['count']),
      hiddenCount: jsonInt(json['hidden_count']),
      origin: origin == null ? null : ReportOrigin.fromJson(origin),
      reports: jsonMapList(
        json['reports'],
      ).map(Report.fromJson).toList(growable: false),
      path: jsonMapList(
        json['path'],
      ).map(PathPoint.fromJson).toList(growable: false),
      timeRange: timeRange == null
          ? null
          : ReportTimeRange.fromJson(timeRange),
    );
  }
}

/// 분석 결과에 적는 등급 한 줄(F-4.1.2).
///
/// 이름만 적으면 "낮음"이 제보를 멈추게 한다. 이 화면의 목적은 거르기가 아니라
/// **확신 없는 목격자에게 면죄부를 주는 것**이라, 등급마다 다음 행동을 붙여
/// 적는다. "보통 · 확인해볼 만합니다"만 명세에 있고 나머지 셋은 같은 규칙으로
/// 맞춘 문구다.
extension SimilarityGradeLabel on SimilarityGrade {
  /// `높음` · `보통` · `낮음` · `얼굴 미검출`.
  String get displayLabel => switch (this) {
    SimilarityGrade.high => '높음',
    SimilarityGrade.medium => '보통',
    SimilarityGrade.low => '낮음',
    SimilarityGrade.noFace => '얼굴 미검출',
  };

  /// `보통 · 확인해볼 만합니다`.
  String get analysisHeadline => switch (this) {
    SimilarityGrade.high => '높음 · 같은 사람일 가능성이 큽니다',
    SimilarityGrade.medium => '보통 · 확인해볼 만합니다',
    SimilarityGrade.low => '낮음 · 그래도 제보해 주세요',
    SimilarityGrade.noFace => '얼굴 미검출 · 위치와 시간은 남습니다',
  };
}
