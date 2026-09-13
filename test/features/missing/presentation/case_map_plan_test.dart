import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/core/map/map_plan.dart';
import 'package:gyeotae/core/widgets/map_pin_icon.dart';
import 'package:gyeotae/features/missing/presentation/missing_detail_providers.dart';
import 'package:gyeotae/features/report/data/report.dart';

final _origin = DateTime(2026, 9, 12, 14, 40);

Report _report(
  String id,
  int minutesAfterOrigin,
  double? similarity, {
  int? routeIndex,
  double? lat = 37.45,
  double lng = 126.73,
}) {
  return Report(
    id: id,
    routeIndex: routeIndex,
    lat: lat,
    lng: lat == null ? null : lng,
    observedAt: _origin.add(Duration(minutes: minutesAfterOrigin)),
    similarity: similarity,
    grade: SimilarityGrade.fromSimilarity(similarity),
    faceFound: similarity != null,
    photoUrl: '/uploads/$id.jpg',
    status: ReportStatus.visible,
  );
}

/// 최신이 위. 경로 번호는 40% 이상에만 붙는다.
ReportBundle _bundle(List<Report> reports, {bool withOrigin = true}) {
  return ReportBundle(
    missingId: 'm_1',
    count: reports.length,
    reports: reports,
    path: const [],
    origin: withOrigin
        ? ReportOrigin(lat: 37.44, lng: 126.72, at: _origin)
        : null,
  );
}

MapPlan _plan(ReportBundle bundle, {bool highOnly = false}) {
  return caseMapPlan(bundle, TimelineView.of(bundle, highOnly: highOnly))!;
}

void main() {
  final reports = [
    _report('r_4', 150, 82.1, routeIndex: 3, lat: 37.47),
    _report('r_3', 100, 34.2, lat: 37.46),
    _report('r_2', 60, 64.9, routeIndex: 2, lat: 37.455),
    _report('r_1', 25, 76.4, routeIndex: 1, lat: 37.45),
  ];

  test('실종 지점과 제보 핀을 지도 탭과 같은 모양으로 찍는다', () {
    final plan = _plan(_bundle(reports));

    final origin = plan.marks.first as MissingMark;
    expect(origin.at, (lat: 37.44, lng: 126.72));
    // 지도 탭의 사건 선택 모드도 실종 지점을 가장 큰 핀으로 찍는다.
    expect(origin.level, MapPinLevel.golden);

    final pins = plan.marks.whereType<ReportMark>().toList();
    expect(pins.map((pin) => pin.id), ['r_4', 'r_3', 'r_2', 'r_1']);
    // 번호는 타임라인 번호와 같다. 40% 미만은 번호 없는 점으로 남는다.
    expect(pins.map((pin) => pin.routeIndex), [3, null, 2, 1]);
  });

  test('경로는 실종 지점에서 시작해 목격 시각순으로 잇는다', () {
    final plan = _plan(_bundle(reports));

    // 설계 결정 5번. 40% 미만(r_3)은 경로에서 빠진다.
    expect(plan.route, [
      (lat: 37.44, lng: 126.72),
      (lat: 37.45, lng: 126.73),
      (lat: 37.455, lng: 126.73),
      (lat: 37.47, lng: 126.73),
    ]);
  });

  test('핀이 여럿이면 전부 들어오게 맞춘다', () {
    final plan = _plan(_bundle(reports));

    expect(plan.fitMarks, isTrue);
  });

  test('아래 타임라인의 60% 토글과 같은 제보만 찍는다', () {
    final plan = _plan(_bundle(reports), highOnly: true);

    // 지도와 타임라인이 다른 제보를 보여주면 번호가 어긋나 보인다.
    expect(plan.marks.whereType<ReportMark>().map((pin) => pin.id), [
      'r_4',
      'r_2',
      'r_1',
    ]);
  });

  test('위치 없이 보낸 제보는 지도에 찍지 않는다', () {
    final plan = _plan(
      _bundle([_report('r_9', 30, 80, routeIndex: 1, lat: null)]),
    );

    expect(plan.marks.whereType<ReportMark>(), isEmpty);
    expect(plan.route, [(lat: 37.44, lng: 126.72)]);
  });

  test('제보가 없으면 실종 지점 하나를 가운데 둔다', () {
    final plan = _plan(_bundle(const []));

    expect(plan.marks, hasLength(1));
    expect(plan.center, (lat: 37.44, lng: 126.72));
    expect(plan.fitMarks, isFalse);
  });

  test('찍을 것이 하나도 없으면 지도를 그리지 않는다', () {
    final bundle = _bundle(const [], withOrigin: false);

    expect(
      caseMapPlan(bundle, TimelineView.of(bundle, highOnly: false)),
      isNull,
    );
  });

  test('같은 내용이면 같은 서명이다', () {
    // 서명이 같으면 지도에 다시 그리지 않는다. 다시 그리면 핀이 깜빡인다.
    expect(
      _plan(_bundle(reports)).signature,
      _plan(_bundle(reports)).signature,
    );
    expect(
      _plan(_bundle(reports)).signature,
      isNot(_plan(_bundle(reports), highOnly: true).signature),
    );
  });
}
