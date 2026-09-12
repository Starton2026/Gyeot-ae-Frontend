import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/features/missing/presentation/missing_detail_providers.dart';
import 'package:gyeotae/features/report/data/report.dart';

Report _report(String id, double? similarity) {
  return Report(
    id: id,
    lat: 37.45,
    lng: 126.73,
    observedAt: DateTime(2026, 9, 12, 15),
    similarity: similarity,
    grade: SimilarityGrade.fromSimilarity(similarity),
    faceFound: similarity != null,
    photoUrl: '/uploads/$id.jpg',
    status: ReportStatus.visible,
  );
}

ReportBundle _bundle(List<Report> reports) {
  return ReportBundle(
    missingId: 'm_1',
    count: reports.length,
    reports: reports,
    path: const [],
  );
}

void main() {
  group('TimelineView — 유사도 토글(F-3.5.5)', () {
    final bundle = _bundle([
      _report('r_1', 82.1),
      _report('r_2', 60),
      _report('r_3', 58.2),
      _report('r_4', 34.2),
      _report('r_5', null),
    ]);

    test('켜면 60% 미만과 미검출이 가려진다', () {
      final view = TimelineView.of(bundle, highOnly: true);

      expect(view.shown.map((r) => r.id), ['r_1', 'r_2']);
      expect(view.hiddenCount, 3);
    });

    test('경계값 60%는 남는다', () {
      final view = TimelineView.of(bundle, highOnly: true);

      expect(view.shown.any((r) => r.id == 'r_2'), isTrue);
    });

    test('끄면 하나도 가리지 않는다', () {
      final view = TimelineView.of(bundle, highOnly: false);

      expect(view.shown, hasLength(5));
      expect(view.hiddenCount, 0);
    });

    test('거르는 것은 표시일 뿐 원본은 그대로다', () {
      TimelineView.of(bundle, highOnly: true);

      expect(bundle.reports, hasLength(5), reason: '설계 결정 3번 — 제보를 지우지 않는다');
    });
  });
}
