import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/features/missing/presentation/timeline_labels.dart';
import 'package:gyeotae/features/report/data/report.dart';

Report _report({int? gapMinutes, String? bearing, double? distanceKm}) {
  return Report(
    id: 'r_1',
    lat: 37.45,
    lng: 126.73,
    observedAt: DateTime(2026, 9, 14, 15),
    similarity: 82.1,
    grade: SimilarityGrade.high,
    faceFound: true,
    photoUrl: '/uploads/r_1.jpg',
    status: ReportStatus.visible,
    routeIndex: bearing == null ? null : 2,
    gapMinutes: gapMinutes,
    bearing: bearing,
    distanceFromPrevKm: distanceKm,
  );
}

void main() {
  group('제보 공백(F-3.5.6)', () {
    test('한 시간 이상 끊기면 공백을 적는다', () {
      expect(timelineGapLabel(_report(gapMinutes: 80)), '⋯ 1시간 20분 공백');
    });

    test('한 시간이 안 되면 적지 않는다', () {
      expect(timelineGapLabel(_report(gapMinutes: 59)), isNull);
      expect(timelineGapLabel(_report()), isNull);
    });

    test('하루가 넘으면 일과 시간으로 적는다', () {
      expect(timelineGapLabel(_report(gapMinutes: 60 * 26)), '⋯ 1일 2시간 공백');
    });
  });

  group('이동 방향·거리(F-3.5.7)', () {
    test('화살표·방위·거리를 적는다', () {
      expect(
        timelineMovementLabel(_report(bearing: 'SE', distanceKm: 1.43)),
        '↘ 남동쪽 1.4km',
      );
      expect(
        timelineMovementLabel(_report(bearing: 'N', distanceKm: 0.6)),
        '↑ 북쪽 0.6km',
      );
    });

    test('거의 안 움직였으면 방향을 적지 않는다', () {
      // GPS 오차 안에서 방향을 적으면 없는 이동을 지어낸다.
      expect(
        timelineMovementLabel(_report(bearing: 'W', distanceKm: 0.04)),
        '앞 지점 근처',
      );
    });

    test('경로에 없는 제보는 방향이 없다', () {
      expect(timelineMovementLabel(_report()), isNull);
      expect(
        timelineMovementLabel(_report(bearing: 'X', distanceKm: 1.0)),
        isNull,
      );
    });
  });
}
