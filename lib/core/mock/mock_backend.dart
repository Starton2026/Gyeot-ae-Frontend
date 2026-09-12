import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/missing/data/missing_case.dart';
import '../../features/report/data/report.dart';

/// 백엔드가 붙기 전까지 쓰는 인메모리 저장소.
///
/// **백엔드가 준비되면 이 폴더(`core/mock/`)를 통째로 지운다.** 화면 코드는
/// Repository 추상 타입만 보고 있어서, provider가 돌려주는 구현만 바꾸면 된다.
///
/// 데이터를 객체로 직접 만들지 않고 **API 명세서 그대로의 JSON Map**으로 들고 있다.
/// 그래야 `fromJson`이 지금부터 실제로 돌아서, 백엔드를 붙이는 날 파싱 버그를
/// 처음 만나는 일이 없다.
///
/// 시각은 전부 **실행 시점 기준 상대값**으로 만든다. 고정 날짜를 박으면 다음 날
/// 데모에서 "3일 전 실종"이 되어 골든타임 배너가 뜨지 않는다.
class MockBackend {
  MockBackend._(this._cases, this._reports);

  /// 제보가 가장 많이 달린 시연용 사건. 타임라인과 경로를 볼 수 있다.
  static const String demoCaseId = 'm_ab12cd34';

  final List<Map<String, dynamic>> _cases;
  final List<Map<String, dynamic>> _reports;
  final Map<String, Map<String, dynamic>> _analyses = {};

  int _sequence = 0;

  /// 분석이 돌아가며 내놓는 유사도. null은 얼굴 미검출.
  ///
  /// 무작위로 만들면 데모가 실행할 때마다 달라진다. 고정 순서면 "이번엔 높음,
  /// 다음은 보통"을 예상하고 시연할 수 있다.
  static const List<double?> _analysisCycle = [82.1, 63.4, null, 34.2, 91.5];

  List<Map<String, dynamic>> get cases => List.unmodifiable(_cases);

  Map<String, dynamic>? findCase(String id) {
    for (final record in _cases) {
      if (record['id'] == id) return record;
    }
    return null;
  }

  List<Map<String, dynamic>> reportsFor(String caseId) {
    return _reports
        .where((report) => report['missing_id'] == caseId)
        .toList(growable: false);
  }

  // ── 사건 ───────────────────────────────────────────────────

  /// 등록 폼이 넘긴 값으로 새 사건을 만든다. 내가 등록했으므로 보호자가 된다.
  Map<String, dynamic> addCase(MissingCaseDraft draft) {
    final id = 'm_new${(_sequence++).toString().padLeft(2, '0')}';
    final photos = List.generate(
      draft.photoPaths.length,
      (i) => '/uploads/${id}_${i + 1}.jpg',
    );

    final record = <String, dynamic>{
      'id': id,
      'name': draft.name,
      'age': draft.age,
      'gender': draft.gender.wire,
      'category': draft.category.wire,
      'description': draft.description,
      'height_cm': draft.heightCm,
      'weight_kg': draft.weightKg,
      'photos': photos,
      'last_lat': draft.lastLat,
      'last_lng': draft.lastLng,
      'last_address': draft.lastAddress,
      'last_place_detail': null,
      'missing_at': (draft.missingAt ?? DateTime.now()).toIso8601String(),
      'status': CaseStatus.active.wire,
      'is_guardian': true,
      'boost_available': true,
    };

    _cases.insert(0, record);
    return record;
  }

  /// 목록 한 줄에 쓰는 형태. 경과 시간과 긴급도는 **읽을 때마다 다시 계산**한다.
  Map<String, dynamic> summaryJson(
    Map<String, dynamic> record, {
    double? lat,
    double? lng,
  }) {
    final photos = (record['photos'] as List?)?.cast<String>() ?? const [];
    final elapsed = _elapsedMinutes(record);
    final status = record['status'] as String;
    final distanceKm = _distanceKm(record, lat: lat, lng: lng);

    return {
      'id': record['id'],
      'name': record['name'],
      'age': record['age'],
      'gender': record['gender'],
      'category': record['category'],
      'description': record['description'],
      'thumbnail': photos.isEmpty ? null : photos.first,
      'last_lat': record['last_lat'],
      'last_lng': record['last_lng'],
      'last_address': record['last_address'],
      'missing_at': record['missing_at'],
      'elapsed_minutes': elapsed,
      'status': status,
      'report_count': reportsFor(record['id'] as String).length,
      'distance_km': distanceKm,
      'urgency_score': _urgencyScore(record, distanceKm: distanceKm),
      'urgency_level': _urgencyLevel(record),
    };
  }

