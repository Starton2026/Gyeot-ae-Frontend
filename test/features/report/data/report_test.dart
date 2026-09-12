import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/features/report/data/analysis.dart';
import 'package:gyeotae/features/report/data/report.dart';

/// API 명세서 15) 제보 목록 / 이동 경로의 응답 예시 그대로.
const _bundleJson = {
  'missing_id': 'm_ab12cd34',
  'count': 6,
  'hidden_count': 0,
  'origin': {
    'lat': 37.4491,
    'lng': 126.7312,
    'address': '인천 남동구 구월동 로데오거리',
    'at': '2026-09-11T14:40:00+09:00',
  },
  'reports': [
    {
      'id': 'r_01',
      'route_index': 3,
      'lat': 37.4701,
      'lng': 126.7512,
      'place_name': '남동구 만수동 버스정류장',
      'observed_at': '2026-09-11T17:12:00+09:00',
      'similarity': 82.1,
      'grade': 'high',
      'face_found': true,
      'photo_url': '/uploads/r_01.jpg',
      'status': 'visible',
      'confirmed': false,
      'gap_minutes': 42,
      'bearing': 'SE',
      'distance_from_prev_km': 1.4,
    },
    {
      'id': 'r_04',
      'route_index': null,
      'lat': 37.4600,
      'lng': 126.7400,
      'place_name': null,
      'observed_at': '2026-09-11T16:00:00+09:00',
      'similarity': 34.2,
      'grade': 'low',
      'face_found': true,
      'photo_url': '/uploads/r_04.jpg',
      'status': 'visible',
      'confirmed': false,
    },
  ],
  'path': [
    {
      'lat': 37.4491,
      'lng': 126.7312,
      'at': '2026-09-11T14:40:00+09:00',
      'index': 0,
      'origin': true,
    },
    {
      'lat': 37.4701,
      'lng': 126.7512,
      'at': '2026-09-11T17:12:00+09:00',
      'index': 3,
    },
  ],
  'time_range': {
    'from': '2026-09-11T14:40:00+09:00',
    'to': '2026-09-11T17:12:00+09:00',
    'ticks': ['2026-09-11T16:30:00+09:00', '2026-09-11T17:12:00+09:00'],
  },
};

