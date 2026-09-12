import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/current_location.dart';
import '../../missing/data/missing_case.dart';
import '../../missing/data/missing_repository.dart';
import '../../report/data/report.dart';

/// 지도 필터 칩(F-5.1.2). 목록(S2)과 달리 상태 칩이 없다.
///
/// 지도는 **진행 중인 사건만** 그린다. 끝난 사건의 핀은 찾아갈 곳이 아니라
/// 지도를 읽는 데 방해만 된다. 발견 완료 사건은 목록(S2)에 남는다.
enum MapCaseFilter {
  all('전체', null),
  child('아동', MissingCategory.child),
  elderly('어르신', MissingCategory.elderly);

  const MapCaseFilter(this.label, this.category);

  final String label;
  final MissingCategory? category;
}

/// 지도의 조회 조건.
///
/// 목록(S2)과 provider를 나눠 둔다. 탭을 오갈 때 한쪽에서 건 검색어가 다른
/// 쪽 화면을 바꿔버리면, 사용자는 자기가 뭘 눌렀는지 알 수 없다.
@immutable
class MapQuery {
  const MapQuery({this.keyword = '', this.filter = MapCaseFilter.all});

  final String keyword;
  final MapCaseFilter filter;

  MapQuery copyWith({String? keyword, MapCaseFilter? filter}) {
    return MapQuery(
      keyword: keyword ?? this.keyword,
      filter: filter ?? this.filter,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MapQuery &&
      other.keyword == keyword &&
      other.filter == filter;

  @override
  int get hashCode => Object.hash(keyword, filter);
}

class MapQueryNotifier extends Notifier<MapQuery> {
  @override
  MapQuery build() => const MapQuery();

  void setKeyword(String keyword) =>
      state = state.copyWith(keyword: keyword.trim());

  void setFilter(MapCaseFilter filter) => state = state.copyWith(filter: filter);
}

final mapQueryProvider = NotifierProvider<MapQueryNotifier, MapQuery>(
  MapQueryNotifier.new,
);

/// 지도에 핀으로 찍을 사건들. 긴급도순이라 카드 캐러셀 순서와 같다.
final mapCasesProvider = FutureProvider<List<MissingCaseSummary>>((ref) async {
  final query = ref.watch(mapQueryProvider);
  final location = ref.watch(currentLocationProvider);

  final page = await ref
      .watch(missingRepositoryProvider)
      .fetchCases(
        query: query.keyword.isEmpty ? null : query.keyword,
        category: query.filter.category,
        status: CaseStatusFilter.active,
        sort: MissingSort.urgency,
        lat: location.lat,
        lng: location.lng,
        limit: _pinLimit,
      );

  return page.items;
});

/// 한 화면에 찍을 핀의 상한.
///
/// 핀이 수백 개가 되면 지도가 읽히지 않고, 핀 이미지를 굽는 비용도 커진다.
/// 긴급도순이라 앞에서 자르면 급한 사건이 남는다.
const int _pinLimit = 50;

/// 지도에서 고른 사건. **null이면 전체 보기**다.
///
/// 이 값 하나가 지도의 두 모드를 가른다(기능정의서 S5). 전체 보기는 실종 핀만
/// 찍고, 사건을 고르면 그 사건의 제보 핀과 이동 경로가 나온다.
class SelectedMapCaseNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? caseId) => state = caseId;
}

final selectedMapCaseProvider =
    NotifierProvider<SelectedMapCaseNotifier, String?>(
      SelectedMapCaseNotifier.new,
    );

/// 시간 슬라이더가 가리키는 시점(F-5.2.4). null이면 최신까지 전부 본다.
///
/// **이 화면의 주인공이다.** 핀만 찍힌 지도는 다른 서비스에도 있지만, 시간을
/// 끌어 경로가 자라나는 것을 보여주는 순간 "이동 경로 복원"이 눈으로 증명된다.
class MapTimeCursorNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() {
    // 사건을 바꾸면 슬라이더는 처음 상태(전체)로 돌아간다.
    ref.watch(selectedMapCaseProvider);