  /// 상세 화면에 쓰는 형태. 목록보다 필드가 많다.
  Map<String, dynamic> detailJson(Map<String, dynamic> record) {
    final reports = reportsFor(record['id'] as String);

    return {
      'id': record['id'],
      'name': record['name'],
      'age': record['age'],
      'gender': record['gender'],
      'category': record['category'],
      'description': record['description'],
      'height_cm': record['height_cm'],
      'weight_kg': record['weight_kg'],
      'photos': record['photos'],
      'last_lat': record['last_lat'],
      'last_lng': record['last_lng'],
      'last_address': record['last_address'],
      'last_place_detail': record['last_place_detail'],
      'missing_at': record['missing_at'],
      'elapsed_minutes': _elapsedMinutes(record),
      'status': record['status'],
      'report_count': reports.length,
      'match_count': reports
          .where((r) => _gradeOf(r).countsTowardPath)
          .length,
      'is_guardian': record['is_guardian'] ?? false,
      'boost_available': record['boost_available'] ?? false,
    };
  }

  /// 등록 직후 응답. 상세와 형태가 다르다(API 명세서 5).
  Map<String, dynamic> registrationJson(Map<String, dynamic> record) {
    final photos = (record['photos'] as List?)?.cast<String>() ?? const [];

    return {
      'id': record['id'],
      'name': record['name'],
      'photos': photos,
      'face_encoding_count': photos.length,
      // 반경 안 기기 수. 위치에 따라 달라지는 값이라 적당히 흩뜨려 둔다.
      'notified_devices': 300 + photos.length * 17 + _cases.length * 53,
    };
  }

  // ── 분석 · 제보 ─────────────────────────────────────────────

  /// 사진 한 장을 분석한다. 결과는 10분간 유효하고 한 번만 확정할 수 있다.
  Map<String, dynamic> createAnalysis(String missingId) {
    final id = 'an_${(_sequence++).toString().padLeft(3, '0')}';
    final similarity = _analysisCycle[_sequence % _analysisCycle.length];
    final record = <String, dynamic>{
      'analysis_id': id,
      'missing_id': missingId,
      'similarity': similarity,
      'grade': SimilarityGrade.fromSimilarity(similarity).wire,
      'face_found': similarity != null,
      'photo_url': '/uploads/tmp/$id.jpg',
      'matched_photo_url': similarity == null
          ? null
          : ((findCase(missingId)?['photos'] as List?)?.firstOrNull),
      'expires_at': DateTime.now()
          .add(const Duration(minutes: 10))
          .toIso8601String(),
    };

    _analyses[id] = record;
    return record;
  }

  /// 분석 결과를 꺼내 쓰고 지운다. 없으면 null — 만료로 다룬다.
  Map<String, dynamic>? consumeAnalysis(String analysisId) {
    final record = _analyses.remove(analysisId);
    if (record == null) return null;

    final expiresAt = DateTime.parse(record['expires_at'] as String);
    if (DateTime.now().isAfter(expiresAt)) return null;

    return record;
  }

  /// 확정된 제보를 저장한다. 40% 미만도 저장한다(설계 결정 3번).
  Map<String, dynamic> addReport({
    required Map<String, dynamic> analysis,
    required double lat,
    required double lng,
    required DateTime observedAt,
    String? placeName,
  }) {
    final id = 'r_new${(_sequence++).toString().padLeft(2, '0')}';
    final record = <String, dynamic>{
      'id': id,
      'missing_id': analysis['missing_id'],
      'lat': lat,
      'lng': lng,
      'place_name': placeName,
      'observed_at': observedAt.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
      'similarity': analysis['similarity'],
      'grade': analysis['grade'],
      'face_found': analysis['face_found'],
      'photo_url': '/uploads/$id.jpg',
      'status': ReportStatus.visible.wire,
      'confirmed': false,
    };

    _reports.add(record);
    return record;
  }

  // ── 계산 ───────────────────────────────────────────────────

  int _elapsedMinutes(Map<String, dynamic> record) {
    final missingAt = DateTime.parse(record['missing_at'] as String);
    return DateTime.now().difference(missingAt).inMinutes;
  }

  SimilarityGrade _gradeOf(Map<String, dynamic> report) {
    return SimilarityGrade.fromJson(report['grade']);
  }

  String _urgencyLevel(Map<String, dynamic> record) {
    if (record['status'] == CaseStatus.resolved.wire) {
      return UrgencyLevel.resolved.wire;
    }

    final elapsed = _elapsedMinutes(record);
    if (elapsed < 180) return UrgencyLevel.critical.wire;
    if (elapsed < 720) return UrgencyLevel.high.wire;
    return UrgencyLevel.normal.wire;
  }

