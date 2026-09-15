import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/features/map/presentation/map_providers.dart';
import 'package:gyeotae/features/report/data/report.dart';

final _origin = DateTime(2026, 9, 12, 14, 40);

Report _report(
  String id,
  int minutesAfterOrigin,
  double? similarity, {
  int? routeIndex,
}) {
  return Report(
    id: id,
    routeIndex: routeIndex,
    lat: 37.45,
    lng: 126.73,
    observedAt: _origin.add(Duration(minutes: minutesAfterOrigin)),
    similarity: similarity,
    grade: SimilarityGrade.fromSimilarity(similarity),
    faceFound: similarity != null,
    photoUrl: '/uploads/$id.jpg',
    status: ReportStatus.visible,
  );
}

/// 시드와 같은 모양. 최신이 위(reports)이고, 경로 번호는 40% 이상에만 붙는다.
ReportBundle _bundle() {
  final reports = [
    _report('r_4', 150, 82.1, routeIndex: 3),
    _report('r_3', 100, 34.2),
    _report('r_2', 60, 64.9, routeIndex: 2),
    _report('r_1', 25, 76.4, routeIndex: 1),
  ];

  return ReportBundle(
    missingId: 'm_1',
    count: reports.length,
    reports: reports,
    path: const [],
    origin: ReportOrigin(lat: 37.44, lng: 126.72, at: _origin),
  );
}

void main() {
  group('MapCaseView — 시간 슬라이더(F-5.2.4)', () {
    test('커서를 안 주면 최신까지 전부 본다', () {
      final view = MapCaseView.of(_bundle(), highOnly: false);

      expect(view.reports, hasLength(4));
      expect(view.from, _origin);
      expect(view.to, _origin.add(const Duration(minutes: 150)));
      expect(view.isAtLatest, isTrue);
    });

    test('커서를 당기면 그 시각까지의 제보만 남는다', () {
      final view = MapCaseView.of(
        _bundle(),
        highOnly: false,
        cursor: _origin.add(const Duration(minutes: 70)),
      );

      expect(view.reports.map((r) => r.id), ['r_2', 'r_1']);
      expect(view.isAtLatest, isFalse);
    });

    test('슬라이더 양 끝은 거르기와 상관없이 그대로다', () {
      final all = MapCaseView.of(_bundle(), highOnly: false);
      final filtered = MapCaseView.of(
        _bundle(),
        highOnly: true,
        cursor: _origin.add(const Duration(minutes: 30)),
      );

      expect(filtered.from, all.from);
      expect(filtered.to, all.to, reason: '토글·커서로 슬라이더 길이가 바뀌면 손에 잡히지 않는다');
    });

    test('눈금은 제보가 있는 시각에만 찍힌다', () {
      final view = MapCaseView.of(_bundle(), highOnly: false);

      expect(view.ticks, hasLength(4));
    });
  });

  group('MapCaseView — 유사도 토글(F-5.2.5)', () {
    test('켜면 60% 미만이 가려지고 몇 건인지 센다', () {
      final view = MapCaseView.of(_bundle(), highOnly: true);

      expect(view.reports.map((r) => r.id), ['r_4', 'r_2', 'r_1']);
      expect(view.hiddenCount, 1);
    });

    test('가려도 원본은 그대로다', () {
      final bundle = _bundle();
      MapCaseView.of(bundle, highOnly: true);

      expect(bundle.reports, hasLength(4), reason: '설계 결정 3번 — 제보를 지우지 않는다');
    });
  });

  test('보호자가 숨긴 제보는 지도에 올리지 않는다', () {
    final bundle = _bundle();
    final hidden = Report(
      id: 'r_hidden',
      lat: 37.45,
      lng: 126.73,
      observedAt: _origin.add(const Duration(minutes: 120)),
      similarity: 91.5,
      grade: SimilarityGrade.high,
      faceFound: true,
      photoUrl: '/uploads/r_hidden.jpg',
      status: ReportStatus.hidden,
    );
    final withHidden = ReportBundle(
      missingId: bundle.missingId,
      count: bundle.count + 1,
      reports: [hidden, ...bundle.reports],
      path: bundle.path,
      origin: bundle.origin,
    );

    final view = MapCaseView.of(withHidden, highOnly: false);

    // 허위·중복이라 숨긴 것이다. 핀으로도, 눈금으로도 남기지 않는다.
    expect(view.reports.map((report) => report.id), isNot(contains('r_hidden')));
    expect(view.ticks, hasLength(4));
  });

  group('MapCaseView — 경로(F-5.2.3)', () {
    test('경로는 번호가 붙은 제보만 시간순으로 잇는다', () {
      final view = MapCaseView.of(_bundle(), highOnly: false);

      expect(view.pathReports.map((r) => r.id), ['r_1', 'r_2', 'r_4']);
    });

    test('커서를 당기면 경로도 같이 짧아진다', () {
      final view = MapCaseView.of(
        _bundle(),
        highOnly: false,
        cursor: _origin.add(const Duration(minutes: 70)),
      );

      expect(view.pathReports.map((r) => r.id), ['r_1', 'r_2']);
    });

    test('핀과 선이 같은 목록에서 나온다', () {
      final view = MapCaseView.of(_bundle(), highOnly: true);

      for (final report in view.pathReports) {
        expect(view.reports, contains(report));
      }
    });
  });
}
