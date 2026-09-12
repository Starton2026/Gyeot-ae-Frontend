import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/features/missing/data/missing_case.dart';

/// API 명세서 6) 실종자 목록의 응답 예시 그대로.
const _listJson = {
  'count': 14,
  'next_cursor': 'eyJvIjoyMH0',
  'items': [
    {
      'id': 'm_ab12cd34',
      'name': '김하준',
      'age': 7,
      'gender': 'male',
      'category': 'child',
      'description': '노란 후드티, 검정 백팩, 파란 운동화',
      'thumbnail': '/uploads/m_ab12_1_thumb.jpg',
      'last_lat': 37.4491,
      'last_lng': 126.7312,
      'last_address': '인천 남동구 구월동 로데오거리',
      'missing_at': '2026-09-11T14:40:00+09:00',
      'elapsed_minutes': 192,
      'status': 'active',
      'report_count': 6,
      'distance_km': 1.2,
      'urgency_score': 9.0,
      'urgency_level': 'critical',
    },
  ],
};

void main() {
  group('MissingCaseList.fromJson', () {
    test('명세 응답을 그대로 읽는다', () {
      final list = MissingCaseList.fromJson(_listJson);

      expect(list.count, 14);
      expect(list.nextCursor, 'eyJvIjoyMH0');
      expect(list.items, hasLength(1));
    });

    test('마지막 페이지면 nextCursor가 null이다', () {
      final list = MissingCaseList.fromJson({
        'count': 1,
        'next_cursor': null,
        'items': const [],
      });

      expect(list.nextCursor, isNull);
      expect(list.hasMore, isFalse);
    });
  });

  group('MissingCaseSummary.fromJson', () {
    test('명세 항목을 그대로 읽는다', () {
      final item = MissingCaseList.fromJson(_listJson).items.single;

      expect(item.id, 'm_ab12cd34');
      expect(item.name, '김하준');
      expect(item.age, 7);
      expect(item.gender, Gender.male);
      expect(item.category, MissingCategory.child);
      expect(item.thumbnail, '/uploads/m_ab12_1_thumb.jpg');
      expect(item.lastLat, 37.4491);
      expect(item.lastAddress, '인천 남동구 구월동 로데오거리');
      expect(item.elapsedMinutes, 192);
      expect(item.status, CaseStatus.active);
      expect(item.reportCount, 6);
      expect(item.distanceKm, 1.2);
      expect(item.urgencyLevel, UrgencyLevel.critical);
    });

    test('missingAt을 KST 오프셋째로 읽는다', () {
      final item = MissingCaseList.fromJson(_listJson).items.single;

      expect(item.missingAt.toUtc(), DateTime.utc(2026, 9, 11, 5, 40));
    });

    test('distanceKm은 위치를 안 보냈을 때 null이다', () {
      final item = MissingCaseSummary.fromJson({
        ...(_listJson['items']! as List).first as Map<String, dynamic>,
        'distance_km': null,
        'urgency_score': null,
      });

      expect(item.distanceKm, isNull);
      expect(item.urgencyScore, isNull);
    });

    test('모르는 enum 값은 other·normal로 떨어뜨린다', () {
      final item = MissingCaseSummary.fromJson({
        ...(_listJson['items']! as List).first as Map<String, dynamic>,
        'category': '새로생긴분류',
        'gender': '미상',
        'urgency_level': '없던등급',
      });

      expect(item.category, MissingCategory.other);
      expect(item.gender, Gender.other);
      expect(item.urgencyLevel, UrgencyLevel.normal);
    });
  });

  group('MissingCaseDetail.fromJson', () {
    test('명세 7) 상세 응답을 그대로 읽는다', () {
      final detail = MissingCaseDetail.fromJson(const {
        'id': 'm_ab12cd34',
        'name': '김하준',
        'age': 7,
        'gender': 'male',
        'category': 'child',
        'description': '노란 후드티, 검정 백팩.',
        'height_cm': 122,
        'weight_kg': 24,
        'photos': ['/uploads/m_ab12_1.jpg', '/uploads/m_ab12_2.jpg'],
        'last_lat': 37.4491,
        'last_lng': 126.7312,
        'last_address': '인천 남동구 구월동 로데오거리',
        'last_place_detail': '학원 차량 승차 지점',
        'missing_at': '2026-09-11T14:40:00+09:00',
        'elapsed_minutes': 192,
        'status': 'active',
        'report_count': 6,
        'match_count': 3,
        'is_guardian': false,
        'boost_available': false,
      });

      expect(detail.heightCm, 122);
      expect(detail.weightKg, 24);
      expect(detail.photos, hasLength(2));
      expect(detail.lastPlaceDetail, '학원 차량 승차 지점');
      expect(detail.matchCount, 3);
      expect(detail.isGuardian, isFalse);
      expect(detail.boostAvailable, isFalse);
    });

    test('선택 필드가 빠져도 읽는다', () {
      final detail = MissingCaseDetail.fromJson(const {
        'id': 'm_x',
        'name': '이순자',
        'age': 81,
        'gender': 'female',
        'category': 'dementia',
        'description': '베이지 카디건.',
        'photos': <String>[],
        'last_lat': 37.4,
        'last_lng': 126.7,
        'missing_at': '2026-09-11T14:40:00+09:00',
        'elapsed_minutes': 10,
        'status': 'resolved',
        'report_count': 0,
        'match_count': 0,
      });

      expect(detail.heightCm, isNull);
      expect(detail.weightKg, isNull);
      expect(detail.lastAddress, isNull);
      expect(detail.lastPlaceDetail, isNull);
      expect(detail.status, CaseStatus.resolved);
      expect(detail.isGuardian, isFalse);
    });
  });

  group('MissingCaseRegistration.fromJson', () {
    test('등록 응답은 상세와 형태가 다르다', () {
      final result = MissingCaseRegistration.fromJson(const {
        'id': 'm_ab12cd34',
        'name': '김하준',
        'photos': ['/uploads/m_ab12_1.jpg', '/uploads/m_ab12_2.jpg'],
        'face_encoding_count': 2,
        'notified_devices': 1284,
      });

      expect(result.id, 'm_ab12cd34');
      expect(result.faceEncodingCount, 2);
      expect(result.notifiedDevices, 1284);
    });
  });
}