void main() {
  group('ReportBundle.fromJson', () {
    test('명세 응답을 그대로 읽는다', () {
      final bundle = ReportBundle.fromJson(_bundleJson);

      expect(bundle.missingId, 'm_ab12cd34');
      expect(bundle.count, 6);
      expect(bundle.hiddenCount, 0);
      expect(bundle.reports, hasLength(2));
      expect(bundle.path, hasLength(2));
      expect(bundle.timeRange!.ticks, hasLength(2));
    });

    test('실종 지점이 경로의 첫 점이다', () {
      final bundle = ReportBundle.fromJson(_bundleJson);

      expect(bundle.origin!.address, '인천 남동구 구월동 로데오거리');
      expect(bundle.path.first.isOrigin, isTrue);
      expect(bundle.path.first.index, 0);
      expect(bundle.path.last.isOrigin, isFalse);
    });
  });

  group('Report.fromJson', () {
    test('경로에 포함된 제보를 읽는다', () {
      final report = ReportBundle.fromJson(_bundleJson).reports.first;

      expect(report.id, 'r_01');
      expect(report.routeIndex, 3);
      expect(report.similarity, 82.1);
      expect(report.grade, SimilarityGrade.high);
      expect(report.faceFound, isTrue);
      expect(report.placeName, '남동구 만수동 버스정류장');
      expect(report.gapMinutes, 42);
      expect(report.bearing, 'SE');
      expect(report.distanceFromPrevKm, 1.4);
      expect(report.isOnPath, isTrue);
    });

    test('40% 미만 제보는 routeIndex가 없고 경로에 안 들어간다', () {
      final report = ReportBundle.fromJson(_bundleJson).reports.last;

      expect(report.routeIndex, isNull);
      expect(report.grade, SimilarityGrade.low);
      expect(report.isOnPath, isFalse);
      expect(report.gapMinutes, isNull);
      expect(report.bearing, isNull);
    });

    test('얼굴 미검출은 similarity가 null이고 오류가 아니다', () {
      final report = Report.fromJson(const {
        'id': 'r_09',
        'route_index': null,
        'lat': 37.46,
        'lng': 126.74,
        'observed_at': '2026-09-11T16:00:00+09:00',
        'similarity': null,
        'grade': 'no_face',
        'face_found': false,
        'photo_url': '/uploads/r_09.jpg',
        'status': 'visible',
        'confirmed': false,
      });

      expect(report.similarity, isNull);
      expect(report.faceFound, isFalse);
      expect(report.grade, SimilarityGrade.noFace);
    });

    test('모르는 등급은 noFace로 떨어뜨린다', () {
      final report = Report.fromJson(const {
        'id': 'r_x',
        'lat': 37.4,
        'lng': 126.7,
        'observed_at': '2026-09-11T16:00:00+09:00',
        'grade': '새등급',
        'face_found': true,
        'photo_url': '/uploads/r_x.jpg',
        'status': 'visible',
        'confirmed': false,
      });

      expect(report.grade, SimilarityGrade.noFace);
    });
  });

  group('SimilarityGrade', () {
    test('명세 5.2의 구간대로 유사도에서 등급을 만든다', () {
      expect(SimilarityGrade.fromSimilarity(82.1), SimilarityGrade.high);
      expect(SimilarityGrade.fromSimilarity(70), SimilarityGrade.high);
      expect(SimilarityGrade.fromSimilarity(69.9), SimilarityGrade.medium);
      expect(SimilarityGrade.fromSimilarity(40), SimilarityGrade.medium);
      expect(SimilarityGrade.fromSimilarity(39.9), SimilarityGrade.low);
      expect(SimilarityGrade.fromSimilarity(null), SimilarityGrade.noFace);
    });

    test('경로 포함 기준은 40% 이상이다', () {
      expect(SimilarityGrade.high.countsTowardPath, isTrue);
      expect(SimilarityGrade.medium.countsTowardPath, isTrue);
      expect(SimilarityGrade.low.countsTowardPath, isFalse);
      expect(SimilarityGrade.noFace.countsTowardPath, isFalse);
    });
  });

  group('AnalysisResult.fromJson', () {
    test('명세 13) 정상 응답을 읽는다', () {
      final result = AnalysisResult.fromJson(const {
        'analysis_id': 'an_7x9k2m',
        'similarity': 63.4,
        'grade': 'medium',
        'face_found': true,
        'photo_url': '/uploads/tmp/an_7x9k2m.jpg',
        'matched_photo_url': '/uploads/m_ab12_1.jpg',
        'expires_at': '2026-09-11T17:24:00+09:00',
      });

      expect(result.analysisId, 'an_7x9k2m');
      expect(result.similarity, 63.4);
      expect(result.grade, SimilarityGrade.medium);
      expect(result.matchedPhotoUrl, '/uploads/m_ab12_1.jpg');
    });

    test('얼굴 미검출 응답도 정상 응답으로 읽는다', () {
      final result = AnalysisResult.fromJson(const {
        'analysis_id': 'an_7x9k2n',
        'similarity': null,
        'grade': 'no_face',
        'face_found': false,
        'photo_url': '/uploads/tmp/an_7x9k2n.jpg',
        'matched_photo_url': null,
        'expires_at': '2026-09-11T17:24:00+09:00',
      });

      expect(result.faceFound, isFalse);
      expect(result.similarity, isNull);
      expect(result.grade, SimilarityGrade.noFace);
      expect(result.matchedPhotoUrl, isNull);
    });
  });
}