  /// 긴급도 = 골든타임 × 취약도 × 거리 × 제보공백 (기능정의서 5.1).
  double? _urgencyScore(Map<String, dynamic> record, {double? distanceKm}) {
    if (record['status'] == CaseStatus.resolved.wire) return 0;

    final elapsed = _elapsedMinutes(record);
    final golden = switch (elapsed) {
      < 180 => 3.0,
      < 720 => 2.0,
      < 2880 => 1.5,
      _ => 1.0,
    };

    final category = MissingCategory.fromJson(record['category']);
    final vulnerability = category.isVulnerable ? 1.5 : 1.0;

    final distance = switch (distanceKm) {
      null => 1.0,
      < 3 => 2.0,
      < 10 => 1.3,
      _ => 1.0,
    };

    final reports = reportsFor(record['id'] as String);
    final lastReportAt = reports.isEmpty
        ? null
        : reports
              .map((r) => DateTime.parse(r['observed_at'] as String))
              .reduce((a, b) => a.isAfter(b) ? a : b);
    final gap =
        lastReportAt != null &&
            DateTime.now().difference(lastReportAt).inMinutes >= 60
        ? 1.3
        : 1.0;

    final score = golden * vulnerability * distance * gap;
    return double.parse(score.toStringAsFixed(2));
  }

  double? _distanceKm(
    Map<String, dynamic> record, {
    double? lat,
    double? lng,
  }) {
    if (lat == null || lng == null) return null;

    final distance = haversineKm(
      lat,
      lng,
      record['last_lat'] as double,
      record['last_lng'] as double,
    );
    return double.parse(distance.toStringAsFixed(2));
  }

  /// 두 좌표 사이 거리(km).
  static double haversineKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusKm = 6371.0;
    double toRadians(double degrees) => degrees * math.pi / 180;