    return null;
  }

  void set(DateTime? at) => state = at;
}

final mapTimeCursorProvider =
    NotifierProvider<MapTimeCursorNotifier, DateTime?>(
      MapTimeCursorNotifier.new,
    );

/// 지도의 "60% 이상" 토글(F-5.2.5). 기본은 켜짐이다(기능정의서 5.2).
class MapHighOnlyNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void set(bool value) => state = value;
}

final mapHighOnlyProvider = NotifierProvider<MapHighOnlyNotifier, bool>(
  MapHighOnlyNotifier.new,
);

/// 사건 하나를 골랐을 때 지도에 그릴 것들.
///
/// 경로는 `bundle.path`를 쓰지 않고 **걸러진 제보로 다시 잇는다.** 핀과 선이
/// 같은 목록에서 나와야 시간 슬라이더를 끌 때 선만 남거나 핀만 남지 않는다.
class MapCaseView {
  const MapCaseView({
    required this.reports,
    required this.pathReports,
    required this.from,
    required this.to,
    required this.cursor,
    required this.ticks,
    required this.hiddenCount,
  });

  /// 핀으로 찍을 제보. 최신순이다.
  final List<Report> reports;

  /// 폴리라인으로 이을 제보. 시간순이다. 실종 지점은 화면이 맨 앞에 붙인다.
  final List<Report> pathReports;

  /// 슬라이더 왼쪽 끝. 실종 시각.
  final DateTime from;

  /// 슬라이더 오른쪽 끝. 가장 최근 제보 시각.
  final DateTime to;

  /// 지금 슬라이더가 선 자리.
  final DateTime cursor;

  /// 눈금. 실제 제보가 있는 시각에만 찍는다.
  final List<DateTime> ticks;

  /// 유사도 토글 때문에 가려진 제보 수.
  final int hiddenCount;

  /// 슬라이더를 끝까지 밀었나. 처음 들어오면 참이다.
  bool get isAtLatest => !cursor.isBefore(to);

  factory MapCaseView.of(
    ReportBundle bundle, {
    required bool highOnly,
    DateTime? cursor,
  }) {
    final origin = bundle.origin;
    final all = bundle.reports;

    // 슬라이더 양 끝은 거르기 전 값으로 잡는다. 토글을 켰다 끌 때마다 슬라이더
    // 길이가 바뀌면 손에 잡히지 않는다.
    final from = origin?.at ?? _earliest(all);
    final to = _latest(all) ?? from;
    final at = cursor == null || cursor.isAfter(to) ? to : cursor;

    final shown = all.where((report) {
      if (report.observedAt.isAfter(at)) return false;
      if (!highOnly) return true;

      return (report.similarity ?? 0) >= SimilarityGrade.displayFilterThreshold;
    }).toList(growable: false);

    final onPath = shown.where((report) => report.isOnPath).toList()
      ..sort((a, b) => a.observedAt.compareTo(b.observedAt));

    return MapCaseView(
      reports: shown,
      pathReports: onPath,
      from: from,
      to: to,
      cursor: at,
      ticks: all
          .map((report) => report.observedAt)
          .where((time) => !time.isAfter(to))
          .toList(growable: false),
      hiddenCount: all.where((report) => !report.observedAt.isAfter(at)).length -
          shown.length,
    );
  }
}

DateTime _earliest(List<Report> reports) {
  if (reports.isEmpty) return DateTime.now();

  return reports
      .map((report) => report.observedAt)
      .reduce((a, b) => a.isBefore(b) ? a : b);
}

DateTime? _latest(List<Report> reports) {
  if (reports.isEmpty) return null;

  return reports
      .map((report) => report.observedAt)
      .reduce((a, b) => a.isAfter(b) ? a : b);
}
