import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/core/location/current_location.dart';
import 'package:gyeotae/core/location/location_source.dart';
import 'package:gyeotae/core/map/map_plan.dart';
import 'package:gyeotae/core/widgets/map_pin_icon.dart';
import 'package:gyeotae/features/home/presentation/home_providers.dart';
import 'package:gyeotae/features/missing/data/case_edit.dart';
import 'package:gyeotae/features/missing/data/missing_case.dart';
import 'package:gyeotae/features/missing/data/missing_repository.dart';

import '../../../support/fake_location_source.dart';

MissingCaseSummary _case(
  String id, {
  int elapsedMinutes = 60,
  double? distanceKm = 1,
}) {
  return MissingCaseSummary(
    id: id,
    name: '김하준',
    age: 7,
    gender: Gender.male,
    category: MissingCategory.child,
    description: '노란 후드티',
    lastLat: 37.45,
    lastLng: 126.73,
    missingAt: DateTime(2026, 9, 14, 12),
    elapsedMinutes: elapsedMinutes,
    status: CaseStatus.active,
    reportCount: 0,
    distanceKm: distanceKm,
    urgencyLevel: UrgencyLevel.high,
  );
}

/// 목록을 정해 두고 돌려주는 저장소.
///
/// 반경과 상한을 **서버처럼** 지킨다. `count`는 반경 안의 전체 건수고
/// `items`는 그중 [limit]건이다. 이걸 안 지키면 홈이 반경을 서버에 넘기는지
/// 테스트가 확인하지 못한다.
class _ListRepository implements MissingRepository {
  _ListRepository(this.items);

  final List<MissingCaseSummary> items;

  /// 마지막으로 받은 인자. 홈이 무엇을 넘겼는지 본다.
  double? lastRadiusKm;
  int? lastLimit;

  @override
  Future<MissingCaseList> fetchCases({
    String? query,
    MissingCategory? category,
    CaseStatusFilter status = CaseStatusFilter.active,
    MissingSort sort = MissingSort.urgency,
    double? lat,
    double? lng,
    double? radiusKm,
    int limit = 20,
    String? cursor,
  }) async {
    lastRadiusKm = radiusKm;
    lastLimit = limit;

    final within = radiusKm == null
        ? items
        : items
              .where((item) => (item.distanceKm ?? double.infinity) <= radiusKm)
              .toList(growable: false);

    return MissingCaseList(
      count: within.length,
      items: within.take(limit).toList(growable: false),
    );
  }

  @override
  Future<MissingCaseDetail> fetchCase(String id) => throw UnimplementedError();

  @override
  Future<MissingCaseRegistration> register(MissingCaseDraft draft) =>
      throw UnimplementedError();

  @override
  Future<MissingCaseDetail> updateCase(String id, CaseEdit edit) =>
      throw UnimplementedError();

  @override
  Future<PhotoAddResult> addPhotos(String id, List<String> photoPaths) =>
      throw UnimplementedError();

  @override
  Future<int> resolveCase(String id) => throw UnimplementedError();
}

void main() {
  test('홈 피드는 목록 3건과 별개로 반경 안 사건을 지도용으로 전부 든다', () async {
    final repository = _ListRepository([
      _case('m_1'),
      _case('m_2'),
      _case('m_3'),
      _case('m_4'),
      _case('m_far', distanceKm: 12),
    ]);
    final container = ProviderContainer.test(
      overrides: [
        missingRepositoryProvider.overrideWithValue(repository),
        locationSourceProvider.overrideWithValue(FakeLocationSource()),
      ],
    );

    final feed = await container.read(homeFeedProvider.future);

    // 반경으로 거르는 일은 서버가 한다. 앱이 받은 뒤에 거르면 반경 밖 사건이
    // 상한을 잡아먹어 정작 주변 사건이 빠진다.
    expect(repository.lastRadiusKm, HomeFeed.nearbyRadiusKm);
    expect(repository.lastLimit, HomeFeed.mapPinLimit);

    expect(feed.nearbyCases, hasLength(HomeFeed.nearbyListLimit));
    expect(feed.mapCases.map((item) => item.id), ['m_1', 'm_2', 'm_3', 'm_4']);
    expect(feed.nearbyCount, 4);
  });

  test('반경 안 사건이 핀 상한을 넘으면 핀은 잘려도 건수는 전부 센다', () async {
    final repository = _ListRepository([
      for (var i = 0; i < HomeFeed.mapPinLimit + 7; i++) _case('m_$i'),
    ]);
    final container = ProviderContainer.test(
      overrides: [
        missingRepositoryProvider.overrideWithValue(repository),
        locationSourceProvider.overrideWithValue(FakeLocationSource()),
      ],
    );

    final feed = await container.read(homeFeedProvider.future);

    expect(feed.mapCases, hasLength(HomeFeed.mapPinLimit));
    // "내 주변 실종 N건"은 핀 수가 아니라 서버가 센 전체 수다.
    expect(feed.nearbyCount, HomeFeed.mapPinLimit + 7);
  });

  test('내 위치를 가운데 두고 주변 사건의 실종 위치를 긴급도대로 찍는다', () {
    const location = AppLocation(lat: 37.47, lng: 126.75, resolved: true);
    final feed = HomeFeed(
      urgentCase: null,
      nearbyCases: const [],
      nearbyCount: 2,
      mapCases: [
        _case('m_golden', elapsedMinutes: 90),
        _case('m_calm', elapsedMinutes: 2000),
      ],
    );

    final plan = homeMapPlan(feed, location);

    expect(plan.center, (lat: 37.47, lng: 126.75));
    expect(plan.fitMarks, isFalse);
    expect(plan.route, isEmpty);
    // 지도 탭 전체 보기와 같은 핀이다.
    final marks = plan.marks.cast<MissingMark>();
    expect(marks.map((mark) => mark.id), ['m_golden', 'm_calm']);
    expect(marks.map((mark) => mark.level), [
      MapPinLevel.golden,
      MapPinLevel.calm,
    ]);
    expect(marks.first.at, (lat: 37.45, lng: 126.73));
  });

  test('주변에 사건이 없어도 내 동네 지도는 보여준다', () {
    const location = AppLocation(lat: 37.47, lng: 126.75);
    const feed = HomeFeed(urgentCase: null, nearbyCases: [], nearbyCount: 0);

    final plan = homeMapPlan(feed, location);

    expect(plan.marks, isEmpty);
    expect(plan.center, (lat: 37.47, lng: 126.75));
  });
}
