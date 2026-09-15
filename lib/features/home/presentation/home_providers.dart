import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/current_location.dart';
import '../../../core/map/map_plan.dart';
import '../../../core/widgets/map_pin_icon.dart';
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
    this.mapCases = const [],
  });

  /// 골든타임(3시간) 안의 긴급도 1위 사건. 없으면 긴급 배너를 숨긴다(F-1.1).
  ///
  /// 상시 노출되는 경고색 배너는 곧 무시된다.
  final MissingCaseSummary? urgentCase;

  /// 주변 목록에 뜨는 사건. 긴급도순 [nearbyListLimit]건(F-1.4).
  final List<MissingCaseSummary> nearbyCases;

  /// 반경 안에서 진행 중인 사건 수. 지도 프리뷰의 "내 주변 실종 N건".
  ///
  /// **[mapCases]의 길이가 아니라 서버가 센 전체 수다.** 반경 안에
  /// [mapPinLimit]건이 넘게 있으면 핀보다 이 숫자가 크다. 150px짜리 프리뷰에서
  /// 핀을 세는 사람은 없지만, 숫자가 틀리면 "내 주변에 몇 명"이 틀린다.
  final int nearbyCount;

  /// 지도 프리뷰에 찍을 반경 안의 사건. 목록은 [nearbyCases] 3건만 보여준다.
  final List<MissingCaseSummary> mapCases;

  /// "내 주변"으로 치는 반경.
  static const double nearbyRadiusKm = 5;

  /// 홈에 고정으로 노출하는 주변 사건 수(F-1.4).
  static const int nearbyListLimit = 3;

  /// 프리뷰에 찍을 핀의 상한.
  ///
  /// 지도 탭과 같은 수다. 이보다 많이 받아봐야 프리뷰 크기에서는 겹쳐서 한
  /// 덩어리로 보이고, 응답만 무거워진다.
  static const int mapPinLimit = 50;
}

/// 홈에 필요한 데이터를 한 번에 가져온다.
///
/// **반경을 서버에 넘긴다.** 예전에는 서버가 준 첫 20건을 받아 앱에서 5km로
/// 걸렀는데, 그러면 진행 중 사건이 20건을 넘는 순간 내 5km 안에 있는데도
/// 긴급도 21위라서 홈에서 사라졌다. 개수도 20에서 멈췄다.
final homeFeedProvider = FutureProvider<HomeFeed>((ref) async {
  final repository = ref.watch(missingRepositoryProvider);
  final location = ref.watch(currentLocationProvider);

  final page = await repository.fetchCases(
    status: CaseStatusFilter.active,
    sort: MissingSort.urgency,
    lat: location.lat,
    lng: location.lng,
    radiusKm: HomeFeed.nearbyRadiusKm,
    limit: HomeFeed.mapPinLimit,
  );

  return HomeFeed(
    urgentCase: _firstWithinGoldenTime(page.items),
    nearbyCases: page.items
        .take(HomeFeed.nearbyListLimit)
        .toList(growable: false),
    // 걸러낸 뒤의 전체 건수다. 이 페이지에 담긴 개수가 아니다.
    nearbyCount: page.count,
    mapCases: page.items,
  );
});

/// 홈 지도 프리뷰(F-1.3). 내 위치를 가운데 두고 주변 사건의 실종 위치만 찍는다.
///
/// 지도 탭(S5) 전체 보기와 같은 핀과 배율이다. 경로는 그리지 않는다 — 여러
/// 사건의 경로를 겹치면 선이 엉켜 아무것도 읽히지 않는다.
MapPlan homeMapPlan(HomeFeed feed, AppLocation location) {
  return MapPlan(
    // 위치를 모르면 시연용 기본 좌표다. 카메라만 두는 자리라 괜찮다.
    center: (lat: location.lat, lng: location.lng),
    zoomLevel: homeMapZoomLevel,
    marks: [
      for (final summary in feed.mapCases)
        MissingMark(
          id: summary.id,
          at: (lat: summary.lastLat, lng: summary.lastLng),
          level: MapPinLevel.of(summary.elapsedMinutes),
        ),
    ],
  );
}

/// 동네 몇 곳이 한눈에 들어오는 배율. 지도 탭 전체 보기와 같다.
const int homeMapZoomLevel = 13;

/// 긴급도순으로 이미 정렬된 목록에서 골든타임 안의 첫 사건을 고른다.
MissingCaseSummary? _firstWithinGoldenTime(List<MissingCaseSummary> cases) {
  for (final item in cases) {
    if (item.isWithinGoldenTime) return item;
  }

  return null;
}
