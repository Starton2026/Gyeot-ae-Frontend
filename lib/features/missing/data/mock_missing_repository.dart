import '../../../core/mock/mock_backend.dart';
import '../../../core/network/api_exception.dart';
import 'missing_case.dart';
import 'missing_repository.dart';

/// 백엔드 없이 도는 [MissingRepository].
///
/// 검색·필터·정렬·페이지네이션을 실제로 구현한다. 목록만 통째로 돌려주면
/// S2 화면을 만들 때 동작을 확인할 방법이 없다.
class MockMissingRepository implements MissingRepository {
  MockMissingRepository(
    this._backend, {
    this.latency = const Duration(milliseconds: 450),
  });

  final MockBackend _backend;

  /// 일부러 주는 지연. `LoadingView`가 실제로 보이게 한다. 테스트는 0으로 준다.
  final Duration latency;

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
    await _delay();

    var items = _backend.cases
        .map((record) => _backend.summaryJson(record, lat: lat, lng: lng))
        .map(MissingCaseSummary.fromJson)
        .toList();

    items = items.where((item) => _matchesStatus(item, status)).toList();

    if (category != null) {
      items = items.where((item) => item.category == category).toList();
    }

    final keyword = query?.trim();
    if (keyword != null && keyword.isNotEmpty) {
      items = items.where((item) => _matchesKeyword(item, keyword)).toList();
    }

    if (radiusKm != null) {
      items = items
          .where((item) => (item.distanceKm ?? double.infinity) <= radiusKm)
          .toList();
    }

    _sort(items, sort);

    final total = items.length;
    final offset = int.tryParse(cursor ?? '') ?? 0;
    final page = items.skip(offset).take(limit).toList(growable: false);
    final nextOffset = offset + page.length;

    return MissingCaseList(
      count: total,
      items: page,
      nextCursor: nextOffset < total ? '$nextOffset' : null,
    );
  }

  @override
  Future<MissingCaseDetail> fetchCase(String id) async {
    await _delay();

    final record = _backend.findCase(id);
    if (record == null) throw _notFound();

    return MissingCaseDetail.fromJson(_backend.detailJson(record));
  }

  @override
  Future<MissingCaseRegistration> register(MissingCaseDraft draft) async {
    await _delay();

    // 서버는 사진에서 얼굴 벡터를 못 뽑으면 등록을 거부한다. mock은 사진이
    // 한 장도 없는 경우로 그 상황을 흉내 낸다.
    if (draft.photoPaths.isEmpty) {
      throw const ApiException(
        '사진에서 얼굴을 찾지 못했습니다. 얼굴이 잘 보이는 사진을 한 장 이상 올려주세요.',
        statusCode: 400,
        code: ApiErrorCode.faceNotFound,
        field: 'photos',
      );
    }

    final record = _backend.addCase(draft);
    return MissingCaseRegistration.fromJson(_backend.registrationJson(record));
  }

  bool _matchesStatus(MissingCaseSummary item, CaseStatusFilter filter) {
    return switch (filter) {
      CaseStatusFilter.all => true,
      CaseStatusFilter.active => item.status == CaseStatus.active,
      CaseStatusFilter.resolved => item.status == CaseStatus.resolved,
    };
  }

  /// 이름과 지역(주소)으로 찾는다. API 명세서 6)의 `q`.
  bool _matchesKeyword(MissingCaseSummary item, String keyword) {
    final needle = keyword.toLowerCase();

    return item.name.toLowerCase().contains(needle) ||
        (item.lastAddress?.toLowerCase().contains(needle) ?? false);
  }

  void _sort(List<MissingCaseSummary> items, MissingSort sort) {
    switch (sort) {
      case MissingSort.recent:
        items.sort((a, b) => b.missingAt.compareTo(a.missingAt));
      case MissingSort.distance:
        // 위치를 안 보냈으면 거리를 모른다. 긴급도로 되돌린다.
        if (items.any((item) => item.distanceKm == null)) {
          _sort(items, MissingSort.urgency);
          return;
        }
        items.sort((a, b) => a.distanceKm!.compareTo(b.distanceKm!));
      case MissingSort.urgency:
        items.sort(
          (a, b) => (b.urgencyScore ?? 0).compareTo(a.urgencyScore ?? 0),
        );
    }
  }

  ApiException _notFound() {
    return const ApiException(
      '이미 종료되었거나 없는 사건이에요.',
      statusCode: 404,
      code: ApiErrorCode.notFound,
    );
  }

  Future<void> _delay() {
    return latency == Duration.zero
        ? Future<void>.value()
        : Future<void>.delayed(latency);
  }
}