    final dLat = toRadians(lat2 - lat1);
    final dLng = toRadians(lng2 - lng1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(toRadians(lat1)) *
            math.cos(toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  // ── 시드 ───────────────────────────────────────────────────

  /// 데모용 데이터를 채워 만든다.
  ///
  /// 사건 6건에 아동·치매노인·그 외가 섞여 있고, 한 건은 발견 완료다
  /// (설계 결정 7번 — 목록에서 지우지 않는다). 시연용 사건에는 유사도 등급
  /// 4종이 모두 달려 있어 타임라인과 경로 표시를 한 화면에서 확인할 수 있다.
  factory MockBackend.seeded() {
    final now = DateTime.now();
    String ago(Duration duration) =>
        now.subtract(duration).toIso8601String();

    final cases = <Map<String, dynamic>>[
      {
        'id': demoCaseId,
        'name': '김하준',
        'age': 7,
        'gender': 'male',
        'category': 'child',
        'description':
            '노란 후드티, 검정 백팩, 파란 운동화. 말수가 적고 버스·간판에 관심을 보이면 오래 서 있습니다.',
        'height_cm': 122,
        'weight_kg': 24,
        'photos': ['/uploads/m_ab12_1.jpg', '/uploads/m_ab12_2.jpg'],
        'last_lat': 37.4491,
        'last_lng': 126.7312,
        'last_address': '인천 남동구 구월동 로데오거리',
        'last_place_detail': '학원 차량 승차 지점',
        'missing_at': ago(const Duration(hours: 2, minutes: 55)),
        'status': 'active',
        'is_guardian': false,
        'boost_available': false,
      },
      {
        'id': 'm_cd34ef56',
        'name': '이순자',
        'age': 81,
        'gender': 'female',
        'category': 'dementia',
        'description': '베이지 카디건, 남색 몸뻬, 꽃무늬 손수건. 집 방향을 물으면 예전 주소를 말합니다.',
        'height_cm': 152,
        'weight_kg': 48,
        'photos': ['/uploads/m_cd34_1.jpg'],
        'last_lat': 37.4563,
        'last_lng': 126.7052,
        'last_address': '인천 남동구 만수동 만수시장',
        'last_place_detail': '시장 정문 앞',
        'missing_at': ago(const Duration(hours: 9, minutes: 20)),
        'status': 'active',
        'is_guardian': false,
        'boost_available': true,
      },
      {
        'id': 'm_ef56gh78',
        'name': '박민수',
        'age': 9,
        'gender': 'male',
        'category': 'child',
        'description': '회색 패딩, 빨간 목도리, 안경 착용.',
        'height_cm': 134,
        'weight_kg': 30,
        'photos': ['/uploads/m_ef56_1.jpg'],
        'last_lat': 37.4702,
        'last_lng': 126.6801,
        'last_address': '인천 부평구 부평동 부평역 광장',
        'last_place_detail': null,
        'missing_at': ago(const Duration(hours: 26)),
        'status': 'active',
        'is_guardian': false,
        'boost_available': true,
      },
      {
        'id': 'm_gh78ij90',
        'name': '최영자',
        'age': 78,
        'gender': 'female',
        'category': 'dementia',
        'description': '분홍 스웨터, 지팡이 사용. 다리가 불편해 멀리 가지 못합니다.',
        'height_cm': 148,
        'weight_kg': 44,
        'photos': ['/uploads/m_gh78_1.jpg'],
        'last_lat': 37.4405,
        'last_lng': 126.7011,
        'last_address': '인천 남동구 논현동 소래포구',
        'last_place_detail': null,
        'missing_at': ago(const Duration(days: 3, hours: 4)),
        'status': 'active',
        'is_guardian': false,
        'boost_available': true,
      },
      {
        'id': 'm_ij90kl12',
        'name': '정우진',
        'age': 34,
        'gender': 'male',
        'category': 'other',
        'description': '검정 후드, 청바지. 지적장애가 있어 길을 잃으면 한자리에 오래 머뭅니다.',
        'height_cm': 171,
        'weight_kg': 66,
        'photos': ['/uploads/m_ij90_1.jpg'],
        'last_lat': 37.4812,
        'last_lng': 126.7223,
        'last_address': '인천 남동구 간석동 간석오거리역',
        'last_place_detail': null,
        'missing_at': ago(const Duration(hours: 50)),
        'status': 'active',
        'is_guardian': false,
        'boost_available': true,
      },
      {
        'id': 'm_kl12mn34',
        'name': '한복순',
        'age': 84,
        'gender': 'female',
        'category': 'dementia',
        'description': '하늘색 블라우스, 흰 운동화.',
        'height_cm': 150,
        'weight_kg': 46,
        'photos': ['/uploads/m_kl12_1.jpg'],
        'last_lat': 37.4358,
        'last_lng': 126.7405,
        'last_address': '인천 남동구 서창동 서창중앙공원',
        'last_place_detail': null,
        'missing_at': ago(const Duration(days: 5)),
        'status': 'resolved',
        'is_guardian': false,
        'boost_available': false,
      },
    ];

    // 시연용 사건의 제보 6건. 등급 4종이 모두 나오고, 40% 미만과 얼굴 미검출이
    // 경로에서 빠지는 것을 한 화면에서 확인할 수 있다.
    Map<String, dynamic> report(
      String id,
      Duration since,
      double lat,
      double lng,
      double? similarity, {
      String? placeName,
    }) {
      return {
        'id': id,
        'missing_id': demoCaseId,
        'lat': lat,
        'lng': lng,
        'place_name': placeName,
        'observed_at': ago(since),
        'created_at': ago(since),
        'similarity': similarity,
        'grade': SimilarityGrade.fromSimilarity(similarity).wire,
        'face_found': similarity != null,
        'photo_url': '/uploads/$id.jpg',
        'status': 'visible',
        'confirmed': false,
      };
    }

    final reports = <Map<String, dynamic>>[
      report(
        'r_01',
        const Duration(hours: 2, minutes: 30),
        37.4552,
        126.7380,
        76.4,
        placeName: '구월동 롯데백화점 앞 횡단보도',
      ),
      report(
        'r_02',
        const Duration(hours: 1, minutes: 50),
        37.4601,
        126.7421,
        58.2,
        placeName: '인천시청역 2번 출구',
      ),
      report('r_03', const Duration(hours: 1, minutes: 20), 37.4634, 126.7455, 34.2),
      report(
        'r_04',
        const Duration(minutes: 55),
        37.4668,
        126.7488,
        64.9,
        placeName: '만수주공 앞 버스정류장',
      ),
      report('r_05', const Duration(minutes: 30), 37.4690, 126.7501, null),
      report(
        'r_06',
        const Duration(minutes: 12),
        37.4701,
        126.7512,
        82.1,
        placeName: '만수동 주민센터 앞',
      ),
    ];

    return MockBackend._(cases, reports);
  }
}

/// 앱 전체가 같은 mock 저장소를 본다. 제보하면 상세 화면에 바로 반영된다.
final mockBackendProvider = Provider<MockBackend>((ref) {
  return MockBackend.seeded();
});
