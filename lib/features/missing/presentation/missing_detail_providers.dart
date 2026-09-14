import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/map/map_plan.dart';
import '../../../core/widgets/map_pin_icon.dart';
import '../../report/data/report.dart';

/// "유사도 60% 이상" 토글(F-3.5.5). 기본은 켜짐이다(기능정의서 5.2).
///
/// 끄면 40% 미만과 얼굴 미검출까지 모두 보인다. **거르는 것은 표시일 뿐
/// 저장된 제보를 지우지 않는다**(설계 결정 3번).
class TimelineHighOnlyNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void set(bool value) => state = value;
}

final timelineHighOnlyProvider =
    NotifierProvider<TimelineHighOnlyNotifier, bool>(
      TimelineHighOnlyNotifier.new,
    );

/// 토글을 반영한 타임라인 목록. 걸러진 뒤에도 원본은 그대로 있다.
class TimelineView {
  const TimelineView({required this.shown, required this.hiddenCount});

  /// 화면에 그릴 제보. 최신이 위다(F-3.5.1).
  final List<Report> shown;

  /// 토글 때문에 가려진 제보 수. "3건 숨김"으로 적는다.
  final int hiddenCount;

  factory TimelineView.of(ReportBundle bundle, {required bool highOnly}) {
    if (!highOnly) {
      return TimelineView(shown: bundle.reports, hiddenCount: 0);
    }

    final shown = bundle.reports
        .where(
          (report) =>
              (report.similarity ?? 0) >=
              SimilarityGrade.displayFilterThreshold,
        )
        .toList(growable: false);

    return TimelineView(
      shown: shown,
      hiddenCount: bundle.reports.length - shown.length,
    );
  }
}

/// 상세의 이동 경로 미니 지도(F-3.4). 찍을 것이 하나도 없으면 null이다.
///
/// 지도 탭(S5)의 사건 선택 모드와 같은 그림이다. 실종 지점 핀, 번호 붙은 제보
/// 핀, 실종 지점에서 목격 시각순으로 이은 경로(설계 결정 5번).
///
/// **아래 타임라인과 같은 [view]로 찍는다.** 60% 토글을 켰는데 지도에만 다른
/// 제보가 있으면 번호가 어긋나 보인다.
MapPlan? caseMapPlan(ReportBundle bundle, TimelineView view) {
  final origin = bundle.origin;
  // 보호자가 숨긴 제보는 타임라인에는 흐리게 남지만 지도에는 찍지 않는다.
  final located = view.shown
      .where(
        (report) =>
            report.hasLocation && report.status != ReportStatus.hidden,
      )
      .toList(growable: false);

  final marks = <MapMark>[
    if (origin != null)
      MissingMark(
        id: 'origin',
        at: (lat: origin.lat, lng: origin.lng),
        level: MapPinLevel.golden,
      ),
    for (final report in located)
      ReportMark(
        id: report.id,
        at: (lat: report.lat!, lng: report.lng!),
        grade: report.grade,
        routeIndex: report.routeIndex,
      ),
  ];
  if (marks.isEmpty) return null;

  final path = located.where((report) => report.isOnPath).toList()
    ..sort((a, b) => a.observedAt.compareTo(b.observedAt));

  return MapPlan(
    center: marks.first.at,
    zoomLevel: caseMapZoomLevel,
    marks: marks,
    route: [
      if (origin != null) (lat: origin.lat, lng: origin.lng),
      for (final report in path) (lat: report.lat!, lng: report.lng!),
    ],
    fitMarks: marks.length > 1,
  );
}

/// 사건 하나의 둘레가 보이는 배율. 지도 탭 사건 선택과 같다.
const int caseMapZoomLevel = 15;
