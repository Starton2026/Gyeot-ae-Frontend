import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../report/data/report.dart';
import '../../report/data/report_repository.dart';
import '../data/missing_case.dart';
import '../data/missing_repository.dart';

/// 사건 하나(S3).
final missingDetailProvider =
    FutureProvider.family<MissingCaseDetail, String>((ref, caseId) async {
      return ref.watch(missingRepositoryProvider).fetchCase(caseId);
    });

/// 사건 하나의 제보 묶음.
///
/// **거르지 않고 전부 받아서 화면에서 거른다.** 유사도 토글을 켰다 끌 때마다
/// 다시 부르면 그때마다 목록이 사라졌다 나타나고, "몇 건이 숨었는지"를 세려면
/// 어차피 전체가 필요하다.
final caseReportsProvider = FutureProvider.family<ReportBundle, String>((
  ref,
  caseId,
) async {
  return ref.watch(reportRepositoryProvider).fetchReports(caseId);
});

/// 타임라인 유사도 필터의 경계(기능정의서 5.2).
const double timelineFilterThreshold = 60;

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
        .where((report) => (report.similarity ?? 0) >= timelineFilterThreshold)
        .toList(growable: false);

    return TimelineView(
      shown: shown,
      hiddenCount: bundle.reports.length - shown.length,
    );
  }
}
