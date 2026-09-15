import '../../../core/network/json.dart';

/// 성별. API 명세서 5) 실종자 등록의 `gender`.
enum Gender {
  male('male'),
  female('female'),
  other('other');

  const Gender(this.wire);

  /// 서버와 주고받는 문자열.
  final String wire;

  static Gender fromJson(Object? value) {
    return switch (value) {
      'male' => Gender.male,
      'female' => Gender.female,
      _ => Gender.other,
    };
  }
}

/// 실종자 분류. 긴급도의 취약도 가중치를 정한다(기능정의서 5.1).
///
/// 구분을 진단명이 아니라 나이대로 잡는다. 배회는 진단과 상관없이 일어나고,
/// 등록하는 순간에 진단 여부를 따지게 하면 손이 멈춘다.
enum MissingCategory {
  child('child'),
  elderly('elderly'),
  other('other');

  const MissingCategory(this.wire);

  final String wire;

  /// 아동·어르신은 취약도 ×1.5.
  bool get isVulnerable => this != MissingCategory.other;

  /// 이 나이까지 아동이다. 실종아동법의 아동이 실종 당시 18세 미만이다.
  static const int childMaxAge = 17;

  /// 이 나이부터 어르신이다.
  static const int elderlyMinAge = 65;

  /// 나이대로 정한 구분(F-7.5). 그 사이는 성인이고, 서버 값은 `other`다.
  ///
  /// **나이만 본다.** 구분을 진단명으로 나누지 않는다는 명세를 따른다. 18~64세
  /// 발달장애인이나 젊은 치매 환자도 여기서는 성인이 되는데, 보호자가 칩을
  /// 바꿔 고를 수 있다.
  static MissingCategory forAge(int age) {
    if (age <= childMaxAge) return MissingCategory.child;
    if (age >= elderlyMinAge) return MissingCategory.elderly;

    return MissingCategory.other;
  }

  static MissingCategory fromJson(Object? value) {
    return switch (value) {
      'child' => MissingCategory.child,
      'elderly' => MissingCategory.elderly,
      // 백엔드가 아직 옛 값을 보낼 수 있다. 그때 조용히 '그 외'로 떨어지면
      // 취약도 가중치가 빠져 목록 순서가 틀어진다.
      'dementia' => MissingCategory.elderly,
      _ => MissingCategory.other,
    };
  }
}

/// 사건 상태. 발견 완료도 목록에서 지우지 않는다(설계 결정 7번).
enum CaseStatus {
  active('active'),
  resolved('resolved');

  const CaseStatus(this.wire);

  final String wire;

  static CaseStatus fromJson(Object? value) {
    return value == 'resolved' ? CaseStatus.resolved : CaseStatus.active;
  }
}

/// 긴급도 뱃지 색을 정하는 등급. 점수가 아니라 등급으로 받는다.
enum UrgencyLevel {
  critical('critical'),
  high('high'),
  normal('normal'),
  resolved('resolved');

  const UrgencyLevel(this.wire);

  final String wire;

  static UrgencyLevel fromJson(Object? value) {
    return switch (value) {
      'critical' => UrgencyLevel.critical,
      'high' => UrgencyLevel.high,
      'resolved' => UrgencyLevel.resolved,
      _ => UrgencyLevel.normal,
    };
  }
}

/// 목록 정렬 기준. API 명세서 6)의 `sort`.
enum MissingSort {
  urgency('urgency'),
  recent('recent'),
  distance('distance');

  const MissingSort(this.wire);

  final String wire;
}

/// 목록 상태 필터. API 명세서 6)의 `status`.
enum CaseStatusFilter {
  active('active'),
  resolved('resolved'),
  all('all');

  const CaseStatusFilter(this.wire);

  final String wire;
}

/// 목록 한 페이지. API 명세서 6) 실종자 목록.
class MissingCaseList {
  /// 아직 아무것도 없을 때. 부르지 않고 건너뛰는 자리에 쓴다.
  const MissingCaseList.empty()
    : count = 0,
      items = const [],
      nextCursor = null,
      activeCount = 0,
      resolvedCount = 0;

  const MissingCaseList({
    required this.count,
    required this.items,
    this.nextCursor,
    this.activeCount,
    this.resolvedCount,
  });

  /// 거른 뒤의 전체 건수. 이 페이지의 개수가 아니다.
  final int count;

  final List<MissingCaseSummary> items;

  /// 다음 페이지 커서. 마지막 페이지면 null.
  final String? nextCursor;

  /// [count] 중 진행 중인 건수. **서버가 안 세 주면 null이다.**
  ///
  /// 상태를 섞어 보여줄 때(`status=all`) 화면이 "진행 중 12건 · 발견 20건"으로
  /// 나눠 적는다. 합계만 적으면 32명이 실종된 것으로 읽힌다.
  final int? activeCount;

