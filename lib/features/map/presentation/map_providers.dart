import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/current_location.dart';
import '../../missing/data/missing_case.dart';
import '../../missing/data/missing_repository.dart';

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

/// 캐러셀에서 지금 보고 있는 사건. 핀 강조와 카메라 이동이 이 값을 따라간다.
class SelectedMapCaseNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? caseId) => state = caseId;
}

final selectedMapCaseProvider =
    NotifierProvider<SelectedMapCaseNotifier, String?>(
      SelectedMapCaseNotifier.new,
    );
