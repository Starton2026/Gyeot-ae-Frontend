import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/current_location.dart';
import '../../missing/data/missing_case.dart';
import '../../missing/data/missing_repository.dart';

/// 홈 한 화면이 쓰는 값 묶음.
///
/// 사건 목록을 한 번만 가져와서 배너·지도 프리뷰·주변 목록이 나눠 쓴다.
/// 같은 목록을 세 번 부르면 세 번 다 다른 순서가 올 수 있다.
class HomeFeed {
  const HomeFeed({
    required this.urgentCase,
    required this.nearbyCases,
    required this.nearbyCount,
    required this.activeCount,
  });

  /// 골든타임(3시간) 안의 긴급도 1위 사건. 없으면 긴급 배너를 숨긴다(F-1.1).
  ///
  /// 상시 노출되는 경고색 배너는 곧 무시된다.
  final MissingCaseSummary? urgentCase;

  /// 주변 목록에 뜨는 사건. 긴급도순 [nearbyListLimit]건(F-1.4).
  final List<MissingCaseSummary> nearbyCases;

  /// 반경 안에서 진행 중인 사건 수. 지도 프리뷰의 "내 주변 실종 N건".
  final int nearbyCount;

  /// 진행 중인 사건 전체 수. "진행 중인 사건 N건 모두 보기".
  final int activeCount;

  /// "내 주변"으로 치는 반경.
  static const double nearbyRadiusKm = 5;

  /// 홈에 고정으로 노출하는 주변 사건 수(F-1.4).
  static const int nearbyListLimit = 3;
}

/// 홈에 필요한 데이터를 한 번에 가져온다.
final homeFeedProvider = FutureProvider<HomeFeed>((ref) async {
  final repository = ref.watch(missingRepositoryProvider);
  final location = ref.watch(currentLocationProvider);

  final page = await repository.fetchCases(
    status: CaseStatusFilter.active,
    sort: MissingSort.urgency,
    lat: location.lat,
    lng: location.lng,
  );

  final nearby = page.items
      .where(
        (item) =>
            (item.distanceKm ?? double.infinity) <= HomeFeed.nearbyRadiusKm,
      )
      .toList(growable: false);

  return HomeFeed(
    urgentCase: _firstWithinGoldenTime(nearby),
    nearbyCases: nearby.take(HomeFeed.nearbyListLimit).toList(growable: false),
    nearbyCount: nearby.length,
    activeCount: page.count,
  );
});

/// 긴급도순으로 이미 정렬된 목록에서 골든타임 안의 첫 사건을 고른다.
MissingCaseSummary? _firstWithinGoldenTime(List<MissingCaseSummary> cases) {
  for (final item in cases) {
    if (item.isWithinGoldenTime) return item;
  }

  return null;
}