  /// [count] 중 발견 완료된 건수. **서버가 안 세 주면 null이다.**
  final int? resolvedCount;

  bool get hasMore => nextCursor != null;

  factory MissingCaseList.fromJson(Map<String, dynamic> json) {
    return MissingCaseList(
      count: jsonInt(json['count']),
      nextCursor: jsonStringOrNull(json['next_cursor']),
      activeCount: jsonIntOrNull(json['active_count']),
      resolvedCount: jsonIntOrNull(json['resolved_count']),
      items: jsonMapList(
        json['items'],
      ).map(MissingCaseSummary.fromJson).toList(growable: false),
    );
  }
}

/// 목록에 한 줄로 뜨는 사건. 상세보다 필드가 적다.
class MissingCaseSummary {
  const MissingCaseSummary({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.category,
    required this.description,
    required this.lastLat,
    required this.lastLng,
    required this.missingAt,
    required this.elapsedMinutes,
    required this.status,
    required this.reportCount,
    required this.urgencyLevel,
    this.thumbnail,
    this.lastAddress,
    this.resolvedAt,
    this.distanceKm,
    this.urgencyScore,
  });

  final String id;
  final String name;
  final int age;
  final Gender gender;
  final MissingCategory category;

  /// 인상착의 한 줄.
  final String description;

  /// 대표 사진 썸네일 경로.
  final String? thumbnail;

  final double lastLat;
  final double lastLng;
  final String? lastAddress;

  final DateTime missingAt;

  /// **서버가 계산한** 경과 분. 클라이언트가 다시 계산하지 않는다(설계 결정 6번).
  final int elapsedMinutes;

  final CaseStatus status;

  /// 발견된 시각. 진행 중이면 null이다.
  final DateTime? resolvedAt;

  final int reportCount;

  /// 내 위치를 보냈을 때만 채워진다.
  final double? distanceKm;

  final double? urgencyScore;
  final UrgencyLevel urgencyLevel;

  /// 골든타임(3시간) 안이다. 긴급 배너 노출 판단에 쓴다.
  bool get isWithinGoldenTime =>
      status == CaseStatus.active && elapsedMinutes < 180;

  /// 이름 옆에 붙는 한 줄. `7세 남아` · `81세 여성`.
  String get ageGenderLabel => formatAgeGender(age, gender);

  factory MissingCaseSummary.fromJson(Map<String, dynamic> json) {
    return MissingCaseSummary(
      id: jsonString(json['id']),
      name: jsonString(json['name']),
      age: jsonInt(json['age']),
      gender: Gender.fromJson(json['gender']),
      category: MissingCategory.fromJson(json['category']),
      description: jsonString(json['description']),
      thumbnail: jsonStringOrNull(json['thumbnail']),
      lastLat: jsonDouble(json['last_lat']),
      lastLng: jsonDouble(json['last_lng']),
      lastAddress: jsonStringOrNull(json['last_address']),
      missingAt: jsonDate(json['missing_at']),
      elapsedMinutes: jsonInt(json['elapsed_minutes']),
      status: CaseStatus.fromJson(json['status']),
      resolvedAt: jsonDateOrNull(json['resolved_at']),
      reportCount: jsonInt(json['report_count']),
      distanceKm: jsonDoubleOrNull(json['distance_km']),
      urgencyScore: jsonDoubleOrNull(json['urgency_score']),
      urgencyLevel: UrgencyLevel.fromJson(json['urgency_level']),
    );
  }
}

/// 사건 상세. API 명세서 7) 실종자 상세.
class MissingCaseDetail {
  const MissingCaseDetail({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.category,
    required this.description,
    required this.photos,
    required this.lastLat,
    required this.lastLng,
    required this.missingAt,
    required this.elapsedMinutes,
    required this.status,
    required this.reportCount,
    required this.matchCount,
    this.heightCm,
    this.weightKg,
    this.lastAddress,
    this.lastPlaceDetail,
    this.isGuardian = false,
    this.boostAvailable = false,
  });

  final String id;
  final String name;
  final int age;
  final Gender gender;
  final MissingCategory category;

  /// 인상착의 + 습관. 목록의 것보다 길다.
  final String description;

  final int? heightCm;
  final int? weightKg;

  /// 등록 사진 전부. 첫 장이 대표.
  final List<String> photos;

  final double lastLat;
  final double lastLng;
  final String? lastAddress;

  /// "학원 차량 승차 지점"처럼 주소로는 안 잡히는 위치 설명.
  final String? lastPlaceDetail;

  final DateTime missingAt;

  /// **서버가 계산한** 경과 분(설계 결정 6번).
  final int elapsedMinutes;

  final CaseStatus status;
  final int reportCount;

  /// 유사도 40% 이상으로 경로에 들어간 제보 수.
  final int matchCount;

