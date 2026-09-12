import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/current_location.dart';
import '../data/missing_case.dart';
import '../data/missing_repository.dart';

/// 목록 필터 칩(F-2.2).
///
/// 구분(아동·어르신)과 상태(진행중·발견)가 한 줄에 섞여 있지만, **하나만
/// 고를 수 있다.** 조합을 열면 칩 하나가 켜진 디자인과 맞지 않고, 사용자가
/// 조합 규칙을 배워야 한다.
///
/// `전체`는 발견 완료까지 모두 보여준다. 끝난 사건도 남겨야 서비스가 실제로
/// 작동한다는 증거가 된다(설계 결정 7번).
enum MissingListFilter {
  all('전체', '전체', null, CaseStatusFilter.all),
  child('아동', '아동', MissingCategory.child, CaseStatusFilter.all),
  elderly('어르신', '어르신', MissingCategory.elderly, CaseStatusFilter.all),
  active('진행중', '진행 중', null, CaseStatusFilter.active),
  resolved('발견', '발견', null, CaseStatusFilter.resolved);

  const MissingListFilter(
    this.chipLabel,
    this.countLabel,
    this.category,
    this.status,
  );

  /// 칩에 적는 말.
  final String chipLabel;

  /// 건수 옆에 적는 말. "진행 중 14건"처럼 띄어쓰기가 다르다.
  final String countLabel;

  final MissingCategory? category;
  final CaseStatusFilter status;
}

/// 정렬 기준에 적는 말(F-2.3).
extension MissingSortLabel on MissingSort {
  String get label => switch (this) {
    MissingSort.urgency => '긴급도순',
    MissingSort.recent => '최신순',
    MissingSort.distance => '거리순',
  };
}

/// 목록 조회 조건. 검색어·칩·정렬을 한 덩어리로 들고 있는다.
///
/// 셋을 따로 두면 하나가 바뀔 때마다 목록을 다시 부르는 지점이 세 군데로
/// 흩어진다. 값이 같으면 다시 부르지 않도록 `==`를 정의해 뒀다.
@immutable
class MissingListQuery {
  const MissingListQuery({
    this.keyword = '',
    this.filter = MissingListFilter.all,
    this.sort = MissingSort.urgency,
  });

  /// 이름·지역 검색어(F-2.1). 빈 문자열이면 검색하지 않는다.
  final String keyword;

  final MissingListFilter filter;
  final MissingSort sort;

  MissingListQuery copyWith({
    String? keyword,
    MissingListFilter? filter,
    MissingSort? sort,
  }) {
    return MissingListQuery(
      keyword: keyword ?? this.keyword,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MissingListQuery &&
        other.keyword == keyword &&
        other.filter == filter &&
        other.sort == sort;
  }

  @override
  int get hashCode => Object.hash(keyword, filter, sort);
}

class MissingListQueryNotifier extends Notifier<MissingListQuery> {
  @override
  MissingListQuery build() => const MissingListQuery();

  void setKeyword(String keyword) {
    state = state.copyWith(keyword: keyword.trim());
  }

  void setFilter(MissingListFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void setSort(MissingSort sort) {
    state = state.copyWith(sort: sort);
  }
}

final missingListQueryProvider =
    NotifierProvider<MissingListQueryNotifier, MissingListQuery>(
      MissingListQueryNotifier.new,
    );

/// 지금까지 쌓인 목록.
@immutable
class MissingListPage {
  const MissingListPage({
    required this.items,
    required this.count,
    this.nextCursor,
    this.isLoadingMore = false,
  });

  final List<MissingCaseSummary> items;

  /// 조건에 맞는 **전체** 건수. 지금 화면에 있는 개수가 아니다.
  final int count;

  final String? nextCursor;
  final bool isLoadingMore;

  bool get hasMore => nextCursor != null;
}

/// 검색·필터·정렬이 걸린 실종자 목록(S2).
///
/// 조건이 바뀌면 [build]가 다시 돌아 첫 페이지부터 받는다. 스크롤이 끝에
/// 닿으면 [loadMore]가 다음 20건을 뒤에 잇는다(F-2.6).
class MissingListNotifier extends AsyncNotifier<MissingListPage> {
  @override
  Future<MissingListPage> build() async {
    final query = ref.watch(missingListQueryProvider);
    final location = ref.watch(currentLocationProvider);

    final page = await ref
        .watch(missingRepositoryProvider)
        .fetchCases(
          query: query.keyword.isEmpty ? null : query.keyword,
          category: query.filter.category,
          status: query.filter.status,
          sort: query.sort,
          lat: location.lat,
          lng: location.lng,
        );

    return MissingListPage(
      items: page.items,
      count: page.count,
      nextCursor: page.nextCursor,
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    final cursor = current?.nextCursor;
    if (current == null || cursor == null || current.isLoadingMore) return;

    state = AsyncData(
      MissingListPage(
        items: current.items,
        count: current.count,
        nextCursor: cursor,
        isLoadingMore: true,
      ),
    );

    final query = ref.read(missingListQueryProvider);
    final location = ref.read(currentLocationProvider);

    try {
      final next = await ref
          .read(missingRepositoryProvider)
          .fetchCases(
            query: query.keyword.isEmpty ? null : query.keyword,
            category: query.filter.category,
            status: query.filter.status,
            sort: query.sort,
            lat: location.lat,
            lng: location.lng,
            cursor: cursor,
          );

      state = AsyncData(
        MissingListPage(
          items: [...current.items, ...next.items],
          count: next.count,
          nextCursor: next.nextCursor,
        ),
      );
    } on Object catch (error) {
      // 다음 장을 못 받았다고 이미 받은 목록까지 지우지 않는다. 커서를 그대로
      // 두니 조금 더 스크롤하면 다시 시도된다.
      debugPrint('실종자 목록 추가 로드 실패: $error');

      state = AsyncData(
        MissingListPage(
          items: current.items,
          count: current.count,
          nextCursor: cursor,
        ),
      );
    }
  }
}

final missingListProvider =
    AsyncNotifierProvider<MissingListNotifier, MissingListPage>(
      MissingListNotifier.new,
    );