  /// 내가 이 사건의 보호자다. 수정·발견완료·제보 관리 UI 노출 판단.
  final bool isGuardian;

  /// 긴급도 부스트를 아직 안 썼다. 사건당 1회.
  final bool boostAvailable;

  bool get isWithinGoldenTime =>
      status == CaseStatus.active && elapsedMinutes < 180;

  /// 이름 옆에 붙는 한 줄. `7세 남아`.
  String get ageGenderLabel => formatAgeGender(age, gender);

  factory MissingCaseDetail.fromJson(Map<String, dynamic> json) {
    return MissingCaseDetail(
      id: jsonString(json['id']),
      name: jsonString(json['name']),
      age: jsonInt(json['age']),
      gender: Gender.fromJson(json['gender']),
      category: MissingCategory.fromJson(json['category']),
      description: jsonString(json['description']),
      heightCm: jsonIntOrNull(json['height_cm']),
      weightKg: jsonIntOrNull(json['weight_kg']),
      photos: jsonStringList(json['photos']),
      lastLat: jsonDouble(json['last_lat']),
      lastLng: jsonDouble(json['last_lng']),
      lastAddress: jsonStringOrNull(json['last_address']),
      lastPlaceDetail: jsonStringOrNull(json['last_place_detail']),
      missingAt: jsonDate(json['missing_at']),
      elapsedMinutes: jsonInt(json['elapsed_minutes']),
      status: CaseStatus.fromJson(json['status']),
      reportCount: jsonInt(json['report_count']),
      matchCount: jsonInt(json['match_count']),
      isGuardian: jsonBool(json['is_guardian']),
      boostAvailable: jsonBool(json['boost_available']),
    );
  }
}

/// 등록 직후 응답. API 명세서 5). 상세와 형태가 다르다.
class MissingCaseRegistration {
  const MissingCaseRegistration({
    required this.id,
    required this.name,
    required this.photos,
    required this.faceEncodingCount,
    required this.notifiedDevices,
  });

  final String id;
  final String name;
  final List<String> photos;

  /// 얼굴 벡터를 뽑아낸 사진 수. 0이면 서버가 등록을 거부한다.
  final int faceEncodingCount;

  /// 알림이 나간 주변 기기 수. 완료 화면에 "N명에게 알렸어요"로 쓴다.
  final int notifiedDevices;

  factory MissingCaseRegistration.fromJson(Map<String, dynamic> json) {
    return MissingCaseRegistration(
      id: jsonString(json['id']),
      name: jsonString(json['name']),
      photos: jsonStringList(json['photos']),
      faceEncodingCount: jsonInt(json['face_encoding_count']),
      notifiedDevices: jsonInt(json['notified_devices']),
    );
  }
}

/// 등록 폼이 채워 넘기는 값. API 명세서 5)의 요청 필드.
class MissingCaseDraft {
  const MissingCaseDraft({
    required this.name,
    required this.age,
    required this.gender,
    required this.category,
    required this.description,
    required this.lastLat,
    required this.lastLng,
    required this.photoPaths,
    this.lastAddress,
    this.missingAt,
    this.heightCm,
    this.weightKg,
  });

  final String name;
  final int age;
  final Gender gender;
  final MissingCategory category;
  final String description;

  final double lastLat;
  final double lastLng;

  /// 안 보내면 서버가 역지오코딩한다.
  final String? lastAddress;

  /// 실종 일시. 안 주면 지금으로 본다.
  final DateTime? missingAt;

  final int? heightCm;
  final int? weightKg;

  /// 올릴 사진 경로. 첫 장이 대표. 여러 장일수록 대조 정확도가 오른다.
  final List<String> photoPaths;
}

/// `7세 남아` · `81세 여성`. 나이와 성별을 합친 표기.
///
/// 두 값을 따로 받는 화면마다 다시 조립하게 되는 말이라 여기 한 곳에서만 정한다.
/// 아동은 남아·여아로 적는 디자인 시안의 표기를 따른다.
/// [separator]는 상세 화면처럼 `7세 · 남아`로 띄워 적을 때 쓴다.
String formatAgeGender(int age, Gender gender, {String separator = ' '}) {
  final suffix = switch (gender) {
    Gender.male => age < 13 ? '남아' : '남성',
    Gender.female => age < 13 ? '여아' : '여성',
    Gender.other => null,
  };

  return suffix == null ? '$age세' : '$age세$separator$suffix';
}

/// 제보 버튼에 적는 말.
///
/// 81세 어르신 사건에 "이 아이를 봤어요"라고 적을 수는 없어서 두 가지를 둔다.
extension MissingCategoryCta on MissingCategory {
  String get witnessCtaLabel =>
      this == MissingCategory.child ? '이 아이를 봤어요' : '이분을 봤어요';
}
